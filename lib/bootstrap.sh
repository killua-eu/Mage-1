#!/usr/bin/env bash

. /etc/portage/make.conf            # include make.conf
. "${ETCDIR}/mage/bootstrap.conf"   # include make.conf


firstboot() {
    # firstboot() detects if we're in a chroot and either executes a command, or queues it up
    # into the /var/mage/firstboot file. Here's why:
    # - Installing Gentoo from stage3 requires you to work from a chrooted environment,
    # - Systemd won't run in a chrooted environment,
    # - We want to run commands such as systemctl, which require Systemd to run.
    
    # Detect if we're in a chroot
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
        [[ -d "/var/mage" ]] && mkdir -p /var/mage || eexit "Couldn't create /var/mage directory"
        [[ -f "/var/mage/firstboot" ]] && echo "#!/usr/bin/env bash" > /var/mage/firstboot || eexit "Couldn't write to /var/mage/firstboot file"
        echo "$@" >> /var/mage/firstboot
    else
        set -x; "$@"; set +x;
    fi
}

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
	refresh)
	    shift 1
	    . "${LIBDIR}/bootstrap/refresh.sh" || eexit "Can't load ${LIBDIR}/bootstrap/refresh.sh"
	    refresh
	;;

        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help bootstrap${NORMAL}"
        ;;
    esac


