#!/usr/bin/env bash
set -euo pipefail

systemctl disable --now suspend-wifi-unload.service resume-wifi-reload.service || true

sudo rm -f /etc/systemd/system/suspend-wifi-unload.service
sudo rm -f /etc/systemd/system/resume-wifi-reload.service

sudo rm -f /etc/systemd/system/sleep.target.wants/suspend-wifi-unload.service
sudo rm -f /etc/systemd/system/suspend.target.wants/resume-wifi-reload.service
sudo rm -f /etc/systemd/system/hibernate.target.wants/resume-wifi-reload.service
sudo rm -f /etc/systemd/system/hybrid-sleep.target.wants/resume-wifi-reload.service
sudo rm -f /etc/systemd/system/suspend-then-hibernate.target.wants/resume-wifi-reload.service

systemctl daemon-reload
systemctl reset-failed || true

echo "--- remaining matches in /etc/systemd/system ---"
find /etc/systemd/system -maxdepth 3 \( -type f -o -type l \) | rg 'suspend-wifi-unload|resume-wifi-reload' || true
