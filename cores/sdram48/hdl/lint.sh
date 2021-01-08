#!/bin/bash

verilator -f jtsdram.f --lint-only --top-module jtsdram_game
