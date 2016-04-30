#!/usr/bin/env bash

lspci -k | grep driver | uniq | awk '{print toupper($0)}' | sed 's/KERNEL DRIVER IN USE: //g' | sed 's/^[ \t]*//' | zgrep -f - /proc/config | sed '/^#/ d'