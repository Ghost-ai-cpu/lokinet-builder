# worktipsnet builder for windows

## Building for Windows (mingw-w64 native, or wow64/linux/unix cross-compiler)

    #i686 or x86_64
    #if cross-compiling from anywhere other than wow64, export CC and CXX to
    #$ARCH-w64-mingw32-g[cc++] respectively
    $ pacman -Sy base-devel mingw-w64-$ARCH-toolchain git libtool autoconf cmake
    $ git clone --recursive https://github.com/worktips-project/worktipsnet-builder
    $ cd worktipsnet-builder
    $ make ensure sodium
    $ cd build
    $ cmake ../deps/llarp -DSODIUM_LIBRARIES=./prefix/lib/libsodium.a -DSODIUM_INCLUDE_DIR=./prefix/include -G "Unix Makefiles" -DHAVE_CXX17_FILESYSTEM=ON
    $ make
    $ cp llarpd ../worktipsnet.exe

## Building on Windows using Microsoft C/C++ (Visual Studio 2017)

- Microsoft C/C++ is unsupported, the codebase has a lot of POSIX functions, and MinGW-w64 implements enough of them to make the win32 port possible

## running

if the machine you run worktipsnet on has a public address (at the moment) it `will` automatically become a relay, 
otherwise it will run in client mode.


**NEVER** run worktipsnet with elevated privileges.

to set up a worktipsnet to start on boot:

    C:\> (not ready yet. TODO: write up some SCM install code in the win32 setup)

alternatively:

set up the configs and bootstrap (first time only):

    C:\> worktipsnet -g && worktipsnet-bootstrap
    
run it (foreground):
    
    C:\> worktipsnet

to force client mode edit `$APPDATA/.worktipsnet/daemon.ini`

comment out the `[bind]` section, so it looks like this:

    ...
    
    # [bind]
    # {B7F2ECAC-BB10-4736-8BBD-6E9444E27030}=1090


-despair