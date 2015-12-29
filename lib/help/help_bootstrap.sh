#!/usr/bin/env bash

help_bootstrap() {
cat << HELP_END
${BAD}mage bootstrap${NORMAL} is a semi-interactive Gentoo installer. Every 
Gentoo installation proceeds in basically same stages:

${BOLD} 1. Setting up the installation environment.${NORMAL} This means:
      * Booting to Linux (Any Linux LiveCD will do, typical choices include
        the Gentoo minimal ISO or a Ubuntu LiveCD)
      * Get internet connectivity
      * [optional] Perform a remote install over SSH (Start sshd and create
        a temporary user to login into the SSH session)
${BOLD} 2. Setting up disks${NORMAL}, which includes:
      * Partitioning
      * Creating filesystems & mounting them unter /mnt/gentoo
${BOLD} 3. Downloading and extracting a stage3 tarball${NORMAL} which is an archive with
    bare bones Gentoo binaries.
${BOLD} 4. Chrooting into this stage3 environment${NORMAL}
${BOLD} 5. Configuring, making and installing the Linux kernel and bootloader${NORMAL}
${BOLD} 6. Adapting the stage3 environment${NORMAL}
      * installing and configuring aditional packages
      * setting up locales
      *  creating first user and setting root pw
${BOLD} 7. Rebooting into Gentoo${NORMAL}

Got it? Continue or get help with:

 * ${HILITE}mage bootstrap net${NORMAL}
   - ${HILITE}mage bootstrap net test${NORMAL}
   - ${HILITE}mage bootstrap net sshd${NORMAL}
 * ${HILITE}mage bootstrap disks${NORMAL}
   - ${HILITE}mage bootstrap disks setup${NORMAL}
   - ${HILITE}mage bootstrap disks remount${NORMAL}
 * ${HILITE}mage bootstrap env${NORMAL}
   - ${HILITE}mage bootstrap env prepare${NORMAL}
   - ${HILITE}mage bootstrap env chroot${NORMAL}
   - ${HILITE}(mage bootstrap env chroot-reenter)${NORMAL} use this only if you reboot during the env phases
   - ${HILITE}mage bootstrap env install${NORMAL}
   - ${HILITE}mage bootstrap env kernel${NORMAL}
   - ${HILITE}mage bootstrap env user${NORMAL}
   - ${HILITE}mage bootstrap env bootloader${NORMAL}
 
HELP_END
exit ${1:-1}
}

