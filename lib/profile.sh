#!/usr/bin/env bash

. /etc/portage/make.conf      # include make.conf


    case "$1" in

        enable)
            shift 1;
	    #. "${DIR}/bootstrap/net.sh" || eexit "Can't load ${DIR}/bootstrap/net.sh"
	;;
        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help profile${NORMAL}"
        ;;
    esac


