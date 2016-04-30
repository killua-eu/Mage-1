#!/usr/bin/env bash

help_listdrivers() {
cat << HELP_END
${BAD}mage listdrivers${NORMAL}
This will get a list of kernel drivers currently in use (lspci -k | grep driver) and grep it against the kernel's config to get a list of options and their value.
HELP_END
exit ${1:-1}
}

