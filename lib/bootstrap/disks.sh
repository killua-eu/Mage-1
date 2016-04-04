#!/usr/bin/env bash

# ###########################################################################################
# Helpers ###################################################################################
# ###########################################################################################

blockfile_exists() {
    echo ""
    einfo "Looking for blockfiles ..."
    while [ "${1+defined}" ]
    do
        [[ -b "$1" ]] && edone "${1}"
        [[ -b "$1" ]] || { 
            efail "${1} not found" 
            error_flag=1
        }
        shift
    done
    [[ ${error_flag} = 1 ]] && eexit "Oops, required blockfiles missing!"
    edone "All good"
    echo ""
    return 0
}


disks_info() {
    einfo "Available storage devices (`cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9] | wc -l`):"
    cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9]
    echo ""
    einfo "Existing partitions (parted -l):"
    parted -l
}

select_file() { # pass path to dir as $1 and default from configuration option as $2
    pushd "${1}" > /dev/null
    shopt -s nullglob
    array=(*)
    shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

    for i in "${!array[@]}"; do 
        printf "\n%s\t%s" "${BOLD}[$i]${NORMAL}" "${array[$i]}"
        [[ "${array[$i]}" == "${2}" ]] && printf " ${BRACKET}*${NORMAL}" && default="${array[$i]}"
    done
   
    echo "";
    popd > /dev/null
    einfo "Select preffered option (or just press enter to default to option selected by your bootstrap.conf)"
    
        
    while [[ -z "$selected" ]]
    do
        read -r option; # read user input and use default on enter, if default is set
        if [ -z $x ] ; then
           [[ -n "${default}" ]] && echo "${default}" && selected="${default}"
           [[ -n "${default}" ]] || echo "No default configured, please choose one of the options above and retry."
        else # if a value is given, test if its a number and a valid array item
           [[ "$option" =~ ^[0-9]+$ ]] && [[ -n "${array[$option]}" ]] && selected="${array[$option]}"
           [[ "$option" =~ ^[0-9]+$ ]] && [[ -n "${array[$option]}" ]] || echo "Not a valid option, please retry."
        fi
    done

    local  __resultvar=$3
    eval $__resultvar="'$selected'"
    # fetch the result with: 
    # select_file "some/path/to/scritps" "default_script_name" "returnvar" 
    # echo ${returnvar}
    }

# ###########################################################################################
# Exec ######################################################################################
# ###########################################################################################

disks_setup() {
    sdcount=`cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9] | wc -l`
    echo ""
    einfo "We have following options and it seems you have ${sdcount} disks, unless there's a thumbdrive installed now:"
    echo ""
    einfo "    1) Single disk: 1x biosboot + ext4 /boot + swap + btrfs root"
    #einfo "    2) Single disk: 1x biosboot + ext4 /boot + swap + ext4 root + aufs patch"
    #einfo "    3) Two disks: 2x biosboot + mdraid1.ext4 /boot + mdraid1.ext4 swap + btrfs.raid1 root"
    echo ""
    ewarn "Your bootstrap conf defaults to <${BOOTSTRAP_PART_SCHEME}>. Press enter to agree, or type in your choice: " && read choice
    [[ "$choice" = "" ]] && choice="${BOOTSTRAP_PART_SCHEME}"
    [[ "$choice" = "single.extboot+btrfsroot" ]] && choice="1"  # TODO rewrite this mess into something normal scananing the ${LIBDIR}/bootstrap/disks for possibilities
    disks_info # may not like thumbdrive (error Invalid partition table - recursive partition on /dev/sdb. ignore/cancel?
    efail "Continuing here will permanently delete any data on disks you play with!"
    
    
    select_file "${LIBDIR}/bootstrap/disks" ${BOOTSTRAP_PART_SCHEME} "choice"
    . "${LIBDIR}/bootstrap/disks/${choice}" || eexit "Can't load ${LIBDIR}/bootstrap/disks/${choice}"
    disks_do_setup()
}


disks_remount() {
    # Used to remount partitions after powerdown/freeze
    ewarn "Remounting partitions should be only required if an unexpected reboot during the installation occured."
    ewarn "Oterwise, you might just fuck up (luckily not too bad) your install. Quit with Ctrl+C or continue"
    einfo "Available devices:"
    echo ""
    ls -l /dev | grep -E ' (sd|hd|md)..?$'
    echo ""
    ewarn "Now a teaser, you gotta remember what disk layout you installed (probably the default marked with *):"
    select_file "${LIBDIR}/bootstrap/disks" ${BOOTSTRAP_PART_SCHEME} "choice"
    . "${LIBDIR}/bootstrap/disks/${choice}" || eexit "Can't load ${LIBDIR}/bootstrap/disks/${choice}"
    disks_do_remount()
}




# http://www.funtoo.org/BTRFS_Fun
# btrfs filesystem df btrfs/
# btrfs filesystem show /dev/sdd1
# http://hackology.co.uk/2014/btrfs-dual-boot-wankery-arch-ubuntu-grub/
# https://lizards.opensuse.org/2012/10/16/snapper-for-everyone/
# https://wiki.gentoo.org/wiki/Snapper
# https://wiki.archlinux.org/index.php/Snapper
# https://wiki.archlinux.org/index.php/Btrfs_-_Tips_and_tricks
# http://events.linuxfoundation.org/sites/events/files/slides/Btrfs-Rollback-LinuxCon-20150907.pdf
# https://github.com/docker/docker/blob/master/contrib/check-config.sh
# https://medium.com/@ramangupta/why-docker-data-containers-are-good-589b3c6c749e


# TODO
#
#http://migmedia.net/~mig/gentoo-auf-btrfs-root
# nahrad
# /dev/BOOT		/boot		ext2		noauto,noatime	1 2
# v /etc/fstab tak, ze misto /dev/BOOT bude UUID.
# viz take https://wiki.archlinux.org/index.php/fstab#Labels
#
# sed  -e "s_/dev/BOOT_$(blkid -o export /dev/sda2 | sed -n '/^UUID=/ p')_g" -i ./fsb
# cat bak | sed  -e "s_/dev/BOOT_$(blkid -o export /dev/sda2 | sed -n '/^UUID=/ p')_g"
