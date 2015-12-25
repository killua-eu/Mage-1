#!/usr/bin/env bash
# TODO help: echo "mage mk_overlay `hostname`-local /usr/local/portage"
help_overlay() {
cat << HELP_END
${BAD}mage overlay${NORMAL} - no help available yet
 
HELP_END
exit ${1:-1}
}
