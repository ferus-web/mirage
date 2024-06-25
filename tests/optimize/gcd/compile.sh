#!/usr/bin/env sh

nim c -d:release --passC:"-flto" --out:gcd-mirage ./gcd.nim &&
gcc ./gcd.c -O2 -o gcd-c &&

hyperfine --shell=none --warmup=500 ./gcd-mirage ./gcd-c
