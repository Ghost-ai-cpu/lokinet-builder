REPO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

BUILD_DIR_BASE=$(REPO)/build

EXE = $(REPO)/worktipsnet
RC_EXE = $(REPO)/worktipsnet-rcutil

DEP_PREFIX=$(BUILD_DIR_BASE)/prefix
PREFIX_SRC=$(DEP_PREFIX)/src

SODIUM_SRC=$(REPO)/deps/sodium
LLARPD_SRC=$(REPO)/deps/llarp
MOTTO=$(LLARPD_SRC)/motto.txt

SODIUM_BUILD=$(PREFIX_SRC)/sodium
SODIUM_CONFIG=$(SODIUM_SRC)/configure
SODIUM_LIB=$(DEP_PREFIX)/lib/libsodium.a

NDK ?= $(HOME)/android-ndk
NDK_INSTALL_DIR = $(BUILD_DIR)/ndk
SDK ?= $(HOME)/Android/Sdk

CROSS_TARGET ?=arm-bcm2708hardfp-linux-gnueabi

CROSS_CC ?=$(CROSS_TARGET)-gcc
CROSS_CXX ?=$(CROSS_TARGET)-g++

MINGW_TOOLCHAIN = $(REPO)/contrib/cross/mingw.cmake
MINGW_WOW64_TOOLCHAIN = $(REPO)/contrib/cross/mingw32.cmake

ANDROID_DIR=$(REPO)/android
JNI_DIR=$(ANDROID_DIR)/jni
ANDROID_MK=$(JNI_DIR)/Android.mk
ANDROID_PROPS=$(ANDROID_DIR)/gradle.properties
ANDROID_LOCAL_PROPS=$(ANDROID_DIR)/local.properties
GRADLE = gradle
JAVA_HOME ?= /usr/lib/jvm/default-java

WIN_BUILD_DIR=$(BUILD_DIR_BASE)/windows
DEBUG_BUILD_DIR=$(BUILD_DIR_BASE)/debug-native
STATIC_BUILD_DIR=$(BUILD_DIR_BASE)/static-native
BUILD_DIR=$(BUILD_DIR_BASE)/native
DEB_BUILD_DIR=$(BUILD_DIR_BASE)/debian

BUILD_TYPE ?=Debug

all: build

ensure: clean
	mkdir -p $(STATIC_BUILD_DIR)
	mkdir -p $(WIN_BUILD_DIR)
	mkdir -p $(DEBUG_BUILD_DIR)
	mkdir -p $(DEP_PREFIX)
	mkdir -p $(PREFIX_SRC)
	mkdir -p $(SODIUM_BUILD)
	mkdir -p $(DEB_BUILD_DIR)

sodium-configure: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared

sodium: sodium-configure
	$(MAKE) -C $(SODIUM_BUILD) clean
	$(MAKE) -C $(SODIUM_BUILD) install CFLAGS=-fPIC

build: ensure sodium
	cd $(BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DHAVE_CXX17_FILESYSTEM=OFF
	$(MAKE) -C $(BUILD_DIR)
	cp $(BUILD_DIR)/worktipsnet $(EXE)

static-sodium-configure: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared

static-sodium: static-sodium-configure
	$(MAKE) -C $(SODIUM_BUILD) clean
	$(MAKE) -C $(SODIUM_BUILD) install CFLAGS=-fPIC

static: static-sodium
	cd $(STATIC_BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DSTATIC_LINK=ON -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
	$(MAKE) -C $(STATIC_BUILD_DIR)
	cp $(STATIC_BUILD_DIR)/worktipsnet $(EXE)

android-sodium: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh && LIBSODIUM_FULL_BUILD=1 ANDROID_NDK_HOME=$(NDK) $(SODIUM_SRC)/dist-build/android-x86.sh

android-gradle: android-prepare android-sodium
	cd $(ANDROID_DIR) && JAVA_HOME=$(JAVA_HOME) $(GRADLE) assemble

android-prepare:
	rm -f $(ANDROID_PROPS)
	rm -f $(ANDROID_LOCAL_PROPS)
	echo "#auto generated don't modify kthnx" >> $(ANDROID_PROPS)
	echo "sodiumInclude=$(SODIUM_SRC)/libsodium-android-i686/include" >> $(ANDROID_PROPS)
	echo "sodiumLib=$(SODIUM_SRC)/libsodium-android-i686/lib/libsodium.a" >> $(ANDROID_PROPS)
	echo "worktipsnetCMake=$(LLARPD_SRC)/CMakeLists.txt" >> $(ANDROID_PROPS)
	echo "org.gradle.parallel=true" >> $(ANDROID_PROPS)
	echo "#auto generated don't modify kthnx" >> $(ANDROID_LOCAL_PROPS)
	echo "sdk.dir=$(SDK)" >> $(ANDROID_LOCAL_PROPS)
	echo "ndk.dir=$(NDK)" >> $(ANDROID_LOCAL_PROPS)

android-arm-mk-prepare:
	rm -f $(ANDROID_MK)
	echo "#auto generated don't modify kthnx" >> $(ANDROID_MK)
	echo 'LOCAL_PATH := $$(call my-dir)' >> $(ANDROID_MK)
	echo 'include $$(CLEAR_VARS)' >> $(ANDROID_MK)
	echo "LOCAL_MODULE := worktipsnet" >> $(ANDROID_MK)
	echo "LOCAL_CPP_FEATURES := rtti exceptions" >> $(ANDROID_MK)
	echo "LOCAL_SRC_FILES := $(JNI_DIR)/worktipsnet_android.cpp" >> $(ANDROID_MK)
	echo "LOCAL_C_INCLUDES += $(LLARPD_SRC)/include" >> $(ANDROID_MK)
	echo "LOCAL_STATIC_LIBRARIES := sodium worktipsnet-static" >> $(ANDROID_MK)
	echo 'include $$(BUILD_SHARED_LIBRARY)' >> $(ANDROID_MK)
	echo 'LOCAL_PATH := $$(call my-dir)' >> $(ANDROID_MK)
	echo 'include $$(CLEAR_VARS)' >> $(ANDROID_MK)
	echo "LOCAL_MODULE := sodium" >> $(ANDROID_MK)
	echo "LOCAL_SRC_FILES := $(SODIUM_SRC)/libsodium-android-armv6/lib/libsodium.a" >> $(ANDROID_MK)
	echo "LOCAL_EXPORT_C_INCLUDES := $(SODIUM_SRC)/libsodium-android-armv6/include" >> $(ANDROID_MK)
	echo 'include $$(PREBUILT_STATIC_LIBRARY)' >> $(ANDROID_MK)
	echo 'LOCAL_PATH := $$(call my-dir)' >> $(ANDROID_MK)
	echo 'include $$(CLEAR_VARS)' >> $(ANDROID_MK)
	echo "LOCAL_MODULE := worktipsnet-static" >> $(ANDROID_MK)
	echo "LOCAL_SRC_FILES := $(BUILD_DIR)/libworktipsnet-static.a" >> $(ANDROID_MK)
	echo "LOCAL_EXPORT_C_INCLUDES := $(LLARPD_SRC)/include" >> $(ANDROID_MK)
	echo 'include $$(PREBUILT_STATIC_LIBRARY)' >> $(ANDROID_MK)

android: android-gradle

debian: ensure sodium
	cd $(DEB_BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -G "Unix Makefiles" -DDEBIAN=ON -DRELEASE_MOTTO="$(shell cat $(LLARPD_SRC)/motto.txt)" -DCMAKE_BUILD_TYPE=Release
	$(MAKE) -C $(DEB_BUILD_DIR)
	cp $(DEB_BUILD_DIR)/worktipsnet $(EXE)
	cp $(DEB_BUILD_DIR)/rcutil $(RC_EXE)

cross-sodium: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared --host=$(CROSS_TARGET)
	$(MAKE) -C $(SODIUM_BUILD) install

cross: cross-sodium
	cd $(BUILD_DIR) && cmake $(LLARPD_SRC) -DSTATIC_LINK=ON -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DCMAKE_C_COMPILER=$(CROSS_CC) -DCMAKE_CXX_COMPILER=$(CROSS_CXX) -DCMAKE_CROSS_COMPILING=ON -DCMAKE_BUILD_TYPE=Release
	$(MAKE) -C $(BUILD_DIR)
	cp $(BUILD_DIR)/worktipsnet $(EXE)

windows-sodium: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared --host=x86_64-w64-mingw32
	$(MAKE) -C $(SODIUM_BUILD) install

wow64-sodium: ensure
	cd $(SODIUM_SRC); $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD); $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared --host=i686-w64-mingw32
	$(MAKE) -C $(SODIUM_BUILD) install

legacy-wow64: wow64-sodium
	cd $(WIN_BUILD_DIR) && cmake $(LLARPD_SRC) -DSTATIC_LINK=ON -DSODIUM_LIB=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DCMAKE_TOOLCHAIN_FILE=$(MINGW_WOW64_TOOLCHAIN) -DHAVE_CXX17_FILESYSTEM=ON -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
	$(MAKE) -C $(WIN_BUILD_DIR)
	cp $(WIN_BUILD_DIR)/worktipsnet.exe $(EXE).exe

wow64-release: wow64-sodium
	cd $(WIN_BUILD_DIR) && cmake $(LLARPD_SRC) -DSTATIC_LINK=ON -DSODIUM_LIB=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DCMAKE_TOOLCHAIN_FILE=$(MINGW_WOW64_TOOLCHAIN) -DHAVE_CXX17_FILESYSTEM=ON -DCMAKE_BUILD_TYPE=Release -DRELEASE_MOTTO="$(shell cat $(MOTTO))"
	$(MAKE) -C $(WIN_BUILD_DIR)
	cp $(WIN_BUILD_DIR)/worktipsnet.exe $(EXE).exe
	gpg --sign --detach $(EXE).exe

windows: windows-sodium
	cd $(WIN_BUILD_DIR) && cmake $(LLARPD_SRC) -DSTATIC_LINK=ON -DSODIUM_LIB=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DCMAKE_TOOLCHAIN_FILE=$(MINGW_TOOLCHAIN) -DHAVE_CXX17_FILESYSTEM=ON -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
	$(MAKE) -C $(WIN_BUILD_DIR)
	cp $(WIN_BUILD_DIR)/worktipsnet.exe $(EXE).exe

windows-release: windows-sodium
	cd $(WIN_BUILD_DIR) && cmake $(LLARPD_SRC) -DSTATIC_LINK=ON -DSODIUM_LIB=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DCMAKE_TOOLCHAIN_FILE=$(MINGW_TOOLCHAIN) -DHAVE_CXX17_FILESYSTEM=ON -DCMAKE_BUILD_TYPE=Release -DRELEASE_MOTTO="$(shell cat $(MOTTO))"
	$(MAKE) -C $(WIN_BUILD_DIR)
	cp $(WIN_BUILD_DIR)/worktipsnet.exe $(EXE).exe
	gpg --sign --detach $(EXE).exe

motto:
	figlet "$(shell cat $(MOTTO))"

release: static-sodium motto
	cd $(BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DSTATIC_LINK=ON -DCMAKE_BUILD_TYPE=Release -DRELEASE_MOTTO="$(shell cat $(MOTTO))"
	$(MAKE) -C $(BUILD_DIR)
	cp $(BUILD_DIR)/worktipsnet $(EXE)
	gpg --sign --detach $(EXE)

clean:
	rm -rf $(EXE) $(EXE).exe $(RC_EXE)

distclean: clean
	rm -rf $(BUILD_DIR_BASE)
