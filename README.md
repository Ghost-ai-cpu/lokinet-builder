# worktipsnet builder

<p align="center">
    <a href="https://github.com/worktips-project/worktipsnet-builder/commits/master"><img alt="pipeline status" src="https://gitlab.com/worktipsproject/worktipsnet-builder/badges/master/pipeline.svg" /></a>
</p>

this repo is a recursive repo for building worktipsnet with all of the required libraries bundled as git submodules

## building the debian package

    $ sudo apt install devscripts build-essential libtool autoconf cmake git libcap-dev wget
    $ git clone --recursive https://github.com/worktips-project/worktipsnet-builder
    $ cd worktipsnet-builder
    $ debuild -b -us -uc

## cross compile on linux for windows
    
    $ sudo apt install build-essential libtool autoconf cmake git mingw-w64
    $ git clone --recursive https://github.com/worktips-project/worktipsnet-builder
    $ cd worktipsnet-builder
    $ make windows

# running

Install the debian package, build the debian package manually if you want optimizations compiled in.

if the machine you run worktipsnet on has a public address (at the moment) it `will` automatically become a relay, 
otherwise it will run in client mode.


**NEVER** run worktipsnet as root.

to set up a worktipsnet to start on boot:

    # systemctl enable --now worktipsnet.service

alternatively:

set up the configs and bootstrap (first time only):

    $ worktipsnet -g && worktipsnet-bootstrap
    
run it (foreground):
    
    $ worktipsnet

to force client mode edit `/var/lib/worktipsnet/.worktipsnet/worktipsnet.ini` or `$HOME/.worktipsnet/daemon.ini`

comment out the `[bind]` section, so it looks like this:

    ...
    
    # [bind]
    # eth0=1090

