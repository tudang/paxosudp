#!/bin/bash

ROOT=`pwd`
LIB_DIR="$ROOT/dependencies"
mkdir -p $LIB_DIR

# build msgpack-c
cd  $ROOT/lib/msgpack-c
cmake -DCMAKE_INSTALL_PREFIX:PATH=$LIB_DIR .
make
make install

# build libevent
cd $ROOT/lib/libevent-2.0.21-stable
./autogen.sh
./configure --prefix=$LIB_DIR
make
make install

# build database
#cd $ROOT/lib/db-6.1.19/build_unix
#../dist/configure --prefix=$LIB_DIR
#make
#make install

# build paxosudp
cd $ROOT
mkdir -p $ROOT/build
cd $ROOT/build
cmake .. -DLIBEVENT_ROOT=$LIB_DIR -DMSGPACK_ROOT=$LIB_DIR #-DBDB_ROOT=$LIB_DIR
make
