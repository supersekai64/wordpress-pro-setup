# 🚀 WordPress Pro Setup

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![Docker](https://img.shields.io/badge/Docker-Automated%20Installation-blue?logo=docker)
![VS Code](https://img.shields.io/badge/VS%20Code-Automated%20Setup-blue?logo=visual-studio-code)
![WordPress](https://img.shields.io/badge/WordPress-Latest-blue?logo=wordpress)
![License](https://img.shields.io/badge/License-MIT-green)

> **Automatisez votre environnement de développement WordPress en 5 minutes !**

Script PowerShell qui crée automatiquement un environnement de développement WordPress professionnel avec Docker et Visual Studio Code. Plus de configuration manuelle, plus de conflits de ports - tout est géré automatiquement !

## ✨ Fonctionnalités Principales

### 🔧 Installation Automatique des Outils
Le script **installe automatiquement** tous les outils nécessaires :
- **Docker Desktop** - Conteneurisation et environnement isolé
- **Visual Studio Code** - Éditeur de code optimisé
- **Git** - Contrôle de version
- **Node.js** - JavaScript runtime et npm
- **Composer** - Gestionnaire de dépendances PHP
- **PHP CodeSniffer** - Standards de code WordPress

### 🎯 Configuration Intelligente
- **Gestion des ports automatique** - Détecte et évite les conflits
- **Projets multiples** - Chaque projet sur des ports différents
- **Versions personnalisables** - PHP (7.4, 8.0, 8.1, 8.2, 8.3), WordPress, MySQL
- **WordPress en français** - Configuration française par défaut

### 🔌 Extensions VS Code Pré-configurées
- **Docker** - Gestion des conteneurs
- **PHP IntelliSense** - Autocomplétion PHP avancée
- **WordPress Toolbox** - Outils spécialisés WordPress
- **WordPress Hooks IntelliSense** - Hooks et filtres WordPress
- **PHP DocBlocker** - Documentation automatique
- **Prettier** - Formatage de code
- **Et 3 autres extensions essentielles**

### 🐳 Stack Docker Complète
- **WordPress** avec WP-CLI intégré
- **MySQL** (5.7 ou 8.0) avec base pré-configurée
- **phpMyAdmin** pour la gestion BDD
- **Configuration optimisée** pour le développement

## 📋 Prérequis

- **Windows 10/11** (64-bit)
- **PowerShell 5.1+** (intégré à Windows)
- **Droits administrateur** (pour l'installation des outils)
- **Connexion Internet** (pour télécharger les outils et images Docker)

> ⚠️ **Important** : Docker et VS Code seront installés automatiquement par le script si absent !

## 🚀 Installation

### 1. Télécharger le Script
```powershell
# Cloner le repository
git clone https://github.com/username/wordpress-pro-setup.git
cd wordpress-pro-setup

# Ou télécharger directement le fichier PowerShell
```

### 2. Lancer le Script
```powershell
# Ouvrir PowerShell en tant qu'Administrateur
# Naviguer vers le dossier du script
.\WordPress Pro Setup.ps1
```

### 3. Suivre l'Assistant
Le script vous guidera à travers :
1. **Vérification automatique** des outils (installation si manquant)
2. **Configuration du projet** (nom, versions)
3. **Création de l'environnement** (Docker + VS Code)
4. **Démarrage automatique** du projet

## 📖 Utilisation

### Menu Principal
```
╭──────────────────────────────────────────────╮
│            WORDPRESS PRO SETUP              │
├──────────────────────────────────────────────┤
│                                              │
│  1. 🚀 Créer un nouveau projet WordPress     │
│  2. 🔧 Vérifier les outils installés         │
│  3. 📚 Aide et documentation                 │
│  4. ❌ Quitter                               │
│                                              │
╰──────────────────────────────────────────────╯
```

### Création d'un Projet
1. **Choisir un nom** de projet (ex: "mon-site-wp")
2. **Sélectionner les versions** PHP, WordPress, MySQL
3. **Laisser le script travailler** (5-10 minutes)
4. **Projet prêt !** VS Code s'ouvre automatiquement

### Accès aux Services
- **WordPress** : `http://localhost:8080` (port auto-assigné)
- **phpMyAdmin** : `http://localhost:8081` (port auto-assigné)
- **Admin WordPress** : `admin` / `admin123`
- **Base de données** : `wordpress_db` / `wordpress` / `wordpress_password`

## 🛠️ Commandes Docker Utiles

### Gestion des Conteneurs
```bash
# Démarrer l'environnement
docker-compose up -d

# Arrêter l'environnement
docker-compose down

# Voir les logs
docker-compose logs -f

# Redémarrer un service
docker-compose restart wordpress
```

### WP-CLI (WordPress Command Line)
```bash
# Accéder au terminal WP-CLI
docker-compose exec wp-cli bash

# Installer un plugin
docker-compose exec wp-cli wp plugin install contact-form-7 --activate

# Créer un utilisateur
docker-compose exec wp-cli wp user create john john@example.com --role=editor

# Exporter la base de données
docker-compose exec wp-cli wp db export backup.sql
```

### PHP CodeSniffer (Standards WordPress)
```bash
# Vérifier le code PHP
docker-compose exec wp-cli phpcs --standard=WordPress /var/www/html/wp-content/themes/

# Corriger automatiquement
docker-compose exec wp-cli phpcbf --standard=WordPress /var/www/html/wp-content/themes/
```

## 📂 Structure du Projet

```
mon-projet-wp/
├── docker-compose.yml      # Configuration Docker
├── mon-projet-wp.code-workspace  # Workspace VS Code
├── SYSTEM-INFO.md         # Documentation du projet
├── wordpress/             # Fichiers WordPress
│   ├── wp-content/
│   │   ├── themes/        # Vos thèmes personnalisés
│   │   └── plugins/       # Vos plugins personnalisés
│   └── ...
├── mysql/                 # Base de données MySQL
└── .vscode/               # Configuration VS Code
    ├── settings.json      # Paramètres optimisés
    ├── tasks.json         # Tâches automatisées
    └── snippets/          # Snippets WordPress
```

## 🔧 Configuration VS Code

### Paramètres Optimisés
- **PHP IntelliSense** configuré pour WordPress
- **Formatage automatique** avec Prettier
- **Standards WordPress** avec PHPCS
- **Débogage PHP** pré-configuré
- **Emmet** activé pour PHP/HTML

### Tâches Intégrées
- 🚀 Démarrer WordPress
- ⏹️ Arrêter WordPress  
- 📋 Voir tous les logs
- 📊 État des conteneurs
- 🔧 Terminal WP-CLI
- 📏 Vérifier code PHP (PHPCS)
- 🔧 Corriger code PHP (PHPCBF)

## ❓ Dépannage

### Docker non démarré
```powershell
# Vérifier l'état de Docker
docker info

# Démarrer Docker Desktop manuellement si nécessaire
```

### Conflits de ports
Le script détecte automatiquement les ports occupés. Si vous rencontrez des problèmes :
```powershell
# Vérifier les ports utilisés
netstat -an | findstr ":8080"

# Le script proposera automatiquement des ports alternatifs
```

### Extensions VS Code
```powershell
# Lister les extensions installées
code --list-extensions

# Réinstaller une extension manuellement
code --install-extension ms-azuretools.vscode-docker
```

### Performance MySQL
Si MySQL est lent à démarrer :
- Augmenter la RAM allouée à Docker (4GB minimum recommandé)
- Vérifier l'espace disque disponible

## 🤝 Contribuer

1. **Fork** le projet
2. **Créer** une branche pour votre fonctionnalité (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Commit** vos changements (`git commit -am 'Ajout de la nouvelle fonctionnalité'`)
4. **Push** vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. **Ouvrir** une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## ⭐ Support

Si ce script vous fait gagner du temps, n'hésitez pas à :
- ⭐ **Mettre une étoile** au projet
- 🐛 **Signaler des bugs** via les Issues
- 💡 **Proposer des améliorations**
- 📢 **Partager** avec d'autres développeurs

---

**Développé avec ❤️ par [Paul CORNILLAD](https://www.linkedin.com/in/paul-cornillad/)**

*Automatisez votre workflow WordPress et concentrez-vous sur l'essentiel : le code !*
