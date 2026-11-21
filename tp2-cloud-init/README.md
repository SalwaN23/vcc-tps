# TP2 : Personnalisation et automatisation des VM avec Cloud-Init

**Module :** Virtualisation et Cloud Computing, Master BD2C, FSAC, 2026/2027
**Étudiante :** Salwa Naciri

## 1. Fondamentaux et NoCloud (Ex. 1 à 4)
### Exercice 1 : découverte de Cloud-Init

VM utilisée : `ubuntu-app01` (déployée au TP1 depuis `ubuntu-template-v1`).
Preuves : `preuves/ex01-cloud-init.txt`, `captures/ex01-cloud-init.png`.

Résultats observés : cloud-init 26.2, `status: done`, aucune erreur,
datasource `DataSourceNoCloud [seed=/dev/sr0]`, instance-id `tp1-ubuntu-app01-v1`.

**Les 4 étapes** : `init-local` (avant le réseau, cherche la datasource),
`init` (après le réseau, applique les réglages de base), `config` (modules :
utilisateurs, SSH, paquets), `final` (commandes finales, `runcmd`).

**Rôle d'une datasource** : c'est la source d'où Cloud-Init lit ses
consignes (`user-data`, `meta-data`) au démarrage. Ici, un CD virtuel NoCloud
(volume `cidata`) ; dans un cloud public, un service de métadonnées.

**Premier démarrage et gestion continue** : Cloud-Init configure l'instance
une seule fois, à sa première vie (identifiée par l'instance-id). Il ne
maintient pas la machine dans le temps. La gestion continue (corriger la
dérive, redéployer des services) relève d'un outil comme Ansible (TP3).

### Exercice 2 : premier fichier user-data

Fichier : `cloud_init/user-data.yaml`. Preuves : `preuves/ex02-user-data.txt`,
`captures/ex02-user-data.png`.

- `hostname` : nom de la machine (`bd2c-vm01`).
- `users` : liste des utilisateurs à créer ; `default` conserve l'utilisateur
  de l'image, `etudiant` est ajouté.
- `groups` : groupes de l'utilisateur. Le sujet cite `wheel` (Rocky) et `sudo`
  (Ubuntu) ; seul `sudo` est conservé car l'image est Ubuntu 24.04.
- `lock_passwd: true` : mot de passe verrouillé, connexion par clé SSH uniquement.

Syntaxe vérifiée avec PyYAML (`yaml.safe_load`) : fichier valide. Un test avec
une indentation volontairement fausse provoque bien une erreur.
## 2. SSH, réseau, logiciels (Ex. 5 à 7)
*À compléter*

## 3. Profils, Jinja2, inventaire (Ex. 8 à 10)
*À compléter*

## 4. Diagnostic (Ex. 11)
*À compléter*

## 5. Mini-projet web01 / db01 / admin01 (Ex. 12)
*À compléter*

## 6. Difficultés rencontrées
| Problème | Diagnostic | Solution |
|----------|------------|----------|
| | | |
