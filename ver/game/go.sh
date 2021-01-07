#!/bin/bash

# Use -d ONEBANK to simulate only one bank

# Generic simulation script from JTFRAME
$JTFRAME/bin/sim.sh -mist \
    -sysname sdram  \
    -def ../../hdl/jtsdram.def \
    -videow 256 -videoh 224 $*
    #-d CPSB_CONFIG="$CPSB_CONFIG" \
