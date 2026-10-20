#!/bin/bash

# Vérifie si le service Nginx est actif.
# Code retour : 0 si actif, 1 sinon.

if systemctl is-active --quiet nginx; then
    echo "OK : Nginx est actif."
    exit 0
else
    echo "ERREUR : Nginx est arrêté ou inactif."
    exit 1
fi
