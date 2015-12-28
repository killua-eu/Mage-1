#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
echo "" && eselect profile show echo ""

einfo "Emerging package sets"
${SCRIPT} tmerge @mage-desktop-gnome

einfo "Enabling and starting services"
systemctl enable gdm.service
systemctl enable NetworkManager 
systemctl daemon-reload
systemctl start avahi-daemon.service
systemctl start avahi-dnsconfd.service
systemctl start cups.service
systemctl start cups-browsed.service
systemctl enable avahi-daemon.service
systemctl enable avahi-dnsconfd.service
systemctl enable cups-browsed.service
systemctl enable cups.service
