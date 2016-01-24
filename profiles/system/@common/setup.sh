#!/usr/bin/env bash
einfo "Emerging package sets"
${SCRIPT} tmerge -uDN @mage-adm-tools @mage-sys-core @mage-sys-fs @mage-sys-net @mage-sys-portage
#cat /var/lib/portage/world_sets | grep "@mage-adm-tools" || echo "@mage-adm-tools" >> /var/lib/portage/world_sets
#cat /var/lib/portage/world_sets | grep "@mage-sys-core" || echo "@mage-sys-core" >> /var/lib/portage/world_sets
#cat /var/lib/portage/world_sets | grep "@mage-sys-fs" || echo "@mage-sys-fs" >> /var/lib/portage/world_sets
#cat /var/lib/portage/world_sets | grep "@mage-sys-portage" || echo "@mage-sys-portage" >> /var/lib/portage/world_sets