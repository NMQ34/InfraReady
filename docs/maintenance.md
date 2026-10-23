# InfraReady — Procédure de maintenance

## 1. Objectif

Cette procédure décrit les opérations de maintenance des serveurs Linux et Windows du laboratoire InfraReady.

Elle vise à assurer la disponibilité des services, contrôler les mises à jour, surveiller l'espace disque et conserver des traces des vérifications.

## 2. Environnement

| Serveur | Système | Rôle |
|---|---|---|
| LINUX01 | Ubuntu Server 26.04 LTS | Nginx, Ansible, Prometheus, Grafana |
| WIN-DC01 | Windows Server 2025 | Active Directory, DNS, partages |

Les deux machines communiquent sur le réseau de laboratoire `192.168.50.0/24`.

## 3. Maintenance Linux

### 3.1 Mises à jour automatiques

Le paquet `unattended-upgrades` est installé et configuré pour installer automatiquement les mises à jour provenant des dépôts Ubuntu autorisés, notamment les mises à jour de sécurité.

La configuration `/etc/apt/apt.conf.d/20auto-upgrades` contient :

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

Les mises à jour sont gérées par les mécanismes APT et les timers systemd.

Le fichier `/etc/apt/apt.conf.d/99infraready-upgrades` contient :

```text
Unattended-Upgrade::Automatic-Reboot "false";
```

Les redémarrages automatiques sont donc désactivés.

**Vérifications réalisées :**
- Paquet `unattended-upgrades` installé.
- Timer `apt-daily-upgrade.timer` actif et activé.
- Configuration des dépôts autorisés vérifiée.
- Test à blanc réussi avec `sudo unattended-upgrade --dry-run --debug`.
- Aucune mise à jour éligible détectée lors de la simulation.

La simulation ne constitue pas une preuve d'installation automatique effective.

### 3.2 Contrôle quotidien

Le script `scripts/maintenance-linux.sh` effectue les contrôles suivants :

- Liste des mises à jour disponibles.
- Utilisation des partitions.
- Recherche des services systemd en échec.
- État et activation au démarrage de Nginx.
- Présence d'une demande de redémarrage.

Il est planifié dans `/etc/cron.d/infraready-maintenance` :

```text
0 8 * * * root /home/theo/InfraReady/scripts/maintenance-linux.sh >> /var/log/infraready-maintenance.log 2>&1
```

La tâche s'exécute théoriquement chaque jour à 08:00, selon le fuseau horaire de la VM.

Le journal peut être consulté avec :

```bash
sudo tail -n 30 /var/log/infraready-maintenance.log
```

**Vérifications réalisées :**
- Script exécuté avec succès manuellement.
- Permissions du fichier Cron : `root:root`, mode `644`.
- Service Cron opérationnel.
- Aucune erreur Cron détectée dans les journaux consultés.

**Limite :** aucune exécution automatique de cette tâche n'a encore été confirmée dans les journaux.

### 3.3 État du stockage et des services

Lors du contrôle réalisé le 22 octobre 2026 :

| Élément | Résultat |
|---|---|
| Partition racine `/` | 36 % utilisés |
| Volume `/mnt/infraready-data` | 1 % utilisé |
| Services systemd en échec | 0 |
| Nginx | Actif et activé |
| Redémarrage nécessaire | Non |

Ces résultats représentent un état ponctuel et non une garantie permanente.

## 4. Maintenance Windows

### 4.1 Procédure de mise à jour
Sur `WIN-DC01`, la procédure de maintenance prévoit :

1. Vérifier l'état d'Active Directory et de DNS.
2. Contrôler les journaux Windows.
3. Vérifier l'espace disque disponible.
4. Créer un snapshot VMware avant toute modification importante.
5. Rechercher les mises à jour via Windows Update.
6. Installer les mises à jour disponibles si les prérequis sont satisfaits.
7. Effectuer un redémarrage contrôlé si nécessaire.
8. Vérifier à nouveau les services et la résolution DNS.

### 4.2 Résultat du test et justification de l'architecture

Une recherche de mises à jour a été effectuée sur `WIN-DC01`. Elle a échoué avec le code `0x8024402C`.

Le serveur Windows est connecté uniquement au réseau interne du laboratoire (`192.168.50.0/24`). Contrairement à `LINUX01`, il ne dispose pas d'interface NAT lui permettant d'accéder à Internet.

**Choix d'architecture :**

Cette configuration permet de limiter la connectivité externe du contrôleur de domaine, qui héberge des services critiques tels qu'Active Directory et DNS.

L'objectif est de conserver un environnement de laboratoire isolé et de réduire les communications réseau non nécessaires.

**Limite identifiée :**

Cette isolation empêche actuellement le serveur de contacter directement les services Windows Update. Aucune mise à jour Windows n'a donc été installée lors du test.

L'absence de connectivité Internet ne constitue pas à elle seule une garantie de sécurité : les correctifs restent indispensables pour protéger le système contre les vulnérabilités connues.

**Amélioration envisageable en environnement professionnel :**

Une architecture de production devrait prévoir un mécanisme de mise à jour sécurisé, par exemple :

- Une sortie Internet contrôlée par un pare-feu, limitée aux services nécessaires.
- Une solution centralisée de distribution des mises à jour, comme WSUS, si adaptée à l'infrastructure.
- Une procédure de maintenance planifiée, avec validation des correctifs et contrôle des services après installation.

**Conclusion :**

L'isolation de `WIN-DC01` est un choix adapté aux objectifs et aux contraintes de ce laboratoire. Elle implique cependant une limitation de maintenance clairement identifiée. Une solution de distribution des mises à jour serait nécessaire pour une exploitation durable en production.

## 5. Précautions avant maintenance

Avant toute modification importante :

- Vérifier la machine ciblée.
- Contrôler l'espace disque disponible.
- Vérifier l'état des services critiques.
- Créer un snapshot VMware lorsque cela est approprié.
- Prévoir une possibilité de retour arrière.
- Éviter les redémarrages non planifiés.
- Ne jamais publier de secrets dans les journaux ou le dépôt GitHub.

## 6. Vérifications après maintenance

Après une opération de maintenance :

**Sur Linux :**

```bash
systemctl --failed
systemctl is-active nginx
df -h
```

**Sur Windows :**

Vérifier les services Active Directory, DNS et WinRM, ainsi que la résolution DNS et les journaux d'événements.

Les anomalies doivent être consignées avec leurs symptômes, les tests réalisés, les corrections appliquées et le résultat final.

## 7. Limites connues

- Les mises à jour Linux automatiques sont configurées et validées par simulation, mais aucune installation automatique réelle n'a encore été démontrée.
- Le déclenchement automatique du script Cron reste à confirmer.
- Les mises à jour Windows sont limitées par l'absence d'accès Internet de `WIN-DC01`.
- Les rôles d'administration et de supervision sont regroupés sur LINUX01 en raison des ressources disponibles.

Ces limites sont conservées dans la documentation pour distinguer les fonctionnalités validées des opérations restant à démontrer.
