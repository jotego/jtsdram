#!/bin/bash

eval `jtcfgstr -target=mist -output=bash -core ldtest`

# Generic simulation script for JTFRAME
jtsim -mist -sysname ldtest  \
    -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    -verilator -keepcpp $*
