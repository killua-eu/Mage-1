#!/usr/bin/env bash

. /etc/portage/make.conf            # include make.conf
. "${ETCDIR}/mage/bootstrap.conf"   # include make.conf

    case "$1" in

        net)
            shift 1;
	    . "${LIBDIR}/bootstrap/net.sh" || eexit "Can't load ${LIBDIR}/bootstrap/net.sh"
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
	    . "${LIBDIR}/bootstrap/disks.sh" || eexit "Can't load ${LIBDIR}/bootstrap/disks.sh"
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
	    . "${LIBDIR}/bootstrap/env.sh" || eexit "Can't load ${LIBDIR}/bootstrap/env.sh"
	    case "$1" in
	         chroot)
	              env_chroot
	         ;;
	         chroot-reenter)
	              env_chroot_reenter
	         ;;
	         prepare)
	              env_prepare
	         ;;
	         install)
	              env_install
	         ;;
	         kernel)
	              env_kernel
	         ;;
	         user)
	              env_user
	         ;;
	         bootloader)
	              env_bootloader
	         ;;
	    esac
	    	
	;;
        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help bootstrap${NORMAL}"
        ;;
    esac


