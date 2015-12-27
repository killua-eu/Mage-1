#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
echo "" && eselect profile show echo ""