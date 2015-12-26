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

Use with caution, while we'll try to help, consider the scripts easy enough to come without any support.

