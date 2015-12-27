#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/systemd"
echo "" && eselect profile show echo ""