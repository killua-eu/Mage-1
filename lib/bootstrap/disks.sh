#!/usr/bin/env bash

disks_info() {
    einfo "Available storage devices (`cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9] | wc -l`):"
    cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9]
    echo ""
    einfo "Existing partitions (parted -l):"
    parted -l
}

disks_setup() {
    sdcount=`cat /proc/partitions | awk '{print $4}' | grep sd[a-z] | grep -v [0-9] | wc -l`
    echo ""
    einfo "We have following options and it seems you have ${sdcount} disks, unless there's a thumbdrive installed now:"
    echo ""
    einfo "    1) Server setup (2 disks): 2x biosboot + mdraid1.ext4 /boot + mdraid1.ext4 swap + btrfs.raid1 root"
    einfo "    2) General setup (1 disk): 1x biosboot + ext4 /boot + swap + btrfs root"
    einfo "    3) General setup (1 disk): 1x biosboot + ext4 /boot + swap + ext4 root + aufs patch"
    echo ""
    ewarn "Pick your choice: " && read choice

    case "$choice" in
        1)
	    disks_info
            efail "Continuing here will permanently delete any data on disks you play with"
            einfo "Set device 1 (usually /dev/sda)" && read dev1
            einfo "Set device 2 (usually /dev/sdb)" && read dev2
            # Partitioning
            disks_parted_def "${dev1}"
            disks_parted_def "${dev2}"
            # FS
            disks_btrfsraid1_root_btrfs_raid1  "${dev1}4" "${dev2}4"
            disks_btrfsraid1_boot_mdraid1_ext4 "${dev1}2" "${dev2}2"
            disks_btrfsraid1_swap_mdraid1      "${dev1}3" "${dev2}3"
        ;;
        2)
            disks_info # may not like thumbdrive (error Invalid partition table - recursive partition on /dev/sdb. ignore/cancel?
            efail "Continuing here will permanently delete any data on disks you play with"
            einfo "Set the disk to install stuff on (usually /dev/sda)" && read dev1
            # Partitioning
            disks_parted_def "${dev1}"
            # FS
            disks_btrfssingle_root_btrfs_single "${dev1}4"
            disks_single_boot_single_ext4       "${dev1}2"
            disks_single_swap_single            "${dev1}3"
        ;;
        *)
            efail "Not implemented yet, sorry, try something else."
        ;;    
    esac    
}


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

disks_parted_def() {
    einfo "Partitioning ${1} with the default ${BOLD}biosboot, boot, swap, root${NORMAL} scheme"
    blockfile_exists "${1}"
    [[ -v MAGE_PARTED_DEF_BIOS ]] || MAGE_PARTED_DEF_BIOS=8M
    [[ -v MAGE_PARTED_DEF_BOOT ]] || MAGE_PARTED_DEF_BOOT=500M
    [[ -v MAGE_PARTED_DEF_SWAP ]] || MAGE_PARTED_DEF_SWAP=12G
    # MAGE_PARTED_DEF_ROOT defined in mage.conf with explanation that it will be ignored here
    # and the rest of the disk's space will be used for the root partition

    parted -a optimal ${1} mklabel gpt                                                             # convert mbr to gpt
    sgdisk -o ${1}                                                                                 # clear partition table
    FS=`sgdisk -F ${1}` ; sgdisk -n 1:${FS}:${MAGE_PARTED_DEF_BIOS} -c 1:"biosboot" -t 1:ef02 ${1} # GRUB partition (4MB)
    FS=`sgdisk -F ${1}` ; sgdisk -n 2:${FS}:${MAGE_PARTED_DEF_BOOT} -c 2:"boot" -t 2:8300 ${1}     # /boot partition (400M)
    FS=`sgdisk -F ${1}` ; sgdisk -n 3:${FS}:${MAGE_PARTED_DEF_SWAP} -c 3:"swap" -t 3:8200 ${1}     # swap partition
    FS=`sgdisk -F ${1}` ; 
    ES=`sgdisk -E ${1}` ; sgdisk -n 4:${FS}:${ES} -c 4:"root" -t 4:8300 ${1}                       # root partition
    echo ""
    edone "Partitioning done, the resulting scheme is below for your pleasure:"
    sgdisk -p ${1}
    # TODO catch return codes of sgdisk and parted
}


disks_ext4single_root_ext4_single() {
   einfo "Setting up ext4 on ${1} [single disk setup]"
   efail "This function isnt implemented yet"
}


btrfs_subvols_def() {

    # Create default btrfs subvolumes set
    
    # Mount btrfs
    einfo "Creating subvolumes"
    mkdir -p /mnt/{btrfs,gentoo}
    mount -t btrfs -o defaults,noatime,compress=lzo,autodefrag "${1}" /mnt/btrfs || eexit "Failed mounting /mnt/btrfs"
    pushd /mnt/btrfs >> /dev/null
    
    # Create subvolumes @,@/root,@/home, ...
    btrfs subvolume create @    || eexit "Failed creating @ subvolume"
    btrfs subvolume create root || eexit "Failed creating root subvolume"
    btrfs subvolume create home || eexit "Failed creating home subvolume"
    btrfs subvolume create tmp  || eexit "Failed creating tmp subvolume"
    mkdir -p var/lib
    btrfs subvolume create var/log || eexit "Failed creating var/log subvolume"
    btrfs subvolume create var/spool || eexit "Failed creating var/spool subvolume"

    # Unmount again and remount with options
    popd
    umount /mnt/btrfs
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@ "${1}" /mnt/gentoo || eexit "Failed mounting /mnt/gentoo"
    sleep 1
    mkdir -p /mnt/gentoo/{home,root,var,tmp}
    mkdir -p /mnt/gentoo/var/{spool,log}    
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=home "${1}" /mnt/gentoo/home || eexit "Failed mounting /mnt/gentoo/home"
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=root "${1}" /mnt/gentoo/root || eexit "Failed mounting /mnt/gentoo/root" 
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=tmp "${1}" /mnt/gentoo/tmp || eexit "Failed mounting /mnt/gentoo/tmp"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=var/log "${1}" /mnt/gentoo/var/log || eexit "Failed mounting /mnt/gentoo/var/log"
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=var/spool "${1}" /mnt/gentoo/var/spool || eexit "Failed mounting /mnt/gentoo/var/spool"

    # Copy-on-write comes with some advantages, but can negatively affect performance with large files that have 
    # small random writes because it will fragment them (even if no "copy" is ever performed!). It is recommended
    # to disable copy-on-write for database files and virtual machine images. 
    #
    # Snapshotting is still doable even with COW off: http://ram.kossboss.com/btrfs-disabling-cow-file-directory-nodatacow/
    #
    # Subovlumes instead of directories are superimportant to not allow to roll back certain log-files, databases
    # etc. when rolling back the root subvolume. See also:
    # https://www.suse.com/documentation/sled-12/book_sle_admin/data/sec_snapper_setup.html#snapper_dir-excludes
    #
    # /var/lib/mysql, /var/www and other well usable subvolumes should be created by pkg_setup() hooks in 
    # /etc/portage/env/pkg-class/pkg-name (http://blog.yjl.im/2014/05/using-epatchuser-to-patch-gentoo.html)

}

disks_btrfssingle_root_btrfs_single() {
    echo ""
    einfo "Setting up btrfs on ${1} [single disk setup]"
    echo ""
    blockfile_exists "${1}"
    mkfs.btrfs -f -L "root" "${1}" || eexit "mkfs.btrfs (root) failed"
    btrfs_subvols_def "${1}"
}


disks_btrfsraid1_root_btrfs_raid1() {
    echo ""
    einfo "Setting up btrfs on ${1} + ${2} [btrfs-raid1]"
    einfo "Creating btrfs filesystem on ${1} and ${2} (root) using btrfs-raid1 ..."
    blockfile_exists "${1}" "${2}"
    mkfs.btrfs -f -L "root" -d raid1 -m raid1 "${1}" "${2}" || eexit "mkfs.btrfs (root) failed"
    btrfs_subvols_def "${1}"
}

disks_btrfsraid1_boot_mdraid1_ext4() {
  mddev="/dev/md0"
  einfo "Setting up ext4 on ${mddev} [md-raid1 ver. 0.9 device consisting of ${1}, ${2} partitions]"
  blockfile_exists "${1}" "${2}"
  [[ -b "$mddev" ]] && eexit "Device ${mddev} already exists, continuing would destroy all data on it. Exitting"
  mdadm --create "${mddev}" --name boot --level 1 --metadata 0.9 --raid-devices=2 "${1}" "${2}"
  mkfs.ext4 -L boot "${mddev}"
  mkdir -p /mnt/gentoo/boot
  mount "${mddev}" /mnt/gentoo/boot
}

disks_single_boot_single_ext4() {
    echo ""
    einfo "Setting up ext4 on ${1} [single disk setup]"
    echo ""
    blockfile_exists "${1}"
    mkfs.ext4 -L boot "${1}" || eexit "mkfs.btrfs (boot) failed"
    mkdir -p /mnt/gentoo/boot
    mount "${1}" /mnt/gentoo/boot
}


disks_single_swap_single() {
    echo ""
    einfo "Setting up swap on ${1} [single disk setup]"
    echo ""
    blockfile_exists "${1}"
    mkswap ${1} || eexit "mkswap failed"
    swapon ${1} || eexit "swapon failed"
}


disks_btrfsraid1_swap_mdraid1() {
    mddev="/dev/md1"
    einfo "Setting up swap on ${mddev} [md-raid1 ver. 0.9 device consisting of ${1}, ${2} partitions]"
    blockfile_exists "${1}" "${2}"
    [[ -b "$mddev" ]] && eexit "Device ${mddev} already exists, continuing would destroy all data on it. Exitting"
    # Swapping on a mirrored RAID can help you survive a failing disk. If a disk fails, 
    # then data for swapped processes would be inaccessable in a non-mirrored environment.
    mdadm --create /dev/md1 --name swap --level 1 --metadata 0.9 --raid-devices=2 "${1}" "${2}"
    mkswap ${mddev}
    swapon ${mddev}
}


disks_btrfsraid1_mountall() {
    rootpart=${1} # i.e. /dev/sda4
    bootpart=${2} # i.e. /dev/md0 or /dev/md126 (in case of mdraid1) or /dev/sda2 (in case of single disk)
    mkdir -p /mnt/gentoo
    mkdir -p /mnt/gentoo/{home,boot,tmp,var}
    mkdir -p /mnt/gentoo/var/{spool,tmp,log}

    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=root ${1} /mnt/gentoo || eexit "Failed mounting /mnt/gentoo"
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=home "${1}" /mnt/gentoo/home || eexit "Failed mounting /mnt/gentoo/home"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=tmp "${1}" /mnt/gentoo/tmp || eexit "Failed mounting /mnt/gentoo/tmp"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=varlog "${1}" /mnt/gentoo/var/log || eexit "Failed mounting /mnt/gentoo/var/log"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=vartmp "${1}" /mnt/gentoo/var/tmp || eexit "Failed mounting /mnt/gentoo/var/tmp"
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=varspool "${1}" /mnt/gentoo/var/spool || eexit "Failed mounting /mnt/gentoo/var/spool"

    mount ${bootpart} /mnt/gentoo/boot  || eexit "Failed mounting /mnt/gentoo/boot"
}



disks_btrfsraid1_finish() {
# TODO this function is currently in the env.sh file for testing, where it doesnt actually belong.
}


disks_remount() {
    # Used to remount partitions after powerdown/freeze
    ewarn "Remounting partitions should be only required if an unexpected reboot during the installation occured."
    ewarn "Oterwise, you might just fuck up (luckily not too bad) your install. Quit with Ctrl+C or continue"
    einfo "Available devices:"
    echo ""
    ls -l /dev | grep -E ' (sd|hd|md)..?$'
    echo ""
    ewarn "Now a teaser, you gotta remember what disk layout you installed:"
    einfo " 1) Server setup (2 disks): 2x biosboot + mdraid1.ext4 /boot + mdraid1.ext4 swap + btrfs.raid1 root"
    einfo " 2) General setup (1 disk): 1x biosboot + ext4 /boot + swap + btrfs root"
    einfo " 3) General setup (1 disk): 1x biosboot + ext4 /boot + swap + ext4 root + aufs patch"
    echo -e ""
    ewarn "Pick your choice: " && read choice

    case "$choice" in
        1)
            einfo "Set the root device (usually sda4)" && read rootdev
            einfo "Set the boot device (usually md0 or md126)" && read bootdev
            disks_btrfsraid1_mountall ${rootdev} ${bootdev}
        ;;
        2)
            einfo "Set the root device (usually sda4)" && read rootdev
            einfo "Set the boot device (usually sda2)" && read bootdev
            disks_btrfsraid1_mountall ${rootdev} ${bootdev}
        ;;
        *)
            eexit "Not implemented yet, sorry, exitting."
        ;;    
    esac
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