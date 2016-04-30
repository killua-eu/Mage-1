#!/usr/bin/env bash
echo "${1}"
. "${LIBDIR}/help/help_mage.sh" || eexit "Can't load ${LIBDIR}/help/help_mage.sh"
	if [ "$#" -eq 0 ]; then
	    help_banner
	    help_usage
	else
	    case "$1" in
		tmerge)
		    . "${LIBDIR}/help/help_tmerge.sh" || eexit "Can't load ${LIBDIR}/help/help_tmerge.sh"
		    help_banner
		    help_tmerge
		;;
		kernel)
		    . "${LIBDIR}/help/help_kernel.sh" || eexit "Can't load ${LIBDIR}/help/help_kernel.sh"
		    help_banner
		    help_kernel
		;;
		bootstrap)
		    . "${LIBDIR}/help/help_bootstrap.sh" || eexit "Can't load ${LIBDIR}/help/help_bootstrap.sh"
		    help_banner
		    help_bootstrap
		;;
		linuxconfig)
		    . "${LIBDIR}/help/help_linuxconfig.sh" || eexit "Can't load ${LIBDIR}/help/help_linuxconfig.sh"
		    help_banner
		    help_linuxconfig
		;;
		listdrivers)
		    . "${LIBDIR}/help/help_listdrivers.sh" || eexit "Can't load ${LIBDIR}/help/help_listdrivers.sh"
		    help_banner
		    help_listdrivers
		;;
		overlay)
		    . "${LIBDIR}/help/help_overlay.sh" || eexit "Can't load ${LIBDIR}/help/help_overlay.sh"
		    help_banner
		    help_overlay
		;;
		*)
		    echo -e "Sorry, no additional help available for action ${BAD}$1${NORMAL}, or action not recognized"
		    echo -e "Try ${BOLD}mage help${NORMAL} for a list of valid actions."
		    exit 1;
		esac
	 fi

