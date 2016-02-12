#!/usr/bin/env bash

. /etc/portage/make.conf      # include make.conf

#
# Prepare
# 

pushd /usr/src/linux > /dev/null || eexit "No kernel installed in /usr/src/linux. Try ${BOLD}eselect kernel list${NORMAL} or ${BOLD}emerge gentoo-sources${NORMAL}"
version=`readlink /usr/src/linux | cut -c7-`

#
# Make
# 

kernel_make() {
    einfo "Running ${BOLD}make && make modules_install${NORMAL} on the (`readlink /usr/src/linux`) kernel"
    make && make modules_install || eexit "Running ${BOLD}make && make modules_install${NORMAL} failed, exitting."
}
#
# Install
# 

kernel_install() {
    einfo "Installing the (`readlink /usr/src/linux`) kernel into /boot"
    [[ -d "/boot" ]] || ewarn "/boot doesnt exist"
    if ![ ${1} == "--mount-test-disabled" ] ; then
      mount | grep boot || mount /boot || eexit "Failed to mount /boot"
    fi
    make install || eexit "Running make install failed, exitting."
    mkdir -p /boot/efi/boot || eexit "Couldn't create /boot/efi/boot"
    cp /boot/vmlinuz-$version /boot/efi/boot/bootx64.efi || eexit "Couldn't copy kernel, exitting." 
    grub2-mkconfig -o /boot/grub/grub.cfg || eexit "grub2-mkconfig failed"
}

#
# All done
#

while [ "$1" ]
do
    case "$1" in

        make)
            shift 1;
	    kernel_make;
        ;;

        install)
            shift 1;
	    kernel_install;
        ;;
        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}make${NORMAL} or ${BOLD}install${NORMAL}"
        ;;
    esac
done
 
popd > /dev/null
edone "Work on Kernel $version succesfully compleeted."
