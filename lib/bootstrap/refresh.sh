#!/usr/bin/env bash

# Prepare the chroot environment(download and extract stage3 to /mnt/gentoo, tweak /etc/portage files
refresh() {
  einfo "Refreshing mage to git bleeding edge ..."
  ewarn "Refresh is *only* a helper for devs/testers to be used *exclusively* when bootstrapping."
  ewarn "Do you really want to continue? [y/n]" && read choice

    case "$choice" in
        y)
        edone "Hope you know what you do"
        ;;
        *)
        eexit "Exitting"
        ;;
        *)
        read choice
        ;;    
    esac    

  pushd ${BINDIR}
  cd ..
  echo "rm -f ./master.zip"
  wget https://github.com/Vaizard/Mage/archive/master.zip || eexit "Failed to get latest master.zip"
  rm -rf ${BINDIR}
  sleep 5
  rm -rf ${BINDIR}
  unzip master.zip
  cd Mage-master
  edone "Mage successfully refreshed"
}
