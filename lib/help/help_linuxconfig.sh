#!/usr/bin/env bash

help_linuxconfig() {
cat << HELP_END
${BAD}mage conflinux <requirements> <testedconfig> [problems]${NORMAL}
is a tool checking the linux configuration file such as /proc/config.gz
or /usr/src/linux/.config (set with <testedconfig>) against predefined
<requirements> that are currently distributed in /etc/mage/configlinux/*
files. [problems] is an optional switch that displays only problems in
<testedconfig>. Examples:

mage linuxconfig "/etc/mage/conflinux/*" /proc/config.gz problems
mage linuxconfig "/etc/mage/conflinux/defaults" /usr/src/linux/.config
HELP_END
exit ${1:-1}
}

