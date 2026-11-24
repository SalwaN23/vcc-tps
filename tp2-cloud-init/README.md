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

### Exercice 3 : datasource NoCloud et ISO seed

Fichiers : `cloud_init/meta-data.yaml`, ISO générée `output/seed-vm01.iso`
(non versionnée). Preuves : `preuves/ex03-seed-iso.txt`, `captures/ex03-seed-iso.png`.

Les fichiers du dépôt portent l'extension `.yaml`, mais Cloud-Init attend les
noms `user-data` et `meta-data` : ils sont renommés dans l'ISO avec
`genisoimage -graft-points`.

**Pourquoi `instance-id` doit changer pour une nouvelle instance ?** Cloud-Init
identifie une instance par son `instance-id`. S'il est identique à celui déjà
enregistré sur le disque, il considère que cette instance est déjà configurée
et ne rejoue pas les modules de premier démarrage. Un nouvel `instance-id`
indique une nouvelle instance, donc une nouvelle configuration.

**Rôle du volume `cidata` ?** C'est l'étiquette que la datasource NoCloud
recherche : Cloud-Init monte le disque dont le volume s'appelle `cidata` et y
lit `user-data` et `meta-data`.

### Exercice 4 : déployer une VM KVM personnalisée

Disque indépendant : copie de `ubuntu-template-v1.qcow2` (image Ubuntu 24.04
généralisée, cloud-init installé) en `bd2c-vm01.qcow2`. L'ISO seed est copiée
dans `/var/lib/libvirt/images/` car QEMU ne peut pas toujours lire dans le
dossier personnel. Intégrité de la copie vérifiée avec `qemu-img check`
(même taille que le template, aucune erreur).

VM créée avec `virt-install --import` : 2048 Mo de RAM, 2 vCPU, disque virtio,
ISO seed attachée en CD-ROM, console VNC locale. La RAM de la VM hôte a été
augmentée à environ 5 Go sous VMware pour pouvoir allouer 2048 Mo.

Preuves : `preuves/ex04-deploiement.txt`, `captures/ex04-deploiement.png`.

Résultats : hostname `bd2c-vm01`, `cloud-init status: done` sans erreur,
datasource `NoCloud [seed=/dev/sr0]`, utilisateur `etudiant` créé (groupe `sudo`),
`/etc/hosts` mis à jour. Le Machine ID est régénéré au premier démarrage.

Connexion avec l'utilisateur du template : le mot de passe de `etudiant` est
verrouillé et la clé SSH n'est ajoutée qu'à l'exercice 5.

Le disque de `bd2c-vm01` a déjà effectué son premier démarrage : il n'est pas
réutilisé pour les tests suivants (nouvelle copie du template à chaque test).
## 2. SSH, réseau, logiciels (Ex. 5 à 7)
### Exercice 5 : utilisateurs et sécurisation SSH

Clé générée : `ssh-keygen -t ed25519 -f ~/.ssh/bd2c_tp2`. Seule la clé publique est
placée dans `cloud_init/user-data-vm02.yaml` (`ssh_authorized_keys`) ; la clé privée
reste hors du dépôt. Nouvelle VM `bd2c-vm02` (nouveau disque copié du template, nouvel
`instance-id: iid-bd2c-vm02`), car une VM ayant déjà fait son premier démarrage ne
rejoue pas la configuration.
Preuves : `preuves/ex05-ssh.txt`, `captures/ex05-ssh.png`.

Résultat : connexion par `ssh -i ~/.ssh/bd2c_tp2 etudiant@IP` réussie, sudo sans mot
de passe, `PasswordAuthentication no`, et la connexion par mot de passe est refusée
(`Permission denied (publickey)`).

**Pourquoi désactiver le mot de passe ?** Un mot de passe peut être deviné ou attaqué
par force brute ; une clé privée de 256 bits ne peut pas être devinée et ne circule pas
sur le réseau. Seul le détenteur de la clé peut se connecter.

### Exercice 6 : configuration automatique du réseau

Fichiers : `cloud_init/network-config-dhcp.yaml`, `cloud_init/network-config-static.yaml`
(format v2, interface `enp1s0` relevée avant les tests : `preuves/ex06-avant.txt`).
Dans l'ISO seed, ils sont renommés `network-config` avec `-graft-points`.
Preuves : `preuves/ex06-dhcp.txt`, `preuves/ex06-static.txt`,
`preuves/ex06-reseau-apres.xml`, `captures/ex06-dhcp.png`, `captures/ex06-static.png`.

**Test DHCP (`bd2c-vm03`).** `dhcp4: true`. La VM reçoit `192.168.122.49/24`,
route par défaut `via 192.168.122.1 proto dhcp`. Cloud-Init écrit `dhcp4: true`
dans `/etc/netplan/50-cloud-init.yaml`.

**Plan d'adressage.** Le réseau libvirt `default` est `192.168.122.0/24`, passerelle
`192.168.122.1`. Sa plage DHCP d'origine couvrait `.2` à `.254`, donc une adresse
statique choisie dans cette plage risquait un conflit avec une VM en DHCP. La plage
a été réduite à `.2`-`.99` (`virsh net-edit default`, puis `net-destroy` et `net-start`).

| Zone | Adresses | Usage |
| --- | --- | --- |
| passerelle | `192.168.122.1` | hôte KVM |
| DHCP | `192.168.122.2` à `.99` | VM en adressage automatique |
| statique | `192.168.122.100` à `.254` | VM en adressage fixe |

**Test statique (`bd2c-vm04`).** `dhcp4: false`, adresse `192.168.122.150/24` (hors
plage DHCP, donc sans conflit), route par défaut via `192.168.122.1`, DNS
`192.168.122.1` et `8.8.8.8`. Résultat : `ip addr` montre `192.168.122.150/24`,
la route est `proto static`, le ping vers la passerelle répond (0 % de perte) et
`resolvectl` affiche les deux DNS.

Chaque test utilise une nouvelle VM (nouveau disque copié du template, nouvel
`instance-id`) car Cloud-Init n'applique la configuration qu'au premier démarrage.
Sur Rocky Linux, Cloud-Init peut appliquer la configuration via NetworkManager ;
non testé ici, les VM étant sous Ubuntu (netplan).

### Exercice 7 : paquets, fichiers et commandes

Fichiers : `cloud_init/user-data-vm05.yaml`, `cloud_init/meta-data-vm05.yaml`.
Preuves : `preuves/ex07-paquets.txt`, `captures/ex07-paquets.png`.

Le `user-data` reprend la base de l'exercice 5 et ajoute quatre blocs dans un seul
document YAML (chaque clé n'apparaît qu'une fois, vérifié avec PyYAML) :

| Bloc | Rôle | Étape Cloud-Init |
| --- | --- | --- |
| `package_update: true` | met à jour la liste des paquets | `config` |
| `packages: [nginx]` | installe nginx | `config` |
| `write_files` | écrit `/etc/motd` (droits `0644`) | `init` |
| `runcmd` | active et démarre nginx (`systemctl enable --now nginx`) | `final` |

Nouvelle VM `bd2c-vm05` (nouveau disque, `instance-id: iid-bd2c-vm05`), réseau en DHCP
(`192.168.122.88`). L'installation passe par le NAT de libvirt : la VM a accès à internet
(ping vers `8.8.8.8` et téléchargement depuis le miroir Ubuntu réussis).

Résultats : `cloud-init status: done` sans erreur ; `nginx 1.24.0` installé ;
`systemctl status nginx` : `active (running)` et `enabled` ; `curl http://localhost`
renvoie la page `Welcome to nginx!` ; `/etc/motd` contient `Laboratoire BD2C - Cloud-Init`.

Sur Rocky Linux 9, il faudrait en plus ouvrir HTTP dans le pare-feu
(`firewall-cmd --permanent --add-service=http`) ; non testé ici, les VM étant sous Ubuntu.
## 3. Profils, Jinja2, inventaire (Ex. 8 à 10)
### Exercice 8 : profils réutilisables

Trois profils dans `profils/` : `web.yaml` (nginx), `database.yaml` (mariadb-server),
`admin.yaml` (htop, curl, net-tools). Chaque profil contient `role`, `service` et une
liste `packages`.

Un profil est une **donnée d'entrée** : il décrit ce qui change selon le rôle de la VM.
Ce n'est pas un fichier cloud-config complet (pas de `#cloud-config`, pas d'utilisateur
ni de clé SSH) ; c'est le modèle qui l'insère dans un vrai `user-data`.

### Exercice 9 : génération avec Jinja2

Modèle : `templates/user_data.j2`, dans un environnement virtuel Python (`.venv`,
Jinja2 et PyYAML).

- **Variables** : `{{ hostname }}`, `{{ username }}`, `{{ ssh_public_key }}`, `{{ service }}`.
- **Boucle** : `{% for pkg in packages %}` écrit une ligne `- paquet` par paquet du profil.
- **Condition** (ajout par rapport au sujet) : `{% if service != 'none' %}` n'écrit le bloc
  `runcmd` que si le profil a un service à démarrer ; le profil admin n'en a pas.

**Séparation données et modèle** : les données (inventaire, profils) disent *quoi* installer
et *sur quelle VM* ; le modèle dit *comment* l'écrire en cloud-config. Changer une VM revient
à changer une ligne de données, sans toucher au modèle, et la même structure vaut pour 3 ou
100 VM.

### Exercice 10 : inventaire YAML et génération de plusieurs VM

Inventaire : `inventaire/vms.yaml`.

| Nom | Hostname | OS | CPU | RAM (Mo) | Profil |
| --- | --- | --- | --- | --- | --- |
| `vm_web` | `web01` | ubuntu | 2 | 2048 | web |
| `vm_db` | `db01` | ubuntu | 2 | 2048 | database |
| `vm_admin` | `admin01` | ubuntu | 1 | 1024 | admin |

Script : `scripts/generate.py`. Pour chaque VM, il lit son profil, remplit le modèle, écrit
`user-data` et `meta-data` dans `output/<nom>/`, puis fabrique `seed.iso` (volume `cidata`)
avec `genisoimage`. Différences avec le script du sujet : il est dans `scripts/` (la racine du
projet s'obtient avec `.parent.parent`), l'`instance-id` est unique par VM
(`iid-bd2c-web01`, `iid-bd2c-db01`, `iid-bd2c-admin01`) et les options `trim_blocks` et
`lstrip_blocks` évitent les lignes vides laissées par les balises Jinja2.

Preuves : `preuves/ex08-10-generation.txt`, `captures/ex08-10-generation-1.png`,
`captures/ex08-10-generation-2.png`. Résultat : trois dossiers générés ; `runcmd` présent
pour web et database (nginx, mariadb) et absent pour admin ; chaque ISO contient `user-data`
et `meta-data` (volume `cidata`).

Le lancement des trois instances avec `virt-install --import` (copie de l'image de base trois
fois) est réalisé par `scripts/deploy.sh` dans le mini-projet (exercice 12).

## 4. Diagnostic (Ex. 11)
*À compléter*

## 5. Mini-projet web01 / db01 / admin01 (Ex. 12)
*À compléter*

## 6. Difficultés rencontrées
| Problème | Diagnostic | Solution |
|----------|------------|----------|
| | | |
