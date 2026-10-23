# InfraReady — Architecture technique

## 1. Présentation

InfraReady est un laboratoire d'administration système et réseau construit avec VMware Workstation Pro.

L'infrastructure comprend deux machines virtuelles :

- **WIN-DC01** : contrôleur de domaine Active Directory, serveur DNS et serveur de fichiers.
- **LINUX01** : serveur Linux assurant l'administration automatisée, l'hébergement web et la supervision.

Les fonctions initialement prévues sur un serveur d'exploitation distinct sont regroupées sur LINUX01 afin de limiter la consommation de ressources matérielles.

## 2. Machines virtuelles

| Caractéristique | WIN-DC01 | LINUX01 |
|---|---|---|
| Système | Windows Server 2025 Standard | Ubuntu Server 26.04 LTS |
| Nom d'hôte | WIN-DC01 | linux01 |
| Domaine | infraready.test | Résolution DNS du domaine |
| IP interne | 192.168.50.10/24 | 192.168.50.20/24 |
| Accès Internet direct | Non | Oui, via NAT |
| Rôles principaux | AD DS, DNS, fichiers | Nginx, Ansible, Prometheus, Grafana |

LINUX01 n'est pas membre du domaine Active Directory. Il utilise toutefois le DNS Windows pour résoudre les noms du domaine.

## 3. Architecture réseau

### 3.1 Réseau interne — vmnet2

Le réseau `192.168.50.0/24` permet aux deux machines de communiquer.

| Machine | Interface | Adresse |
|---|---|---|
| WIN-DC01 | Réseau interne VMware | 192.168.50.10 |
| LINUX01 | ens33 | 192.168.50.20 |

Aucune passerelle par défaut n'est configurée sur l'interface interne de LINUX01.

### 3.2 Réseau NAT — vmnet8

LINUX01 possède une deuxième interface réseau, `ens37`, configurée en DHCP.

Lors de la vérification du 23 octobre 2026 :

- Adresse IPv4 : `192.168.47.143/24`.
- Passerelle par défaut : `192.168.47.2`.
- DNS fourni par VMware : `192.168.47.2`.

Cette interface permet l'accès aux dépôts Ubuntu, à GitHub et aux autres ressources externes nécessaires au laboratoire.

L'adresse NAT étant attribuée par DHCP, elle peut évoluer.

WIN-DC01 ne possède pas d'interface NAT.

## 4. Résolution DNS

### 4.1 DNS interne

WIN-DC01 héberge le service DNS du domaine Active Directory `infraready.test`.

Le serveur DNS est accessible à l'adresse `192.168.50.10`.

Une interrogation directe a confirmé que le domaine `infraready.test` se résout vers `192.168.50.10`.

### 4.2 DNS conditionnel sur Linux

LINUX01 utilise une configuration Netplan avec `systemd-resolved`.

Sur `ens33` :

- Serveur DNS : `192.168.50.10`.
- Domaine de routage : `~infraready.test`.

Sur `ens37` :

- Serveur DNS : `192.168.47.2`.
- Résolution des autres domaines.

Cette configuration permet de séparer la résolution des noms internes et externes.

### 4.3 Tests de validation

Les commandes suivantes ont été exécutées :

```bash
resolvectl query infraready.test
resolvectl query github.com
```

Résultats du 23 octobre 2026 :

| Domaine | Adresse retournée | Interface |
|---|---|---|
| infraready.test | 192.168.50.10 | ens33 |
| github.com | 20.250.119.67 | ens37 |

Les deux tests ont réussi.

## 5. Services déployés

### 5.1 Windows Server

WIN-DC01 héberge :

- Active Directory Domain Services.
- Le service DNS.
- Des comptes et groupes d'utilisateurs.
- Des partages de fichiers avec permissions.
- WinRM pour l'administration distante avec Ansible.

### 5.2 Ubuntu Server

LINUX01 héberge :

- Nginx, serveur web de test.
- Ansible, pour l'automatisation Linux et Windows.
- Prometheus, pour la collecte des métriques.
- Grafana, pour les tableaux de bord et les alertes.
- Node Exporter, pour les métriques Linux.
- Les scripts de maintenance.

Un volume supplémentaire est monté sur `/mnt/infraready-data`.

## 6. Supervision

Prometheus collecte les métriques des cibles suivantes :

| Cible | Adresse | Fonction |
|---|---|---|
| Prometheus | localhost:9090 | Supervision du collecteur |
| Node Exporter | localhost:9100 | Métriques Linux |
| Windows Exporter | 192.168.50.10:9182 | Métriques Windows |

Grafana est accessible sur LINUX01 au port `3000`.

Le tableau de bord InfraReady présente notamment la disponibilité des machines, l'utilisation CPU, la mémoire et l'espace disque.

Une alerte Grafana de disponibilité a été testée en interrompant temporairement Windows Exporter, puis en le redémarrant.

## 7. Choix de sécurité et limites

### 7.1 Isolation du contrôleur de domaine

WIN-DC01 est volontairement limité au réseau interne du laboratoire.

Cette architecture réduit les communications externes du contrôleur de domaine, mais empêche les mises à jour Windows directement depuis Internet.

Dans un environnement professionnel, une solution de mise à jour avec accès sortant contrôlé ou distribution centralisée des correctifs serait nécessaire.

### 7.2 Regroupement des rôles sur Linux

Les ressources matérielles disponibles ne permettent pas de maintenir confortablement trois machines virtuelles.

Les rôles d'administration, de supervision et de serveur Linux ont donc été regroupés sur LINUX01.

Cette solution répond aux contraintes du laboratoire, mais introduit une dépendance : l'indisponibilité de LINUX01 affecterait plusieurs services simultanément.

### 7.3 Limites de l'architecture

- Absence de haute disponibilité.
- Pas de mécanisme centralisé de mise à jour Windows déployé.
- Concentration de plusieurs services sur LINUX01.
- Environnement de laboratoire, non dimensionné pour la production.

## 8. Validation

Les contrôles réalisés comprennent :

- Vérification des interfaces et routes Linux.
- Communication entre les machines du réseau interne.
- Résolution DNS interne et externe.
- Vérification des services Windows et Linux.
- Tests d'automatisation Ansible.
- Vérification des cibles Prometheus.
- Test d'une alerte Grafana.

Les résultats détaillés et les preuves seront présentés dans le dossier technique final.
