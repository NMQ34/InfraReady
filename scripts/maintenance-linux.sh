#!/usr/bin/env bash
set -u

echo "=== Maintenance InfraReady — $(date) ==="

echo
echo "=== Mises à jour disponibles ==="
apt list --upgradable 2>/dev/null

echo
echo "=== Utilisation des disques ==="
df -h / /mnt/infraready-data

echo
echo "=== Services en échec ==="
systemctl --failed --no-pager

echo
echo "=== État de Nginx ==="
systemctl is-active nginx
systemctl is-enabled nginx

echo
echo "=== Redémarrage nécessaire ==="
if [[ -f /var/run/reboot-required ]]; then
    echo "Oui"
else
    echo "Non"
fi
