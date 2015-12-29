# Mage

Mage is a set of scripts, recipes and configuration files to make our lives easier to manage Gentoo linux boxes. Mage is

* a toolset comprising of
  * tmerge (emerge on tmpfs)
  * overlay manager (an overlay creation helper)
  * linuxconfig (a tool checking the current linux configuration against required config options)
  * kernel updater
  * is a CLI Gentoo Linux installer
* a collection of "profiles" which are basically a collection of
  * package sets, use flags and accept keyword flags
  * an installation recipe (just a shell script)
  * a linuxconfig (see above) requirements file

Beware that Mage is an ugly hack. The profiles should be eventually rewritten to something more robust such as Ansible, so for now, you can consider them a proof of concept.
The tools are usable on some (i.e. reasonably powerful) systems and to some (i.e. reasonably lazy) users. They are intentionally separated for easy hacking, forking and any other abuse.

Mage will expect following paths:

- /etc/mage for configuration
- /usr/bin for the mage script
- /usr/lib/mage for the mage included scripts
- /var/mage/profiles.all for all available profiles
- /var/mage/profiles.active for active profiles

**BOOTSTRAPPING**

To bootstrap a new Gentoo box, get yourself a bootable thumbdrive with any live linux distro.
To flash a thumbdrive with a Gentoo minimal ISO use as root:

~~~
mkdir gentooiso
pushd gentooiso
wget iso.url.iso
isohybrid *.iso
dd if=/path/to/image.iso of=/dev/sdc bs=8192k # /dev/sdc assumes your thumbdrive, if its your disk, you will delete your data
~~~

After booting into the livecd, while being root do 
wget https://github.com/Vaizard/Mage/archive/master.zip && unzip *.zip && cd M*
./mage help bootstrap

**WARNING**

Mage is currently designed (by a line of code here andthere) to rely on systemd. The reasons are following:

- We prefer a Gnome desktop
- We're interested in exploring systemd+virtualization integration possibilities (i.e. CoreOS, etc.)
- We want to help change Gentoo+Systemd to an alternative as good as Gentoo+OpenRC

Use with caution, while we'll try to help, consider the scripts easy enough to come without any support.

