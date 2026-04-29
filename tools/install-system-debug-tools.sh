#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  gdb \
  gdbserver \
  strace \
  ltrace \
  valgrind \
  mesa-utils \
  x11-apps

