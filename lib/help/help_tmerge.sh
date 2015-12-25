#!/usr/bin/env bash

help_tmerge() {
cat << HELP_END
${BAD}mage tmerge${NORMAL} runs emerge (the cli interface for Portage, Gentoo's package
with disabled power cpu powersaving and using a tmpfs device
mounted at /var/tmp/portage-tmpfs as a temporary compile-time storage.
Use it as emerge, so i.e. to 'emerge -uDNa world' in memory just do
${HILITE}mage tmerge -uDNa world${NORMAL}

HELP_END
exit ${1:-1}
}

