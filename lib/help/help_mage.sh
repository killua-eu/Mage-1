#!/usr/bin/env bash

help_banner() {
cat << HELP_END
${BOLD}mage: ${NORMAL}command-line interface to manage a Gentoo box

HELP_END
}

help_usage() {
cat << HELP_END1
${BOLD}Usage: 
     ${BAD}mage${NORMAL} ${GOOD}[action]${NORMAL} ${BRACKET}[options]${NORMAL}
     ${BAD}mage help${NORMAL} ${BRACKET}[action]${NORMAL}

${BOLD}All actions:${NORMAL}
     ${GOOD}* help  ${NORMAL}              This help message.
     ${GOOD}* bootstrap${NORMAL}           A semi-interactive Gentoo installer.
     ${GOOD}* linuxconfig${NORMAL}         A linux kernel configuration test tool.
     ${GOOD}* listdrivers${NORMAL}         List config settings of kernel drivers' currently in use
     ${GOOD}* kernel${NORMAL}              Configure, compile and install the Linux kernel.
     ${GOOD}* test${NORMAL}                Test mage.
     ${GOOD}* tmerge${NORMAL}              Emerge on tmpfs.

HELP_END1
exit ${1:-1}
}

