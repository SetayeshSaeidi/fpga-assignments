#!/usr/bin/env bash
# Compile and run every testbench in a question folder with Icarus Verilog.
# Usage: ./sim.sh hw3/q3-two-stack-fifo
set -euo pipefail

dir="${1:?usage: ./sim.sh <question-folder>}"
cd "$dir"

designs=()
for f in *.v; do
  [[ "$f" == *tb* ]] || designs+=("$f")
done

for tb in *tb*.v; do
  echo "=== $tb"
  # Testbenches that `include their design files are compiled on their own.
  if grep -q '`include' "$tb"; then
    iverilog -g2012 -I . -o sim.vvp "$tb"
  else
    iverilog -g2012 -I . -o sim.vvp "$tb" "${designs[@]}"
  fi
  vvp -n sim.vvp
  rm -f sim.vvp
done
