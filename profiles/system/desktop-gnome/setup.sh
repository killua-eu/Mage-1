#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
echo "" && eselect profile show echo ""

einfo "Emerging package sets"
${SCRIPT} -uDN @mage-desktop-gnome
#cat /var/lib/portage/world_sets | grep "@mage-desktop-gnome" || echo "@mage-desktop-gnome" >> /var/lib/portage/world_sets

[[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]
firstboot einfo "Enabling and starting services"
firstboot systemctl enable gdm.service
firstboot systemctl enable NetworkManager 
firstboot systemctl daemon-reload
firstboot systemctl start avahi-daemon.service
firstboot systemctl start avahi-dnsconfd.service
firstboot systemctl start cups.service
firstboot systemctl start cups-browsed.service
firstboot systemctl enable avahi-daemon.service
firstboot systemctl enable avahi-dnsconfd.service
firstboot systemctl enable cups-browsed.service
firstboot systemctl enable cups.service
