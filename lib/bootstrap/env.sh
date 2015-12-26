#!/usr/bin/env bash

# Prepare the chroot environment(download and extract stage3 to /mnt/gentoo, tweak /etc/portage files
env_prepare() {
  einfo "Preparing the /mnt/gentoo environment"
  einfo "Getting current stage3 version..."
  mountpoint -q /mnt/gentoo || eexit "/mnt/gentoo is expected to be a mountpoint"
  cd /mnt/gentoo || eexit "Failed to change directory to /mnt/gentoo"
  STAGE3=$(wget -O - http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64.txt 2> /dev/null | sed -n 3p | awk -F'/' '{ print $1}')
  STAGE3_FILE="/mnt/gentoo/stage3-amd64-$STAGE3.tar.bz2"
  SRC="http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3/stage3-amd64-$STAGE3.tar.bz2"
  einfo "Downloading stage3-amd64-$STAGE3.tar.bz2"
  wget -N "$SRC" -O "$STAGE3_FILE" > /dev/null 1> /dev/null 2> /dev/null
  ls "./stage3-amd64-$STAGE3.tar.bz2" || eexit "Failed to fetch ${SRC}"
  edone "stage3-amd64-$STAGE3.tar.bz2 downloaded" && echo  ""
  
  einfo "Extracting stage3-amd64-$STAGE3.tar.bz2"
  tar xvjpf "stage3-amd64-${STAGE3}.tar.bz2" --xattrs || eexit "Failed to extract the stage3-amd64-${STAGE3}.tar.bz2 archive"
  edone "stage3-amd64-$STAGE3.tar.bz2 extracted" && echo  ""

  einfo "Updating portage's make.conf defaults"
  echo "MAKEOPTS=\"-j"$((`nproc` + 1))\" >> /mnt/gentoo/etc/portage/make.conf
  echo "PORTAGE_ELOG_CLASSES=\"info log warn error\"" >> /mnt/gentoo/etc/portage/make.conf
  echo "PORTAGE_ELOG_SYSTEM=\"save\"" >> /mnt/gentoo/etc/portage/make.conf
  echo "FEATURES=\"cgroup parallel-install\"" >> /mnt/gentoo/etc/portage/make.conf
  edone "make.conf defaults set" && echo  ""

# Enter the /mnt/gentoo chroot (this should work after having booted from any linux livecd)
env_chroot() {
  einfo "Chrooting into /mnt/gentoo"
  ismounted /mnt/gentoo || eexit "/mnt/gentoo unmounted or not a mount point. If you rebooted, you may need to remount partitions (and/or volumes and subvolumes), \`mage env chroot-reenter\` should do that for you. If this is a first installation, either something went really wrong, or you did some steps out of expected order. Either way, you're screwed. You may want to try to ask on github or in gentoo forums tho (beware that mage is not an official thing, so support might be scarse)."
  cp -L /etc/resolv.conf /mnt/gentoo/etc/
  mount -t proc proc /mnt/gentoo/proc
  mount --rbind /sys /mnt/gentoo/sys
  mount --rbind /dev /mnt/gentoo/dev
  mount --make-rslave /mnt/gentoo/{sys,dev}
  rm /dev/shm && mkdir /dev/shm
  mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
  chmod 1777 /dev/smh
  chroot /mnt/gentoo /bin/bash -c "printf '\033[33;01m[*] YOU ARE NOW IN THE /MNT/GENTOO CHROOT.\033[0m\n\033[01m[!] Please run:\n    source /etc/profile\n    env-update\n    export PS1=\"(chroot) \$PS1\"\n    mage env install' && echo \"    ${1}\"" 
  chroot /mnt/gentoo /bin/bash
}

# In case that env_install gets interrupted (i.e. power failure, frozen ILO, random reboot, accidental meteorite showers etc.)
env_chroot_reenter() {
  mage bootstrap net test
  mage bootstrap disks remount
  mage bootstrap env chroot
}

# Install Gentoo with all the packages, configure kernel, write /etc/fstab, reboot & enjoy
env_install() {
  einfo "Syncing portage tree ..."
  emerge-webrsync || ewarn "emerge-webrsync failed (bad connection or server down?)"
  edone "Portage tree synced."
  
  einfo "Setting profile ..."
  case "${BOOTSTRAP_PROFILE}" in
    desktop-gnome) 
        eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
    ;;
    server)
        eselect profile set "default/linux/amd64/13.0/systemd"
    ;;
    *)
        eexit "BOOTSTRAP_PROFILE in /etc/mage/bootstrap.conf is misconfigured."
    ;;
  esac
  echo "" && eselect profile show echo ""
  
  einfo "Emerging baseline portage utilities"
  emerge app-portage/cpuinfo2cpuflags app-portage/flaggie app-portage/eix || eexit "Emerge failed"
  edone "Baseline portage utilities emerged"
  
  einfo "Finalizing portage and make.conf configuration ..."
  mkdir -p /etc/portage/{package.mask,package.unmask,sets,repos.conf,package.accept_keywords,package.use,env,package}
  cpuinfo2cpuflags-x86 >> /etc/portage/make.conf
  echo "sys-kernel/dracut" >> /etc/portage/package.accept_keywords/mage-sys-core
  flaggie +systemd +vaapi +vdpau
  # If BOOTSTRAP_MAKECONF* parameters from /etc/mage/bootstrap.conf are set, set make.conf accordingly
  [[ ! -z ${BOOTSTRAP_MAKECONF_LINGUAS} ]] && echo "LINGUAS=${BOOTSTRAP_MAKECONF_LINGUAS}" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_ACCEPT_LICENSE} ]] && echo "ACCEPT_LICENSE=${BOOTSTRAP_MAKECONF_ACCEPT_LICENSE}" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_INPUT_DEVICES} ]] && echo "INPUT_DEVICES=${BOOTSTRAP_MAKECONF_INPUT_DEVICES}" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_VIDEO_CARDS} ]] && echo "VIDEO_CARDS=${BOOTSTRAP_MAKECONF_VIDEO_CARDS}" >> /etc/portage/make.conf
  edone "Portage and make.conf configuration now set to good defaults"
  
  einfo "Getting some Mage sets ..."
  pushd /etc/portage/sets/
  wget https://raw.githubusercontent.com/Vaizard/Mage/master/etc/portage/sets/{mage-sys-portage,mage-sys-core,mage-sys-fs,mage-sys-net,mage-adm-tools} || eexit "Downloading Mage sets for portage failed"
  popd
  edone "Mage sets installed into /etc/portage/sets"
  


  
  ls /usr/share/zoneinfo
  echo "Europe/Prague" > /etc/timezone
  emerge --config sys-libs/timezone-data
  echo "en_US ISO-8859-1
en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  eselect locale list # select en_US.utf8
  mkdir -p /etc/portage/{package.mask,package.unmask,sets,repos.conf,package.accept_keywords,package.use,env,package}
  # download sets
  emerge @portage
  
echo "en_US ISO-8859-1
en_US.UTF-8 UTF-8
cs_CZ.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.utf8
timedatectl set-timezone Europe/Prague


  eix-update
  eix-sync
  emerge -uDN @kernel @boot @core @tools
  cd /usr/src/linux
  make nconfig
  make && make modules_install
  make install # copy stuff to /boot
  
  mkdir -p /var/mage/repos
  ln -s /usr/portage /var/mage/repos/gentoo
  ln -s /usr/local/portage /var/mage/repos/local
  ln -s /var/lib/layman /var/mage/repos/layman
  ln -s /usr/lib/portage /var/mage/repos/layman
  {gentoo,distfiles,local,layman}
  mkdir -p /tmp/portage
  mv /usr/portage/* /var/portage/gentoo/
  mkdir -p /boot/efi/boot
  cp /boot/vmlinuz-* /boot/efi/boot/bootx64.efi
  dracut --hostonly 
  grub2-install /dev/sda
  grub2-install /dev/sdb
  grub2-mkconfig -o /boot/grub/grub.cfg
  # errors
  #  /run/lvm/lvmetad.socket: connect failed: No such file or directory
  # WARNING: Failed to connect to lvmetad. Falling back to internal scanning.
  # No volume groups found
  # can be ignored
  echo "
# <fs>              <mountpoint>    <type>      <opts>                                              <dump/pass>
LABEL="boot"        /boot           ext2        noauto,noatime                                          1 2
LABEL="root"        /               brtfs       defaults,noatime,compress=lzo,autodefrag,subvol=root    0 0
LABEL="root"        /home           brtfs       defaults,noatime,compress=lzo,autodefrag,subvol=home    0 0
LABEL="swap"        none            swap        sw                                                      0 0
" >> /etc/fstab
}
