#!/bin/bash
SYSNAME=sdram48

eval `jtcfgstr -core $SYSNAME -output bash`
# Use -d ONEBANK to simulate only one bank

# Generic simulation script from JTFRAME
jtsim -mist -sysname $SYSNAME $*
