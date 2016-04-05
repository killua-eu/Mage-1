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
  
  einfo "Extracting stage3-amd64-$STAGE3.tar.bz2 ..."
  tar xjpf "stage3-amd64-${STAGE3}.tar.bz2" --xattrs || eexit "Failed to extract the stage3-amd64-${STAGE3}.tar.bz2 archive"
  edone "stage3-amd64-$STAGE3.tar.bz2 extracted" && echo  ""
}

# Enter the /mnt/gentoo chroot (this should work after having booted from any linux livecd)
env_chroot() {
  einfo "Chrooting into /mnt/gentoo"
  ismounted /mnt/gentoo || eexit "/mnt/gentoo unmounted or not a mount point. If you rebooted, you may need to remount partitions (and/or volumes and subvolumes), \`mage env chroot-reenter\` should do that for you. If this is a first installation, either something went really wrong, or you did some steps out of expected order. Either way, you're screwed. You may want to try to ask on github or in gentoo forums tho (beware that mage is not an official thing, so support might be scarse)."
  #cp -r ~/Mage-master /mnt/gentoo
  [[ -d "/mnt/gentoo/etc/" ]] || eexit "env prepare stage was probably not called or failed"
  cp -L /etc/resolv.conf /mnt/gentoo/etc/
  cp -r /root/Mage-master /mnt/gentoo      # copying
  mount -t proc proc /mnt/gentoo/proc
  mount --rbind /sys /mnt/gentoo/sys
  mount --rbind /dev /mnt/gentoo/dev
  mount --make-rslave /mnt/gentoo/{sys,dev}
  rm /dev/shm && mkdir /dev/shm
  mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
  chmod 1777 /dev/smh
  chroot /mnt/gentoo /bin/bash -c "printf '\033[33;01m[*] YOU ARE NOW IN THE /MNT/GENTOO CHROOT.\033[0m\n\033[01m[!] Please run:\n    source /etc/profile\n    env-update\n    export PS1=\"(chroot) \$PS1\"\n    mage bootstrap env install' && echo \"    ${1}\"" 
  chroot /mnt/gentoo /bin/bash
}

# In case that env_install gets interrupted (i.e. power failure, frozen ILO, random reboot, accidental meteorite showers etc.)
env_chroot_reenter() {
  echo `${SCRIPT} bootstrap net test`
  echo `${SCRIPT} bootstrap disks remount`
  echo `${SCRIPT} bootstrap env chroot`
}

# Configure the environment and install userspace
env_install() {
  einfo "Syncing portage tree ..."
  emerge-webrsync || ewarn "emerge-webrsync failed (bad connection or server down?)"
  edone "Portage tree synced."
  sleep 5 # TODO REMOVE
  
  einfo "Updating portage's make.conf defaults"
  echo "MAKEOPTS=\"-j$((`nproc` + 1))\"" >> /etc/portage/make.conf
  echo "PORTAGE_ELOG_CLASSES=\"info log warn error\"" >> /etc/portage/make.conf
  echo "PORTAGE_ELOG_SYSTEM=\"save\"" >> /etc/portage/make.conf
  echo "FEATURES=\"cgroup parallel-install\"" >> /etc/portage/make.conf
  echo "EMERGE_DEFAULT_OPTS=\"--jobs=2\"" >> /etc/portage/make.conf
  edone "make.conf defaults set" && echo  ""  
  sleep 5 # TODO REMOVE

  einfo "Setting up Mage"
  # Portage repo symlinks
  mkdir -p /var/mage/repos
  ln -s /usr/portage /var/mage/repos/gentoo
  ln -s /usr/local/portage /var/mage/repos/local
  ln -s /var/lib/layman /var/mage/repos/layman
  # Mount point for `mage tmerge`
  mkdir -p /tmp/portage
  edone "Mage is set up"
  sleep 5 # TODO REMOVE 
  
  # Needs be done here, otherwise python utils such as flaggie will fail to run because of UTF
  einfo "Setting the locale"
  echo -e "${BOOTSTRAP_LOCALE_GEN}" >> /etc/locale.gen
  locale-gen
  eselect locale set "en_US.utf8" # this will fail if the locale isnt in /etc/locale.gen, test it!
  env-update && source /etc/profile
  edone "Locale set"  
  
  einfo "Emerging baseline packages, resyncing the live tree"
  emerge app-portage/cpuinfo2cpuflags app-portage/flaggie app-portage/eix || eexit "Emerge failed"
  eix-sync || eexit "Failed syncing the portage tree. Connection down?"
  edone "Baseline packages emerged, live tree resynced."
  sleep 5 # TODO REMOVE
  
  einfo "Finalizing portage and make.conf configuration ..."
  mkdir -p /etc/portage/{package.mask,package.unmask,sets,repos.conf,package.accept_keywords,package.use,env,package}
  cpuinfo2cpuflags-x86 >> /etc/portage/make.conf
  echo "sys-kernel/dracut" >> /etc/portage/package.accept_keywords/mage-sys-core
  echo "sys-kernel/dracut device-mapper btrfs ssh-client systemd" >> /etc/portage/package.use/mage-sys-core 

  flaggie +systemd +vaapi +vdpau
  # If BOOTSTRAP_MAKECONF* parameters from /etc/mage/bootstrap.conf are set, set make.conf accordingly
  [[ ! -z ${BOOTSTRAP_MAKECONF_LINGUAS} ]] && echo "LINGUAS=\"${BOOTSTRAP_MAKECONF_LINGUAS}\"" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_ACCEPT_LICENSE} ]] && echo "ACCEPT_LICENSE=\"${BOOTSTRAP_MAKECONF_ACCEPT_LICENSE}\"" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_INPUT_DEVICES} ]] && echo "INPUT_DEVICES=\"${BOOTSTRAP_MAKECONF_INPUT_DEVICES}\"" >> /etc/portage/make.conf
  [[ ! -z ${BOOTSTRAP_MAKECONF_VIDEO_CARDS} ]] && echo "VIDEO_CARDS=\"${BOOTSTRAP_MAKECONF_VIDEO_CARDS}\"" >> /etc/portage/make.conf
  edone "Portage and make.conf configuration now set to good defaults"
  sleep 5 # TODO REMOVE
  
  einfo "Setting up systemd"
  emerge -uDN sys-apps/systemd || eexit "Emerge failed"
  firstboot localectl set-locale ${BOOTSTRAP_LOCALE_SET}
  firstboot timedatectl set-timezone ${BOOTSTRAP_TIMEZONE}
  edone "Systemd ready"  
  sleep 5 # TODO REMOVE
 
  einfo "Enabling bootstrap profiles"
  for PROFILE in ${BOOTSTRAP_PROFILES} ; do
  if [ `echo "${PROFILE}" | grep "system/"` ] ; then
      `echo "${SCRIPT} profile enable ${PROFILE}"` || eexit "Enabling profile ${PROFILE} failed"
    fi
    # TODO counter to see how many system profiles have been enabled
  done
  for PROFILE in ${BOOTSTRAP_PROFILES} ; do
  if [ `echo "${PROFILE}" | grep "hardware/"` ] ; then
      `echo "${SCRIPT} profile enable ${PROFILE}"` || eexit "Enabling profile ${PROFILE} failed"
    fi
    # TODO counter to see how many hardware profiles have been enabled
  done
  for PROFILE in ${BOOTSTRAP_PROFILES} ; do
  if [ `echo "${PROFILE}" | grep "app/"` ] ; then
      `echo "${SCRIPT} profile enable ${PROFILE}"` || eexit "Enabling profile ${PROFILE} failed"
    fi
  done
  edone "All profiles enabled"
  sleep 5 # TODO REMOVE
}

# configure kernel, write /etc/fstab, reboot & enjoy
env_kernel() {
  # https://bpaste.net/raw/506ec064e8ef kernel
  pushd /usr/src/linux
  ${SCRIPT} linuxconfig /usr/src/linux/.config /etc/mage/linuxconfig/* problems
  einfo "Press enter to continue ..."
  read
  make nconfig
  ${SCRIPT} linuxconfig /usr/src/linux/.config /etc/mage/linuxconfig/* problems
    
  read -r -p "Happy now with your config? [y/n]: " response
  case $response in
      [yY]) 
          ${SCRIPT} kernel make
          ${SCRIPT} kernel install nomountcheck
      ;;
      *)
          eexit "Dang! In that case, re-run mage bootstrap env-kernel"
      ;;
  esac
}  
  
  


env_user() {
  einfo "Setting up the system user (root) ..."
  # Figure out which of the following groups exist on the system already
  grps=( users wheel video plugdev portage games usb lp lpadmin scanner floppy cdrom )
  grpadd=""
  [[ -f /etc/group ]]
  for i in "${grps[@]}"
  do
      [[ `cat /etc/group | grep "${i}:"` ]] && grpadd="${grpadd}${i},"
  done
  [[ ${grpadd} = "" ]] || grpadd=${grpadd::-1}
  echo "${grpadd}"
  ewarn "Please enter the username:"
  read username
  useradd -m -G ${grpadd} -s /bin/bash ${username} 
  ewarn "Please enter the password:"  
  passwd ${username}
  ewarn "Enter root password:"
  passwd
}

env_bootloader() {
    # Flush the page cache to ensure GRUB2 sees the latest disk content
    echo 1 > /proc/sys/vm/drop_caches
    . "${LIBDIR}/bootstrap/disks.sh" || eexit "Can't load ${LIBDIR}/bootstrap/disks.sh"
    einfo "Available devices:"
    echo ""
    ls -l /dev | grep -E ' (sd|hd|md)..?$'
    echo ""
    ewarn "Now a teaser, you gotta remember what disk layout you installed (probably the default marked with *):"
    select_file "${LIBDIR}/bootstrap/disks" ${BOOTSTRAP_PART_SCHEME} "choice"
    . "${LIBDIR}/bootstrap/disks/${choice}" || eexit "Can't load ${LIBDIR}/bootstrap/disks/${choice}"

cat  > /etc/dracut.conf.d/local.conf << ENDER
hostonly="yes"
add_dracutmodules+="bash btrfs systemd systemd-initrd dracut-systemd usrmount rescue base"
compress="xz"
ENDER

   dracut --hostonly --force '' $(readlink -f /usr/src/linux | sed -e 's!.*linux-!!')   
    
    # GRUB_PARAMS should set here everything userspace related
    # everything partition/disk scheme related is appended by the disks_bootloader function
    GRUB_PARAMS="real_init=/usr/lib/systemd/systemd init=/usr/lib/systemd/systemd" 
    disks_do_bootloader "${GRUB_PARAMS}"
}

disks_btrfsraid1_finish() {
# real_init= is used with initramfs, init= without initramfs
echo "GRUB_CMDLINE_LINUX=\"rootfstype=btrfs real_init=/usr/lib/systemd/systemd init=/usr/lib/systemd/systemd rootflags=device=/dev/${1}4,subvol=@\"" >> /etc/default/grub
echo 'filesystems+="btrfs ext2 ext4"' >> /etc/dracut.conf # http://nlug.ml1.co.uk/2013/08/gentoo-dracut-btrfs-quirk/4293  # TODO NAHRADIT /etc/dracut.conf.d
#ismounted /boot || eexit  "boot not mounted" 
dracut --hostonly 

grub2-install "/dev/${1}"
#grub2-install "/dev/${2}" # applies only on raid1 setup
grub2-mkconfig -o /boot/grub/grub.cfg
echo "
# <fs>              <mountpoint>    <type>      <opts>                                                                         <dump/pass>
LABEL="boot"        /boot           ext2        noauto,noatime                                                                 1 2
LABEL="@"           /               brtfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@                  0 0
LABEL="root"        /root           brtfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=root               0 0
LABEL="home"        /home           brtfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=home               0 0
LABEL="tmp"         /tmp            brtfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=tmp                0 0
LABEL="varlog"      /var/log        brtfs       defaults,space_cache,noatime,nodatacow,compress=lzo,autodefrag,subvol=varlog   0 0
LABEL="varspool"    /var/spool      brtfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=varspool           0 0
LABEL="swap"        none            swap        sw                                                                             0 0
" >> /etc/fstab
}


#env_bootloader() {
#mkdir -p /etc/dracut.conf.d
#echo ' 
#filesystems+="btrfs ext2 ext4"
##hostonly="yes"
#add_dracutmodules+="btrfs systemd systemd-initrd busybox dracut-systemd kernel-modules base dm dmraid biosdevname fs-lib uefi-lib bash"' >> /etc/dracut.conf.d/mage.conf
#dracut -f '' $(readlink -f /usr/src/linux | sed -e 's!.*linux-!!') 
#. "${LIBDIR}/bootstrap/disks/single.extboot+btrfsroot.sh" || eexit "Can't load ${LIBDIR}/bootstrap/disks/single.extboot+btrfsroot.sh"
#disks_bootloader
## todo ulozit a nacist device
#}
  
# configure kernel, write /etc/fstab, reboot & enjoy
env_bootloader_unfinished() {

# gnome na extu
echo 'GRUB_CMDLINE_LINUX="rootfstype=ext4 real_init=/usr/lib/systemd/systemd"' >> /etc/default/grub
grub2-install /dev/sda
grub2-mkconfig -o /boot/grub/grub.cfg

# btrfs na 2 discich s dracutem
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
LABEL="root"        /               brtfs       defaults,noatime,compress=lzo,autodefrag,subvol=@       0 0
LABEL="root"        /home           brtfs       defaults,noatime,compress=lzo,autodefrag,subvol=home    0 0
LABEL="swap"        none            swap        sw                                                      0 0
" >> /etc/fstab

  echo "
/dev/sda3   none         swap    sw                                      0 0
/dev/sda2   /            ext4    defaults,noatime,nodiratime,discard     0 1
/dev/sda4   /boot	 ext4    defaults,noatime,nodiratime,discard	 0 2
" >> /etc/fstab
}


env_firstboot() {
 einfo "Finalizing ..."
 chmod +x /var/mage/firstboot
 /var/mage/firstboot # todo bin/bash na zacatek souboru
 # TODO dodelat totot
}