#!/usr/bin/env bash


help_kernel() {
cat << HELP_END
${BAD}mage kernel${NORMAL} - a helper to compile and install linux kernels.

 * ${HILITE}mage kernel make${NORMAL}
 * ${HILITE}mage kernel install${NORMAL}

See also mage help linuxconfig for the ${HILITE}mage linuxconfig${NORMAL}, a linux kernel configuration helper. 

HELP_END
exit ${1:-1}
}
