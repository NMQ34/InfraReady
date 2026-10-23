# InfraReady — Infrastructure Windows / Linux automatisée et supervisée

## Présentation

InfraReady est un projet de déploiement, d'administration et de supervision d'une infrastructure informatique hybride Windows Server / Linux, réalisé dans le cadre d'un Bachelor 3 Cybersécurité et Informatique.

L'objectif est de mettre en œuvre une infrastructure fonctionnelle, documentée et partiellement automatisée, intégrant Active Directory, DNS, Ansible, la maintenance système, la supervision et une chaîne d'intégration continue.

## Architecture

L'environnement repose sur deux machines virtuelles VMware Workstation Pro.

| Machine | Système | Adresse IP (réseau laboratoire) | Rôle |
|---|---|---|---|
| WIN-DC01 | Windows Server 2025 | 192.168.50.10 | Active Directory, DNS, services Windows |
| LINUX01 | Ubuntu Server 26.04 LTS | 192.168.50.20 | Services Linux, Ansible, Prometheus, Grafana |

Deux réseaux virtuels sont utilisés :

- **VMnet2 — 192.168.50.0/24 :** réseau de laboratoire permettant la communication entre les machines.
- **VMnet8 — NAT :** accès Internet de LINUX01 pour les mises à jour et les outils nécessaires.

Le domaine Active Directory est `infraready.test`.

Les détails techniques et les choix d'architecture sont présentés dans [la documentation d'architecture](docs/architecture.md).

## Fonctionnalités réalisées

### Administration Windows

- Déploiement de Windows Server 2025.
- Configuration d'Active Directory Domain Services (AD DS) et du DNS.
- Gestion des comptes, groupes et permissions.
- Configuration des services nécessaires à l'administration distante.
- Vérification et documentation de la stratégie de mise à jour.

### Administration Linux

- Installation et configuration d'Ubuntu Server.
- Gestion des utilisateurs, groupes et permissions.
- Configuration réseau et résolution DNS.
- Gestion du stockage et des montages persistants.
- Déploiement et vérification du service Nginx.
- Configuration des mises à jour automatiques et des contrôles de maintenance.

### Automatisation

Des playbooks Ansible permettent d'automatiser et de vérifier une partie de la configuration des machines Linux et Windows.

Les playbooks ont été testés pour vérifier leur idempotence.

### Supervision

La supervision repose sur :

- **Prometheus :** collecte et interrogation des métriques.
- **Node Exporter :** métriques Linux.
- **Windows Exporter :** métriques Windows.
- **Grafana :** visualisation et alertes.

Un point de contact e-mail InfraReady - Email Alerts, associé à l'adresse fictive admin@infraready.test, est configuré pour illustrer les notifications. Aucun envoi réel n'a été validé, faute de serveur SMTP fonctionnel.

Le tableau de bord couvre notamment la disponibilité des cibles et les indicateurs CPU, mémoire et stockage.

Une règle Grafana détecte les cibles dont la métrique Prometheus `up` reste inférieure à `1` pendant la période configurée.

### Simulation d'incident

Un incident contrôlé a été réalisé en arrêtant temporairement le service `windows_exporter` sur WIN-DC01.

La supervision a détecté l'indisponibilité (`up = 0`), Grafana a déclenché une alerte `Firing`, puis les deux outils ont confirmé le rétablissement après redémarrage du service.

Le scénario, les commandes et les preuves sont disponibles dans le [rapport d'incident](docs/incident-report.md).

## Organisation du dépôt

```text
InfraReady/
├── .github/
│   └── workflows/
│       └── ansible-ci.yml
├── dashboards/
│   └── infraready-dashboard.json
├── docs/
│   ├── architecture.md
│   ├── incident-report.md
│   └── maintenance.md
├── evidence/
│   ├── grafana-alert-history.png
│   ├── grafana-incident-firing.png
│   └── grafana-incident-recovered.png
├── inventory/
│   ├── group_vars/
│   │   └── windows
│   └── hosts.yml
├── monitoring/
│   ├── grafana-alerts.yml
│   └── prometheus.yml
├── playbooks/
│   ├── linux.yml
│   └── windows.yml
├── scripts/
│   ├── check-nginx.sh
│   └── maintenance-linux.sh
└── README.md
```

## Documentation et ressources

| Ressource | Description |
|---|---|
| [Architecture](docs/architecture.md) | Machines, réseau, DNS, services et choix techniques |
| [Maintenance](docs/maintenance.md) | Mises à jour, contrôles périodiques et limites |
| [Rapport d'incident](docs/incident-report.md) | Simulation de panne, diagnostic et résolution |
| [Playbook Linux](playbooks/linux.yml) | Automatisation et vérifications Linux |
| [Playbook Windows](playbooks/windows.yml) | Automatisation et vérifications Windows |
| [Inventaire Ansible](inventory/hosts.yml) | Déclaration des machines |
| [Configuration Prometheus](monitoring/prometheus.yml) | Cibles de collecte |
| [Règle Grafana](monitoring/grafana-alerts.yml) | Définition de l'alerte |
| [Tableau de bord Grafana](dashboards/infraready-dashboard.json) | Export du dashboard |
| [Maintenance Linux](scripts/maintenance-linux.sh) | Contrôles de maintenance |
| [Workflow CI](.github/workflows/ansible-ci.yml) | Vérifications automatisées |

## Intégration continue

Un workflow GitHub Actions exécute des vérifications Ansible pour détecter certaines erreurs avant l'intégration des modifications.

Les vérifications CI ne remplacent pas les tests d'exécution réalisés sur les machines virtuelles.

## Limites de l'environnement

- L'infrastructure est un laboratoire pédagogique et non un environnement de production.
- Les rôles Linux et supervision sont regroupés sur une seule VM pour limiter la consommation de ressources.
- WIN-DC01 ne dispose pas d'un accès Internet direct ; les limites associées aux mises à jour Windows sont documentées.
- Un destinataire fictif est associé à l'alerte Grafana, mais la livraison des notifications nécessite un serveur SMTP fonctionnel.
- Les configurations exportées peuvent nécessiter une adaptation à un nouvel environnement, notamment les adresses IP et les identifiants de sources de données Grafana.

## Conclusion

InfraReady rassemble les principales étapes d'administration d'une infrastructure Windows / Linux : déploiement, configuration réseau, gestion des identités, automatisation, maintenance, supervision et traitement d'incident.

Le dépôt conserve les configurations, les scripts et les preuves permettant de présenter et d'expliquer les travaux réalisés.
