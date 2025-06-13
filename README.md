# 🚀 WordPress Pro Setup

> **Script PowerShell d'automatisation complète pour créer des environnements de développement WordPress avec Docker et Visual Studio Code**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/en-us/powershell/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue)](https://www.docker.com/)
[![WordPress](https://img.shields.io/badge/WordPress-Latest-blue)](https://wordpress.org/)

## 📖 À propos

**WordPress Pro Setup** transforme la création d'environnements WordPress de développement de 3 heures de configuration manuelle à **5 minutes chrono** ! 

Ce script PowerShell automatise entièrement la configuration d'un environnement de développement WordPress professionnel avec Docker, incluant la vérification et l'installation automatique de tous les prérequis.

### 🎯 Problème résolu

Fini les configurations manuelles fastidieuses :
- ❌ Installation manuelle de Docker, PHP, MySQL, VS Code
- ❌ Configuration des ports qui entrent en conflit
- ❌ Création manuelle des fichiers docker-compose.yml
- ❌ Installation une par une des extensions VS Code
- ❌ Oubli d'étapes cruciales dans la configuration

## ✨ Fonctionnalités principales

### 🔍 **Détection et installation automatique**
- Vérification complète des prérequis
- Installation automatique via Chocolatey : Docker, Node.js, Composer, VS Code, Git
- Configuration d'environnement intelligente

### 🧠 **Gestion intelligente des ports**
- Détection automatique des ports libres
- Sauvegarde et réutilisation des configurations de ports par projet
- Gestion de projets multiples sans conflit

### ⚙️ **Configuration sur mesure**
- **PHP** : Versions 8.0, 8.1, 8.2, 8.3
- **WordPress** : Dernière version ou version spécifique
- **MySQL** : Versions 5.7 ou 8.0
- **Langue** : Configuration automatique en français

### 💼 **Environnement VS Code complet**
- **9 extensions WordPress** installées automatiquement
- Workspace pré-configuré avec IntelliSense PHP
- **Standards WordPress** avec PHP CodeSniffer intégré
- Snippets WordPress personnalisés
- Tâches Docker intégrées

### 📁 **Structure de projet standardisée**
```
mon-projet/
├── 📁 wordpress/              # Fichiers WordPress
├── 📁 mysql/                 # Base de données persistante
├── 🐳 docker-compose.yml     # Configuration conteneurs
├── 💼 mon-projet.code-workspace # Workspace VS Code
└── 📊 SYSTEM-INFO.md         # Documentation automatique
```

## 🚀 Installation et utilisation

### Prérequis
- **Windows 10/11** avec PowerShell 5.1+
- **Droits administrateur** (pour installation des outils)
- **Connexion internet** active

### 🎬 Démarrage rapide

1. **Télécharger le script**
   ```powershell
   # Télécharger depuis GitHub
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/username/wordpress-pro-setup/main/WordPress Pro Setup.ps1" -OutFile "WordPress Pro Setup.ps1"
   ```

2. **Exécuter le script**
   ```powershell
   # Autoriser l'exécution (une seule fois)
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

   # Lancer le script
   .\WordPress Pro Setup.ps1
   ```

3. **Suivre le menu interactif**
   - Choix du nom de projet
   - Sélection des versions (PHP, WordPress, MySQL)
   - Configuration automatique des ports
   - Démarrage automatique de l'environnement

4. **Commencer à développer !**
   - Site accessible sur `http://localhost:PORT`
   - Admin : `http://localhost:PORT/wp-admin` (admin/admin123)
   - phpMyAdmin : `http://localhost:PORT_PHPMYADMIN`

## 🛠️ Ce qui est installé automatiquement

### 📦 **Outils de développement**
- **Docker Desktop** - Conteneurisation
- **Git** - Contrôle de version
- **Node.js** - Runtime JavaScript
- **Composer** - Gestionnaire de dépendances PHP
- **Visual Studio Code** - Éditeur de code
- **Chocolatey** - Gestionnaire de paquets Windows

### 🔌 **Extensions VS Code**
- **Docker** - Gestion des conteneurs
- **PHP IntelliSense** - Autocomplétion PHP avancée
- **WordPress Toolbox** - Outils spécialisés WordPress
- **WordPress Hooks** - IntelliSense pour les hooks WordPress
- **PHP DocBlocker** - Documentation PHP automatique
- **Prettier** - Formatage de code
- **Tailwind CSS** - Support CSS
- **Auto Rename Tag** - Renommage automatique des balises
- **Path Intellisense** - Autocomplétion des chemins

### 🐳 **Stack Docker**
- **WordPress** (dernière version ou spécifique)
- **MySQL** (5.7 ou 8.0)
- **phpMyAdmin** - Interface de gestion BDD
- **WP-CLI** - Interface en ligne de commande WordPress

### 🔌 **Configuration WordPress**
- **Langue française** par défaut
- **Query Monitor** installé (débogage/optimisation)
- **Plugins indésirables supprimés** (Hello Dolly, Akismet)
- **Debug mode activé** pour le développement

## 📋 Fonctionnalités avancées

### 🎯 **Menu principal**
1. **Créer un nouveau projet WordPress**
2. **Lister les projets existants**
3. **Vérifier les outils installés**
4. **Gestion des ports intelligents**
5. **Aide et documentation**

### 🔌 **Gestion des ports intelligents**
- Affichage des ports utilisés par projet
- Nettoyage des ports inutilisés
- Statistiques d'utilisation des ports
- Détection des conflits

### 📊 **Documentation automatique**
Chaque projet génère automatiquement :
- **SYSTEM-INFO.md** - Guide complet du projet
- **Raccourci bureau** - Accès rapide au projet
- **Configuration VS Code** - Workspace prêt à l'emploi

## 🛠️ Commandes Docker utiles

Le script génère automatiquement des tâches VS Code pour :

```bash
# Gestion des conteneurs
docker-compose up -d          # Démarrer
docker-compose down           # Arrêter
docker-compose restart        # Redémarrer
docker-compose logs -f        # Voir les logs

# WP-CLI
docker-compose exec wp-cli wp plugin list
docker-compose exec wp-cli wp theme list
docker-compose exec wp-cli wp db export backup.sql

# PHP CodeSniffer
docker-compose exec wp-cli phpcs --standard=WordPress /var/www/html/wp-content/themes/
```

## 🔧 Configuration personnalisée

### Modifier les ports par défaut
Éditez la fonction `Get-Configuration` dans le script :

```powershell
$defaultConfig = @{
    DefaultPorts = @{
        WordPress = 8080    # Port WordPress
        MySQL = 3306       # Port MySQL
        PHPMyAdmin = 8081  # Port phpMyAdmin
    }
}
```

### Ajouter des plugins par défaut
```powershell
$defaultConfig = @{
    DefaultPlugins = @(
        "query-monitor",
        "wp-super-cache",
        "contact-form-7"
    )
}
```

## 🆘 Dépannage

### Problèmes courants

**🚨 "Port déjà utilisé"**
- Le script détecte automatiquement les ports libres
- Utilisez la gestion des ports intelligents (option 4)

**🚨 "Docker non démarré"**
- Lancez Docker Desktop manuellement
- Le script attend que Docker soit prêt

**🚨 "Permission denied"**
- Exécutez PowerShell en tant qu'administrateur
- Vérifiez la politique d'exécution : `Get-ExecutionPolicy`

**🚨 "Extensions VS Code non installées"**
- Redémarrez VS Code après la première installation
- Installez manuellement : `code --install-extension nom-extension`

### Logs et diagnostics
```powershell
# Voir les logs Docker
docker-compose logs

# Vérifier le statut des conteneurs
docker-compose ps

# Redémarrer complètement
docker-compose down && docker-compose up -d
```

## 🤝 Contribution

Les contributions sont les bienvenues ! 

1. **Fork** le projet
2. **Créer** une branche feature (`git checkout -b feature/AmazingFeature`)
3. **Commiter** les changements (`git commit -m 'Add AmazingFeature'`)
4. **Push** sur la branche (`git push origin feature/AmazingFeature`)
5. **Ouvrir** une Pull Request

### Idées de contributions
- Support pour d'autres OS (Linux, macOS)
- Templates de projets prédéfinis
- Intégration CI/CD
- Interface graphique

## 📝 Changelog

### Version 2.1 (Actuelle)
- ✅ Gestion intelligente des ports multiples projets
- ✅ Menu interactif complet
- ✅ Documentation automatique (SYSTEM-INFO.md)
- ✅ Raccourcis bureau automatiques
- ✅ Support PHP 8.3
- ✅ Amélioration de la stabilité Docker

### Version 2.0
- ✅ Refactorisation complète du code
- ✅ Interface utilisateur améliorée
- ✅ Gestion des erreurs robuste
- ✅ Support projets multiples

## 📄 License

Ce projet est sous licence **MIT** - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Paul CORNILLAD**
- LinkedIn: [paul-cornillad](https://www.linkedin.com/in/paul-cornillad/)
- GitHub: [@paul-cornillad](https://github.com/paul-cornillad)

---

<div align="center">

**⭐ N'oubliez pas de mettre une étoile si ce projet vous aide ! ⭐**

*Développé avec ❤️ pour la communauté WordPress*

</div>
