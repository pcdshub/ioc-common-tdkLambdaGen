#! /bin/bash

# Setup the common directory env variables
if [ -e      /reg/g/pcds/pyps/config/common_dirs.sh ]; then
        source   /reg/g/pcds/pyps/config/common_dirs.sh
elif [ -e    /afs/slac/g/pcds/pyps/config/common_dirs.sh ]; then
        source   /afs/slac/g/pcds/pyps/config/common_dirs.sh
fi

# Setup edm environment
source /reg/g/pcds/setup/epicsenv-cur.sh

pushd $$IOCTOP/screens

$$LOOP(GENESYS)
edm -x -m "NAME=$$BASE,IOC=$$IOC_PV" -eolc geneSys.edl &
$$ENDLOOP(GENESYS)
