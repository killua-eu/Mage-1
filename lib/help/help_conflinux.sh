#!/usr/bin/env bash

help_conflinux() {
cat << HELP_END
${BAD}mage conflinux <testedconfig> <requirements> [problems]${NORMAL}
is a tool checking the linux configuration file such as /proc/config.gz
or /usr/src/linux/.config (set with <testedconfig>) against predefined
<requirements> that are currently distributed in /etc/mage/configlinux/*
files. [problems] is an optional switch that displays only problems in
<testedconfig>. If <requirements> is a directory, all files in the directory
are concated and used as a united set of requirements. Examples:

mage conflinux /proc/config.gz /etc/mage/conflinux problems
mage conflinux /usr/src/linux/.config /etc/mage/conflinux/defaults
HELP_END
exit ${1:-1}
}

