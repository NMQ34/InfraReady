# Rapport d'incident — Indisponibilité de Windows Exporter

## 1. Contexte

**Projet :** InfraReady
**Date du test :** 23 octobre 2026
**Machine concernée :** WIN-DC01 — 192.168.50.10
**Service concerné :** `windows_exporter`
**Supervision :** Prometheus et Grafana, hébergés sur LINUX01

Cet incident a été simulé volontairement afin de vérifier la capacité de l'infrastructure à détecter une indisponibilité, déclencher une alerte et confirmer le rétablissement du service.

## 2. Symptômes observés

Après l'arrêt du service `windows_exporter` :

- Le service Windows apparaît en état `Stopped`.
- Prometheus ne peut plus récupérer les métriques de la cible `192.168.50.10:9182`.
- La métrique `up{job="windows"}` passe de `1` à `0`.
- Grafana déclenche l'alerte `InfraReady - Machine indisponible`, qui passe à l'état `Firing`.

Les autres cibles Prometheus restent disponibles.

## 3. Diagnostic et cause

La cause est l'arrêt volontaire du service Windows Exporter sur WIN-DC01.

Commande utilisée :

```powershell
Stop-Service -Name windows_exporter
```

Vérification :

```powershell
Get-Service -Name windows_exporter
```

Résultat : `Stopped`.

Dans Prometheus :

```promql
up{instance="192.168.50.10:9182",job="windows"}
```

Résultat : `0`.

Cette observation permet d'identifier une interruption de la collecte des métriques Windows. Elle ne signifie pas que Windows Server, Active Directory ou DNS sont eux-mêmes indisponibles.

## 4. Détection et alerte

La règle Grafana `InfraReady - Machine indisponible` surveille la métrique Prometheus `up`.

Configuration observée :

- Condition : valeur inférieure à `1`.
- Intervalle d'évaluation : 1 minute.
- Période d'attente : 1 minute.

L'alerte est passée à l'état `Firing` pendant l'incident.

La configuration actuelle n'inclut pas de destinataire externe de notification. L'alerte est donc consultable dans Grafana, sans démonstration d'envoi d'un e-mail ou d'une autre notification.

## 5. Résolution

Le service a été redémarré sur WIN-DC01 :

```powershell
Start-Service -Name windows_exporter
```

Son état a été vérifié :

```powershell
Get-Service -Name windows_exporter
```

Résultat : `Running`.

Une nouvelle interrogation Prometheus a confirmé :

```promql
up{instance="192.168.50.10:9182",job="windows"} = 1
```

Grafana est ensuite revenu à l'état `Normal`.

## 6. Validation du rétablissement

Le test a confirmé le cycle suivant :

1. Service initialement opérationnel.
2. Arrêt contrôlé de Windows Exporter.
3. Détection de l'indisponibilité par Prometheus.
4. Déclenchement de l'alerte Grafana.
5. Redémarrage du service.
6. Retour de Prometheus à `up = 1`.
7. Retour de Grafana à `Normal`.

L'incident est **résolu** et le scénario est **reproductible et réversible**.

## 7. Preuves

Les captures sont conservées dans le répertoire `evidence/` du dépôt :

- [Historique des alertes Grafana](../evidence/grafana-alert-history.png)
- [Alerte Grafana en état Firing](../evidence/grafana-incident-firing.png)
- [Retour de Grafana à l'état Normal](../evidence/grafana-incident-recovered.png)

L'historique contient également des événements antérieurs dont les causes exactes ne sont pas établies. Seul le test contrôlé décrit ici est attribué avec certitude à l'arrêt volontaire de Windows Exporter.

## 8. Limites et améliorations

- L'alerte détecte l'indisponibilité de l'exporter ou de sa collecte, pas nécessairement une panne complète du serveur.
- Une notification externe pourrait être configurée pour prévenir automatiquement un administrateur.
- Une supervision complémentaire des services critiques AD DS et DNS permettrait de mieux distinguer les incidents de collecte des incidents applicatifs.
- Le test pourrait être enrichi par des journaux Windows horodatés pour mesurer précisément les délais de détection et de résolution.

## 9. Conclusion

La simulation démontre que l'infrastructure InfraReady peut détecter une interruption de la collecte des métriques Windows, signaler l'incident dans Grafana et confirmer le rétablissement après intervention.

Le service a été restauré sans modification permanente de la configuration.
