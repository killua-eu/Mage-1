#!/usr/bin/env bash


net_test() {
    einfo "Testing network connection ..."

    ping -c 1 8.8.8.8 || {
        echo  ""
        efail "The network is dead, check physical connection."
        efail "If all's right, you need to configure your network manually. If you booted"
        efail "a Gentoo minimal ISO, try running run ${HILITE}net-setup <interface-name>${NORMAL}."
        efail "Even though net-setup is screwed up (Aug 2015), it might help you."
        efail "Your active interfaces including lo are:"
        echo  "";
        ifconfig -a | sed 's/[ \t].*//;/^$/d' | sed 's/.$//'
        echo  "";
        efail "(for more run ${HILITE}ifconfig${NORMAL}). An example of the /etc/conf.d/net file for a static"
        eexit "IP setup is in ${BOLD}${DIR}/bootstrap/files/static-conf.d-net${NORMAL}"
    }

    ping -c 1 google.com || {
        echo  "";
        efail "Your network connection works, but DNS doesn't." 
        efail "Try using a public DNS server, i.e. Google's 8.8.8.8. To do this, just run" 
        eexit "${HILITE}echo 'nameserver 8.8.8.8' >> /etc/resolv.conf'${NORMAL}."
    }
    
    echo "" ; edone "Network connection seems to work just fine." ; exit 0 ;
    
}
    
net_sshd() {
    [[ `whoami` = "root" ]] || eexit "You have to be root to do this."
    einfo "Starting sshd ..."
    initsys=`cat /proc/1/comm`
    
    
    case "${initsys}" in
    systemd) 
        systemctl start sshd || eexit "sshd could not be started"
    ;;
    openrc)
        /etc/init.d/sshd start || eexit "sshd could not be started"
    ;;
    *)
        ewarn "Unknown init system, please start sshd manually yourself."
    ;;
    esac
    
    [[ -v MAGE_BOOTSTRAP_UNAME ]] || einfo "Enter temporary (install-time) username: " && read MAGE_BOOTSTRAP_UNAME
    [[ -v MAGE_BOOTSTRAP_UPASS ]] || einfo "Enter temporary (install-time) password for user ${MAGE_BOOTSTRAP_UNAME}: " && read MAGE_BOOTSTRAP_UPASS
    [[ -v MAGE_BOOTSTRAP_RPASS ]] || einfo "Enter temporary (install-time) root password: " && read MAGE_BOOTSTRAP_RPASS

    useradd -m -G users,wheel ${MAGE_BOOTSTRAP_UNAME} || eexit "Failed to create user ${MAGE_BOOTSTRAP_UNAME}"
    echo "${MAGE_BOOTSTRAP_UNAME}:${MAGE_BOOTSTRAP_UPASS}" | chpasswd || eexit "Changing ${MAGE_BOOTSTRAP_UNAME}'s password failed"
    echo "root:${MAGE_BOOTSTRAP_RPASS}" | chpasswd || eexit "Changing root password failed"
    edone "You're now ready to connect to the installation environment over ssh by issuing"
    edone "${HILITE}ssh ${MAGE_BOOTSTRAP_UNAME}@<ipaddress>${NORMAL} on your desktop."
}

