#!/usr/bin/env bash

. /etc/portage/make.conf      # include make.conf


    case "$1" in

        net)
            shift 1;
	    . "${DIR}/bootstrap/net.sh" || eexit "Can't load ${DIR}/bootstrap/net.sh"
	    case "$1" in
	         test)
	              net_test
	         ;;
	         sshd)
	              net_sshd
	         ;;
	    esac
	;;
	disks)
	    shift 1
	    . "${DIR}/bootstrap/disks.sh" || eexit "Can't load ${DIR}/bootstrap/disks.sh"
	    case "$1" in
	         setup)
	              disks_setup
	         ;;
	         remount)
	              disks_remount
	         ;;
	    esac
	;;
	env)
	    shift 1
	    . "${DIR}/bootstrap/env.sh" || eexit "Can't load ${DIR}/bootstrap/env.sh"
	    case "$1" in
	         chroot)
	              env_chroot
	         ;;
	         chroot-reenter)
	              env_chroot_reenter
	         ;;
	    esac
	    
	
	;;
        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help bootstrap${NORMAL}"
        ;;
    esac


