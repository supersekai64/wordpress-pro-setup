# ============================================================================
# 🚀 WORDPRESS DEVELOPMENT ENVIRONMENT SETUP SCRIPT
# ============================================================================
# Author: Paul CORNILLAD
# Description: Automated script for creating WordPress development environments with Docker & Visual Studio Code
# Version: 2.1
# License: MIT
# LinkedIn: https://www.linkedin.com/in/paul-cornillad/
# ============================================================================

# Global configuration parameters
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# 🎨 COLORS AND STYLES CONFIGURATION
# ============================================================================

# Color constants for consistent styling
$Global:Colors = @{
    Red     = "Red"
    Green   = "Green"
    Yellow  = "Yellow"
    Blue    = "Blue"
    Magenta = "Magenta"
    Cyan    = "Cyan"
}

# Required Visual Studio Code extensions for WordPress development
$Global:RequiredVSCodeExtensions = @(
    "ms-azuretools.vscode-docker",
    "bmewburn.vscode-intelephense-client",
    "wordpresstoolbox.wordpress-toolbox",
    "johnbillion.vscode-wordpress-hooks",
    "neilbrayfield.php-docblocker",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense"
)

# ============================================================================
# 🛠️ FONCTIONS UTILITAIRES
# ============================================================================

function Write-ColorText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $true)]
        [string]$Color
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [string]$Icon = "🔥"
    )
    Clear-Host
    Write-Host ""
    Write-ColorText "$Icon $Title" $Global:Colors.Cyan
    Write-Host ""
    Write-Host ""
}

function Write-Box {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [string]$Color = $Global:Colors.Cyan
    )
    $borderLength = $Text.Length + 4
    $border = "═" * $borderLength
    
    Write-Host ""
    Write-ColorText "╭$border╮" $Color
    Write-ColorText "│  $Text  │" $Color
    Write-ColorText "╰$border╯" $Color
    Write-Host ""
}

function Write-Success {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-ColorText "✅ $Message" $Global:Colors.Green
}

function Write-Error {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-ColorText "❌ $Message" $Global:Colors.Red
}

function Write-Warning {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-ColorText "⚠️ $Message" $Global:Colors.Yellow
}

function Write-Info {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-ColorText "ℹ️ $Message" $Global:Colors.Blue
}

# ============================================================================
# 🔧 TOOL VERIFICATION FUNCTIONS
# ============================================================================

function Test-ToolInstalled {
    <#
    .SYNOPSIS
    Tests if a command-line tool is installed and accessible.
    
    .PARAMETER Command
    The command name to test.
    
    .EXAMPLE
    Test-ToolInstalled -Command "docker"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-ToolVersion {
    <#
    .SYNOPSIS
    Gets the version of an installed tool.
    
    .PARAMETER Command
    The command name to get version for.
    
    .EXAMPLE
    Get-ToolVersion -Command "docker"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    try {
        switch ($Command) {
            "choco" { 
                $version = choco --version 2>$null
                return $version
            }
            "git" { 
                $version = git --version 2>$null
                return ($version -split " ")[2]
            }
            "node" { 
                $version = node --version 2>$null
                return $version.TrimStart('v')
            }
            "composer" { 
                $version = composer --version 2>$null
                return ($version -split " ")[2]
            }
            "docker" { 
                $version = docker --version 2>$null
                return ($version -split " ")[2].TrimEnd(',')
            }
            "code" { 
                $version = code --version 2>$null | Select-Object -First 1
                return $version
            }
            default { return "N/A" }
        }
    } catch {
        return "N/A"
    }
}

function Test-ComposerPackage {
    <#
    .SYNOPSIS
    Tests if a Composer package is installed globally.
    
    .PARAMETER PackageName
    The name of the package to check.
    
    .EXAMPLE
    Test-ComposerPackage -PackageName "squizlabs/php_codesniffer"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )
    
    try {
        $output = composer global show 2>$null
        return $output -match $PackageName
    } catch {
        return $false
    }
}

function Test-VSCodeExtension {
    <#
    .SYNOPSIS
    Tests if a Visual Studio Code extension is installed.
    
    .PARAMETER ExtensionId
    The ID of the extension to check.
    
    .EXAMPLE
    Test-VSCodeExtension -ExtensionId "ms-azuretools.vscode-docker"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )
    
    try {
        # Test simple et rapide
        $extensions = code --list-extensions 2>$null
        if ($LASTEXITCODE -eq 0 -and $extensions) {
            return ($extensions -split "`n" | Where-Object { $_.Trim() -eq $ExtensionId }).Count -gt 0
        }
        return $false
    } catch {
        # En cas d'erreur, on assume que l'extension n'est pas installée
        return $false
    }
}

function Test-DockerStatus {
    <#
    .SYNOPSIS
    Tests the status of Docker Desktop.
    
    .EXAMPLE
    Test-DockerStatus
    #>
    try {
        docker info > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{Status="Running"; Message="Docker opérationnel"}
        } else {
            return @{Status="NotRunning"; Message="Docker installé mais non démarré"}
        }
    } catch {
        return @{Status="Error"; Message="Erreur Docker"}
    }
}

function Get-ProjectPortsFile {
    param([string]$ProjectName)
    
    $portsDir = "$env:USERPROFILE\.wordpress-dev"
    if (-not (Test-Path $portsDir)) {
        New-Item -Path $portsDir -ItemType Directory -Force | Out-Null
    }
    
    return "$portsDir\$ProjectName-ports.json"
}

function Save-ProjectPorts {
    param(
        [string]$ProjectName,
        [hashtable]$Ports
    )
    
    try {
        $portsFile = Get-ProjectPortsFile -ProjectName $ProjectName
        $portsData = @{
            ProjectName = $ProjectName
            CreatedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            LastUsed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Ports = $Ports
        }
        
        $portsData | ConvertTo-Json -Depth 10 | Set-Content -Path $portsFile -Encoding UTF8
        Write-Debug "Ports sauvegardés pour le projet $ProjectName dans $portsFile"
    } catch {
        Write-Debug "Erreur lors de la sauvegarde des ports: $($_.Exception.Message)"
    }
}

function Get-ProjectPorts {
    param([string]$ProjectName)
    
    try {
        $portsFile = Get-ProjectPortsFile -ProjectName $ProjectName
        if (Test-Path $portsFile) {
            $portsData = Get-Content -Path $portsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            
            # Mettre à jour la date de dernière utilisation
            $portsData.LastUsed = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $portsData | ConvertTo-Json -Depth 10 | Set-Content -Path $portsFile -Encoding UTF8
            
            return $portsData.Ports
        }
        return $null
    } catch {
        Write-Debug "Erreur lors du chargement des ports: $($_.Exception.Message)"
        return $null
    }
}

function Test-PortAvailableForProject {
    param(
        [int]$Port,
        [string]$ProjectName
    )
    
    Write-Debug "Testing port $Port availability for project $ProjectName..."
    
    # 1. Vérifier avec netstat (ports système)
    try {
        $netstatCmd = "netstat -an"
        $netstatOutput = Invoke-Expression $netstatCmd 2>$null
        if ($netstatOutput) {
            # Rechercher le port dans différents formats
            $portPatterns = @(
                ":$Port ",      # Format standard
                ":${Port}:",    # Format avec deux points
                " $Port ",      # Port seul
                ".$Port ",      # Avec point
                "0.0.0.0:$Port",    # Format IPv4 complet
                "127.0.0.1:$Port",  # Localhost
                ":::$Port",         # IPv6 format
                "\[::\]:$Port"      # IPv6 avec crochets
            )
            
            foreach ($pattern in $portPatterns) {
                if ($netstatOutput -match [regex]::Escape($pattern)) {
                    Write-Debug "Port $Port found in netstat with pattern $pattern"
                    return $false
                }
            }
        }
    } catch {
        Write-Debug "Netstat check failed for port $Port"
    }
    
    # 2. Vérifier les conteneurs Docker ACTIFS seulement (ignorer les arrêtés)
    try {
        $dockerOutput = docker ps --format "{{.Names}} {{.Ports}}" 2>$null
        if ($dockerOutput) {
            $dockerLines = $dockerOutput -split "`n" | Where-Object { $_.Trim() -ne "" }
            foreach ($line in $dockerLines) {
                # Ignorer les conteneurs de ce projet
                if ($line -match "^${ProjectName}_") {
                    continue
                }
                
                # Patterns pour détecter le port dans les autres conteneurs
                $patterns = @(
                    "0\.0\.0\.0:$Port->",           # IPv4 direct
                    "\[::\]:$Port->",               # IPv6 direct
                    ":$Port->",                     # Port mapping général
                    "127\.0\.0\.1:$Port->",         # Localhost
                    "localhost:$Port->"             # Localhost text
                )
                
                foreach ($pattern in $patterns) {
                    if ($line -match $pattern) {
                        Write-Debug "Port $Port found in Docker container (non-project): $line"
                        return $false
                    }
                }
            }
        }
    } catch {
        Write-Debug "Docker check failed for port $Port"
    }
    
    # 3. Test direct avec TcpListener (le plus fiable)
    try {
        $listener = New-Object System.Net.Sockets.TcpListener -ArgumentList ([System.Net.IPAddress]::Any), $Port
        $listener.Start()
        $listener.Stop()
        Write-Debug "Port $Port is available (TcpListener test passed)"
        return $true
    } catch {
        Write-Debug "Port $Port is NOT available (TcpListener test failed): $($_.Exception.Message)"
        return $false
    }
}



function Test-PortDetailed {
    param([int]$Port)
    
    Write-Host "🔍 Test détaillé pour le port $Port :" -ForegroundColor Yellow
    
    # Test 1: netstat
    Write-Host "  1. Test netstat..." -NoNewline
    try {
        $netstatOutput = netstat -an 2>$null
        $netstatMatch = $netstatOutput | Select-String ":$Port " -Quiet
        if ($netstatMatch) {
            Write-Host " ❌ Port trouvé dans netstat" -ForegroundColor Red
        } else {
            Write-Host " ✅ Port libre dans netstat" -ForegroundColor Green
        }
    } catch {
        Write-Host " ⚠️ Erreur netstat" -ForegroundColor Yellow
    }
    
    # Test 2: Docker
    Write-Host "  2. Test Docker..." -NoNewline
    try {
        $dockerOutput = docker ps --format "{{.Ports}}" 2>$null
        if ($dockerOutput) {
            $dockerMatch = $dockerOutput | Select-String ":$Port->" -Quiet
            if ($dockerMatch) {
                Write-Host " ❌ Port trouvé dans Docker" -ForegroundColor Red
                $dockerOutput | Select-String ":$Port->" | ForEach-Object {
                    Write-Host "    -> $_" -ForegroundColor Gray
                }
            } else {
                Write-Host " ✅ Port libre dans Docker" -ForegroundColor Green
            }
        } else {
            Write-Host " ✅ Aucun container Docker" -ForegroundColor Green
        }
    } catch {
        Write-Host " ⚠️ Erreur Docker" -ForegroundColor Yellow
    }
    
    # Test 3: TcpListener
    Write-Host "  3. Test TcpListener..." -NoNewline
    try {
        $listener = New-Object System.Net.Sockets.TcpListener -ArgumentList ([System.Net.IPAddress]::Any), $Port
        $listener.Start()
        $listener.Stop()
        Write-Host " ✅ Port disponible" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " ❌ Port occupé: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# 📁 PROJECT CONFIGURATION FUNCTIONS
# ============================================================================

function Get-Configuration {
    <#
    .SYNOPSIS
    Returns the default configuration settings for WordPress projects.
    
    .DESCRIPTION
    This function provides the default settings including language, theme, plugins, and ports.
    
    .EXAMPLE
    $config = Get-Configuration
    #>
    
    $defaultConfig = @{
        WordPressLanguage = "fr_FR"
        DefaultTheme = "twentytwentyfour"
        DefaultPlugins = @("query-monitor")
        DefaultPorts = @{
            WordPress = 8080
            MySQL = 3306
            PHPMyAdmin = 8081
        }
    }
    return $defaultConfig
}

# ============================================================================
# 🚀 INSTALLATION AND VERIFICATION FUNCTIONS
# ============================================================================

function Install-Chocolatey {
    <#
    .SYNOPSIS
    Installs Chocolatey package manager if not already present.
    
    .DESCRIPTION
    Downloads and installs Chocolatey from the official source.
    
    .EXAMPLE
    Install-Chocolatey
    #>
    
    Write-Info "Installation de Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installé"
        return $true
    } catch {
        Write-Error "Erreur lors de l'installation de Chocolatey - $($_.Exception.Message)"
        return $false
    }
}

function Install-Tool {
    <#
    .SYNOPSIS
    Installs a tool using Chocolatey package manager.
    
    .PARAMETER ToolName
    The display name of the tool.
    
    .PARAMETER ChocoPackage
    The Chocolatey package name.
    
    .EXAMPLE
    Install-Tool -ToolName "Docker" -ChocoPackage "docker-desktop"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$ChocoPackage
    )
    
    Write-Info "Installation de $ToolName..."
    try {
        choco install $ChocoPackage -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$ToolName installé"
            return $true
        } else {
            Write-Error "Erreur lors de l'installation de $ToolName"
            return $false
        }
    } catch {
        Write-Error "Erreur lors de l'installation de $ToolName - $($_.Exception.Message)"
        return $false
    }
}

function Install-VSCodeExtension {
    <#
    .SYNOPSIS
    Installs a Visual Studio Code extension.
    
    .PARAMETER ExtensionId
    The ID of the extension to install.
    
    .EXAMPLE
    Install-VSCodeExtension -ExtensionId "ms-azuretools.vscode-docker"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )
    
    try {
        code --install-extension $ExtensionId > $null 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Install-PHPCodeSniffer {
    <#
    .SYNOPSIS
    Installs PHP CodeSniffer globally using Composer.
    
    .DESCRIPTION
    Installs the PHP CodeSniffer package with WordPress coding standards support.
    
    .EXAMPLE
    Install-PHPCodeSniffer
    #>
    
    Write-Info "Installation de PHP CodeSniffer..."
    try {
        composer global require "squizlabs/php_codesniffer=*"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PHP CodeSniffer installé"
            return $true
        } else {
            Write-Error "Erreur lors de l'installation de PHP CodeSniffer"
            return $false
        }
    } catch {
        Write-Error "Erreur lors de l'installation de PHP CodeSniffer - $($_.Exception.Message)"
        return $false
    }
}

function Test-CompleteCheck {
    <#
    .SYNOPSIS
    Performs a complete check of all prerequisites for WordPress development.
    
    .DESCRIPTION
    Verifies that all required tools are installed and properly configured.
    Installs missing tools automatically with user consent.
    
    .EXAMPLE
    $isReady = Test-CompleteCheck
    #>
    
    Write-Info "Vérification des prérequis..."
    
    $allGood = $true
    $installationNeeded = @()
    
    # Check Chocolatey first
    if (!(Test-ToolInstalled -Command "choco")) {
        Write-Warning "Chocolatey non trouvé"
        Write-Info "Installation de Chocolatey..."
        if (!(Install-Chocolatey)) {
            $allGood = $false
        } else {
            # Reload environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
    } else {
        Write-Success "Chocolatey trouvé"
    }
    
    # Define required tools
    $requiredTools = @(
        @{Name="Git"; Command="git"; Package="git"},
        @{Name="Node.js"; Command="node"; Package="nodejs"},
        @{Name="Composer"; Command="composer"; Package="composer"},
        @{Name="Docker"; Command="docker"; Package="docker-desktop"},
        @{Name="VS Code"; Command="code"; Package="vscode"}
    )
    
    # Check each tool
    foreach ($tool in $requiredTools) {
        if (!(Test-ToolInstalled -Command $tool.Command)) {
            Write-Warning "$($tool.Name) non trouvé"
            $installationNeeded += $tool
        } else {
            Write-Success "$($tool.Name) trouvé"
        }
    }
    
    # Install missing tools if needed
    if ($installationNeeded.Count -gt 0) {
        Write-Warning "Installation des outils manquants..."
        foreach ($tool in $installationNeeded) {
            if (!(Install-Tool -ToolName $tool.Name -ChocoPackage $tool.Package)) {
                $allGood = $false
            }
        }
        
        # Reload environment after installation
        Write-Info "Rechargement de l'environnement..."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    # Check Docker specifically
    if (Test-ToolInstalled -Command "docker") {
        $dockerStatus = Test-DockerStatus
        if ($dockerStatus.Status -ne "Running") {
            Write-Warning "Docker n'est pas démarré. Veuillez démarrer Docker Desktop."
            Write-Info "Le script attendra que Docker soit prêt..."
        } else {
            Write-Success "Docker opérationnel"
        }
    }
    
    # Install VS Code extensions (approche "fire and forget")
    if (Test-ToolInstalled -Command "code") {
        Write-Success "Visual Studio Code trouvé"
    }
    
    # Install PHP CodeSniffer if Composer is available
    if (Test-ToolInstalled -Command "composer") {
        if (!(Test-ComposerPackage -PackageName "squizlabs/php_codesniffer")) {
            Install-PHPCodeSniffer
        } else {
            Write-Success "PHP CodeSniffer trouvé"
        }
    }
    
    return $allGood
}

function Get-ExtensionFriendlyName {
    <#
    .SYNOPSIS
    Converts extension IDs to user-friendly names.
    
    .PARAMETER ExtensionId
    The ID of the extension.
    
    .EXAMPLE
    Get-ExtensionFriendlyName -ExtensionId "ms-azuretools.vscode-docker"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )
    
    $friendlyNames = @{
        "ms-azuretools.vscode-docker" = "Docker"
        "bmewburn.vscode-intelephense-client" = "PHP IntelliSense"
        "wordpresstoolbox.wordpress-toolbox" = "WordPress Toolbox"
        "johnbillion.vscode-wordpress-hooks" = "WordPress Hooks"
        "neilbrayfield.php-docblocker" = "PHP DocBlocker"
        "esbenp.prettier-vscode" = "Prettier"
        "bradlc.vscode-tailwindcss" = "Tailwind CSS IntelliSense"
        "formulahendry.auto-rename-tag" = "Auto Rename Tag"
        "christian-kohler.path-intellisense" = "Path Intellisense"
    }
    
    return if ($friendlyNames.ContainsKey($ExtensionId)) { $friendlyNames[$ExtensionId] } else { $ExtensionId }
}

# ============================================================================
# 🎯 PROJECT CREATION FUNCTIONS
# ============================================================================

function Get-ProjectName {
    <#
    .SYNOPSIS
    Prompts the user for a project name and validates it.
    
    .DESCRIPTION
    Ensures the project name is valid and doesn't already exist.
    
    .EXAMPLE
    $projectName = Get-ProjectName
    #>
    
    Write-Box "📝 NOM DU PROJET" $Global:Colors.Yellow
    
    do {
        $projectName = Read-Host "Entrez le nom de votre projet WordPress"
        
        # Validate project name format
        if ($projectName -notmatch "^[a-zA-Z0-9_-]+$" -or $projectName.Length -lt 3) {
            Write-Error "Nom invalide. Utilisez uniquement des lettres, chiffres, tirets et underscores (minimum 3 caractères)."
            continue
        }
        
        # Check if project already exists
        $projectPath = "C:\dev\wordpress-projects\$projectName"
        if (Test-Path $projectPath) {
            Write-Error "Un projet avec ce nom existe déjà!"
            Write-Info "Choisissez un autre nom ou supprimez le projet existant."
            continue
        }
        
        Write-Success "Nom du projet validé: $projectName"
        return $projectName
        
    } while ($true)
}

function Select-Versions {
    <#
    .SYNOPSIS
    Allows the user to select versions for PHP, WordPress, and MySQL.
    
    .DESCRIPTION
    Provides interactive menus for version selection with validation.
    
    .EXAMPLE
    $versions = Select-Versions
    #>
    
    Write-Box "📦 SÉLECTION DES VERSIONS" $Global:Colors.Yellow
    
    $versions = @{}
    
    # PHP Version Selection
    Write-ColorText "🐘 Version PHP:" $Global:Colors.Cyan
    Write-Host "  1. PHP 8.3 (recommandé)"
    Write-Host "  2. PHP 8.2"
    Write-Host "  3. PHP 8.1"
    Write-Host "  4. PHP 8.0"
    Write-Host ""
    
    do {
        $phpChoice = Read-Host "Choisissez la version PHP (1-4)"
        switch ($phpChoice) {
            "1" { $versions.PHP = "8.3"; break }
            "2" { $versions.PHP = "8.2"; break }
            "3" { $versions.PHP = "8.1"; break }
            "4" { $versions.PHP = "8.0"; break }
            default { 
                Write-Error "Choix invalide"
                continue 
            }
        }
        break
    } while ($true)
    
    # WordPress Version Selection
    Write-Host ""
    Write-ColorText "🌐 Version WordPress:" $Global:Colors.Cyan
    Write-Host "  1. Dernière version (recommandé)"
    Write-Host "  2. Version spécifique"
    Write-Host ""

    do {
        $wpChoice = Read-Host "Choisissez (1-2)"
        switch ($wpChoice) {
            "1" { 
                $versions.WordPress = "latest"
                break 
            }
            "2" { 
                do {
                    $wpVersion = Read-Host "Entrez la version WordPress (ex: 6.4)"
                    if (Test-WordPressVersion -Version $wpVersion) {
                        $versions.WordPress = $wpVersion
                        break
                    } else {
                        Write-Error "Format de version invalide. Utilisez le format X.Y ou X.Y.Z (ex: 6.4 ou 6.4.1)"
                    }
                } while ($true)
                break
            }
            default { 
                Write-Error "Choix invalide"
                continue 
            }
        }
        break
    } while ($true)
    
    # MySQL Version Selection
    Write-Host ""
    Write-ColorText "🗄️ Version MySQL:" $Global:Colors.Cyan
    Write-Host "  1. MySQL 8.0 (recommandé)"
    Write-Host "  2. MySQL 5.7"
    Write-Host ""

    do {
        $mysqlChoice = Read-Host "Choisissez (1-2)"
        switch ($mysqlChoice) {
            "1" { $versions.MySQL = "8.0"; break }
            "2" { $versions.MySQL = "5.7"; break }
            default { 
                Write-Error "Choix invalide"
                continue 
            }
        }
        break
    } while ($true)
    
    Write-Success "Versions sélectionnées: PHP $($versions.PHP), WordPress $($versions.WordPress), MySQL $($versions.MySQL)"
    
    return $versions
}

function Test-WordPressVersion {
    <#
    .SYNOPSIS
    Validates a WordPress version string.
    
    .PARAMETER Version
    The version string to validate.
    
    .EXAMPLE
    Test-WordPressVersion -Version "6.4.1"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    if ($Version -eq "latest") {
        return $true
    }
    
    if ($Version -match "^\d+\.\d+(\.\d+)?$") {
        return $true
    }
    
    return $false
}

function Get-SmartPorts {
    param([string]$ProjectName)
    
    Write-Box "🔌 CONFIGURATION INTELLIGENTE DES PORTS" $Global:Colors.Yellow
    
    # 1. Essayer de charger les ports existants pour ce projet
    $existingPorts = Get-ProjectPorts -ProjectName $ProjectName
    if ($existingPorts) {
        Write-Info "📂 Ports existants trouvés pour le projet '$ProjectName'"
        
        # Vérifier que tous les ports sont encore disponibles
        $allPortsAvailable = $true
        foreach ($service in $existingPorts.Keys) {
            $port = $existingPorts[$service]
            if (-not (Test-PortAvailableForProject -Port $port -ProjectName $ProjectName)) {
                Write-Warning "Port $port ($service) n'est plus disponible"
                $allPortsAvailable = $false
                break
            }
        }
        
        if ($allPortsAvailable) {
            foreach ($service in $existingPorts.Keys) {
                $port = $existingPorts[$service]
                Write-Success "$service - Port $port (réutilisé)"
            }
            return $existingPorts
        } else {
            Write-Warning "Certains ports ne sont plus disponibles, recherche de nouveaux ports..."
        }
    }
    
    # 2. Assigner de nouveaux ports
    Write-Info "🔍 Recherche de ports libres pour le projet '$ProjectName'..."
    
    $defaultPorts = @{
        WordPress = 8080
        MySQL = 3306
        PHPMyAdmin = 8081
    }
    
    $ports = @{}
    $assignedPorts = @()  # Garder trace des ports déjà assignés
    
    foreach ($service in $defaultPorts.Keys) {
        $port = $defaultPorts[$service]
        $originalPort = $port
        
        # Vérifier que le port n'est pas déjà utilisé ET pas déjà assigné à un autre service
        $attempts = 0
        $maxAttempts = 100
        
        while ((!(Test-PortAvailableForProject -Port $port -ProjectName $ProjectName) -or ($assignedPorts -contains $port)) -and $attempts -lt $maxAttempts) {
            if ($assignedPorts -contains $port) {
                Write-Warning "Port $port ($service) déjà assigné à un autre service"
            } else {
                Write-Warning "Port $port ($service) déjà utilisé"
            }
            $port++
            $attempts++
        }
        
        if ($attempts -ge $maxAttempts) {
            Write-Error "Impossible de trouver un port disponible pour $service après $maxAttempts tentatives"
            throw "Port assignment failed for $service"
        }
        
        $ports[$service] = $port
        $assignedPorts += $port  # Ajouter le port à la liste des ports assignés
        
        if ($port -ne $originalPort) {
            Write-Info "$service - Port $originalPort → $port (nouveau)"
        } else {
            Write-Success "$service - Port $port (nouveau)"
        }
    }
    
    # 3. Sauvegarder les ports pour ce projet
    Save-ProjectPorts -ProjectName $ProjectName -Ports $ports
    Write-Info "💾 Ports sauvegardés pour le projet '$ProjectName'"
    
    return $ports
}

function Stop-ProjectContainers {
    param(
        [string]$ProjectName
    )
    
    Write-Info "🛑 Arrêt des conteneurs du projet '$ProjectName' seulement..."
    
    try {
        # Trouver SEULEMENT les conteneurs de ce projet spécifique
        $projectContainers = docker ps --format "{{.Names}}" --filter "name=^${ProjectName}_" 2>$null
        
        if ($projectContainers) {
            foreach ($container in $projectContainers) {
                if ($container.Trim() -ne "") {
                    Write-Info "Arrêt du conteneur du projet: $container"
                    docker stop $container 2>$null | Out-Null
                    # Ne PAS supprimer les conteneurs, juste les arrêter
                }
            }
            Write-Success "Conteneurs du projet '$ProjectName' arrêtés (conservés pour réutilisation)"
        } else {
            Write-Info "Aucun conteneur du projet '$ProjectName' en cours d'exécution"
        }
        
        # Attendre un peu que les ports se libèrent
        Start-Sleep -Seconds 2
        
    } catch {
        Write-Debug "Erreur lors de l'arrêt des conteneurs du projet: $($_.Exception.Message)"
    }
}

function New-DesktopShortcut {
    param(
        [string]$WorkspacePath,
        [string]$ProjectName
    )
    
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = "$desktopPath\$ProjectName.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "code"
        $shortcut.Arguments = "`"$WorkspacePath`""
        $shortcut.WorkingDirectory = Split-Path $WorkspacePath -Parent
        $shortcut.Description = "Ouvrir le projet WordPress $ProjectName dans Visual Studio Code"
        $shortcut.Save()
        
        Write-Success "Raccourci créé sur le bureau"
    } catch {
        Write-Warning "Impossible de créer le raccourci sur le bureau"
    }
}

function New-SystemInfoFile {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [hashtable]$Ports,
        [hashtable]$Versions,
        [hashtable]$Config
    )
    
    $systemInfo = @"
# 📊 INFORMATIONS SYSTÈME - $ProjectName

**Date de création** - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Créé avec** - WordPress Pro Setup  
**Développeur** - Paul CORNILLAD  
**LinkedIn** - https://www.linkedin.com/in/paul-cornillad/

## 🌐 Accès aux Services

### 🚀 WordPress
- **URL Site** - http://localhost:$($Ports.WordPress)
- **URL Admin** - http://localhost:$($Ports.WordPress)/wp-admin
- **Utilisateur** - ``admin``
- **Mot de passe** - ``admin123``
- **Email** - ``admin@localhost.local``

### 🗃️ Base de Données (MySQL)
- **Host** - ``localhost:$($Ports.MySQL)``
- **Nom BDD** - ``wordpress_db``
- **Utilisateur** - ``wordpress``
- **Mot de passe** - ``wordpress_password``
- **Root password** - ``root_password``

### 🔧 phpMyAdmin
- **URL** - http://localhost:$($Ports.PHPMyAdmin)
- **Utilisateur** - ``wordpress``
- **Mot de passe** - ``wordpress_password``

## 📁 Structure des Fichiers

``````
$ProjectName/
├── 📁 wordpress/           # Fichiers WordPress (thèmes, plugins, uploads)
├── 📁 mysql/              # Base de données MySQL (persistante)
├── 🐳 docker-compose.yml  # Configuration des conteneurs
├── 💼 $ProjectName.code-workspace  # Workspace Visual Studio Code
└── 📊 SYSTEM-INFO.md      # Ce fichier
``````

## 🔌 Plugins Installés par Défaut

- **Query Monitor** - Plugin de débogage et optimisation WordPress
  - Accessible via la barre d'administration WordPress
  - Affiche les requêtes SQL, hooks, temps de chargement, etc.

## 🛠️ Commandes Utiles

### 🐳 Gestion Docker
``````bash
# Démarrer tous les services
docker-compose up -d

# Arrêter tous les services
docker-compose down

# Voir les logs en temps réel
docker-compose logs -f

# Redémarrer un service spécifique
docker-compose restart wordpress

# Voir le statut des conteneurs
docker-compose ps
``````

### 🔧 WP-CLI (WordPress Command Line)
``````bash
# Accéder au terminal WP-CLI
docker-compose exec wp-cli bash

# Installer un plugin
docker-compose exec wp-cli wp plugin install contact-form-7 --activate

# Mettre à jour WordPress
docker-compose exec wp-cli wp core update

# Créer un utilisateur
docker-compose exec wp-cli wp user create john john@example.com --role=editor

# Exporter la base de données
docker-compose exec wp-cli wp db export backup.sql

# Importer une base de données
docker-compose exec wp-cli wp db import backup.sql

# Changer la langue
docker-compose exec wp-cli wp language core install fr_FR --activate
``````

### 📏 PHP CodeSniffer (Standards WordPress)
``````bash
# Vérifier un fichier PHP
phpcs --standard=WordPress path/to/file.php

# Vérifier tout le thème
phpcs --standard=WordPress wordpress/wp-content/themes/

# Corriger automatiquement les erreurs
phpcbf --standard=WordPress path/to/file.php
``````

## 🔒 Sécurité et Recommandations

### 🛡️ Recommandations
- ⚠️ **Mots de passe par défaut** - Changez les mots de passe en production
- 🔐 **Accès réseau** - Ces services ne sont accessibles qu'en local
- 📝 **Logs** - Surveillez les logs pour détecter les problèmes
- 🔍 **Query Monitor** - Utilisez le plugin pour optimiser les performances

### 🔄 Sauvegarde
``````bash
# Sauvegarde complète du projet
docker-compose exec wp-cli wp db export /var/www/html/backup-`$(Get-Date -Format "yyyyMMdd").sql

# Sauvegarde des fichiers WordPress
tar -czf ${ProjectName}-backup-`$(Get-Date -Format "yyyyMMdd").tar.gz wordpress/
``````

## 📝 Notes

- **Date de création** - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Créé avec** - WordPress Pro Setup
- **Développeur** - Paul CORNILLAD
- **Configuration** - Langue: $($Config.WordPressLanguage)

## 🆘 Dépannage

### 🚨 Problèmes courants
1. **Port déjà utilisé** - Modifiez les ports dans docker-compose.yml
2. **Docker non démarré** - Lancez Docker Desktop
3. **Permission denied** - Exécutez en tant qu'administrateur
4. **Site inaccessible** - Attendez 1-2 minutes après le démarrage
5. **Extensions Visual Studio Code** - Vérifiez que toutes les extensions sont installées
6. **WordPress en anglais** - Allez dans Réglages > Général > Langue

### 📞 Support
- Vérifiez les logs - ``docker-compose logs``
- Redémarrez les services - ``docker-compose restart``
- Supprimez et recréez - ``docker-compose down && docker-compose up -d``

---
*Généré automatiquement par WordPress Pro Setup*  
*Développé par Paul CORNILLAD - https://www.linkedin.com/in/paul-cornillad/*
"@

    $systemInfo | Out-File -FilePath "$ProjectPath\SYSTEM-INFO.md" -Encoding UTF8
    Write-Success "Fichier SYSTEM-INFO.md créé avec toutes les informations système"
}

function New-ProjectFiles {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [hashtable]$Ports,
        [hashtable]$Versions,
        [hashtable]$Config
    )
    
    # Docker Compose avec versions personnalisées
    $dockerCompose = @"
services:
  wordpress:
    image: wordpress:php$($Versions.PHP)-apache
    container_name: ${ProjectName}_wordpress
    restart: unless-stopped
    ports:
      - "$($Ports.WordPress):80"
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress_db
      WORDPRESS_DEBUG: 1
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_DEBUG', true);
        define('WP_DEBUG_LOG', true);
        define('WP_DEBUG_DISPLAY', false);
        define('SCRIPT_DEBUG', true);
    volumes:
      - ./wordpress:/var/www/html
    depends_on:
      - mysql
    networks:
      - wordpress_network

  mysql:
    image: mysql:$($Versions.MySQL)
    container_name: ${ProjectName}_mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress_db
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
$(if($Versions.MySQL -eq "8.0"){"      MYSQL_AUTHENTICATION_PLUGIN: mysql_native_password"})
    volumes:
      - ./mysql:/var/lib/mysql
    ports:
      - "$($Ports.MySQL):3306"
    networks:
      - wordpress_network
    command: --default-authentication-plugin=mysql_native_password

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: ${ProjectName}_phpmyadmin
    restart: unless-stopped
    ports:
      - "$($Ports.PHPMyAdmin):80"
    environment:
      PMA_HOST: mysql
      PMA_USER: wordpress
      PMA_PASSWORD: wordpress_password
      PMA_ARBITRARY: 1
    depends_on:
      - mysql
    networks:
      - wordpress_network

  wp-cli:
    image: wordpress:cli-php$($Versions.PHP)
    container_name: ${ProjectName}_wpcli
    user: "33:33"
    volumes:
      - ./wordpress:/var/www/html
    environment:
      WORDPRESS_DB_HOST: mysql
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress_db
    depends_on:
      - mysql
      - wordpress
    networks:
      - wordpress_network
    command: tail -f /dev/null

networks:
  wordpress_network:
    driver: bridge
"@

    # Visual Studio Code Workspace amélioré - Pointe vers le dossier WordPress
    $workspace = @"
{
    "folders": [
        {
            "name": "🚀 $ProjectName",
            "path": "./wordpress"
        }
    ],
    "settings": {
        "files.exclude": {
            "mysql/": true,
            "**/.DS_Store": true,
            "**/Thumbs.db": true,
            "**/.vscode/": false
        },
        "php.version": "$($Versions.PHP)",
        "intelephense.environment.phpVersion": "$($Versions.PHP)",
        "intelephense.files.exclude": [
            "**/.git/**",
            "**/node_modules/**",
            "**/vendor/**/{Tests,tests}/**",
            "mysql/**"
        ],
        "intelephense.stubs": [
            "apache",
            "bcmath",
            "bz2",
            "calendar",
            "com_dotnet",
            "Core",
            "ctype",
            "curl",
            "date",
            "dba",
            "dom",
            "enchant",
            "exif",
            "fileinfo",
            "filter",
            "ftp",
            "gd",
            "hash",
            "iconv",
            "imap",
            "interbase",
            "intl",
            "json",
            "ldap",
            "libxml",
            "mbstring",
            "mcrypt",
            "mssql",
            "mysql",
            "mysqli",
            "mysqlnd",
            "oci8",
            "odbc",
            "openssl",
            "pcntl",
            "pcre",
            "PDO",
            "pdo_ibm",
            "pdo_mysql",
            "pdo_pgsql",
            "pdo_sqlite",
            "pgsql",
            "Phar",
            "posix",
            "pspell",
            "readline",
            "recode",
            "Reflection",
            "regex",
            "session",
            "shmop",
            "SimpleXML",
            "snmp",
            "soap",
            "sockets",
            "sodium",
            "SPL",
            "sqlite3",
            "standard",
            "superglobals",
            "sybase",
            "sysvmsg",
            "sysvsem",
            "sysvshm",
            "tidy",
            "tokenizer",
            "wddx",
            "xml",
            "xmlreader",
            "xmlrpc",
            "xmlwriter",
            "xsl",
            "zip",
            "zlib",
            "wordpress"
        ],
        "phpcs.standard": "WordPress",
        "phpcs.enable": true,
        "phpcs.executablePath": "phpcs",
        "prettier.requireConfig": false,
        "prettier.disableLanguages": ["php"],
        "emmet.includeLanguages": {
            "php": "html"
        },
        "files.associations": {
            "*.php": "php"
        },
        "editor.tabSize": 4,
        "editor.insertSpaces": false,
        "editor.detectIndentation": true,
        "html.format.indentInnerHtml": true,
        "css.validate": true,
        "less.validate": true,
        "scss.validate": true,
        "[php]": {
            "editor.defaultFormatter": "bmewburn.vscode-intelephense-client",
            "editor.formatOnSave": true,
            "editor.tabSize": 4,
            "editor.insertSpaces": false
        },
        "[javascript]": {
            "editor.defaultFormatter": "esbenp.prettier-vscode",
            "editor.formatOnSave": true,
            "editor.tabSize": 2,
            "editor.insertSpaces": true
        },
        "[css]": {
            "editor.defaultFormatter": "esbenp.prettier-vscode",
            "editor.formatOnSave": true,
            "editor.tabSize": 2,
            "editor.insertSpaces": true
        },
        "[scss]": {
            "editor.defaultFormatter": "esbenp.prettier-vscode",
            "editor.formatOnSave": true
        },
        "[html]": {
            "editor.defaultFormatter": "esbenp.prettier-vscode",
            "editor.formatOnSave": true
        },
        "[json]": {
            "editor.defaultFormatter": "esbenp.prettier-vscode",
            "editor.formatOnSave": true
        },
        "search.exclude": {
            "**/node_modules": true,
            "**/bower_components": true,
            "**/*.code-search": true,
            "mysql/**": true,
            "**/vendor/**": true
        }
    },
    "extensions": {
        "recommendations": [
            "ms-azuretools.vscode-docker",
            "bmewburn.vscode-intelephense-client",
            "wordpresstoolbox.wordpress-toolbox",
            "johnbillion.vscode-wordpress-hooks",
            "neilbrayfield.php-docblocker",
            "esbenp.prettier-vscode",
            "bradlc.vscode-tailwindcss",
            "formulahendry.auto-rename-tag",
            "christian-kohler.path-intellisense"
        ]
    },
    "tasks": {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "🚀 Démarrer WordPress",
                "type": "shell",
                "command": "docker-compose up -d",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🛑 Arrêter WordPress",
                "type": "shell",
                "command": "docker-compose down",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🔄 Redémarrer WordPress",
                "type": "shell",
                "command": "docker-compose restart wordpress",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "📋 Voir les logs WordPress",
                "type": "shell",
                "command": "docker-compose logs -f wordpress",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "📋 Voir tous les logs",
                "type": "shell",
                "command": "docker-compose logs -f",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "📊 État des conteneurs",
                "type": "shell",
                "command": "docker-compose ps",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🔧 Terminal WP-CLI",
                "type": "shell",
                "command": "docker-compose exec wp-cli bash",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": true,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "📏 Vérifier code PHP (PHPCS)",
                "type": "shell",
                "command": "docker-compose exec wp-cli phpcs --standard=WordPress /var/www/html/wp-content/themes/ --extensions=php",
                "group": "test",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🔧 Corriger code PHP (PHPCBF)",
                "type": "shell",
                "command": "docker-compose exec wp-cli phpcbf --standard=WordPress /var/www/html/wp-content/themes/ --extensions=php",
                "group": "test",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "📦 Sauvegarder base de données",
                "type": "shell",
                "command": "docker-compose exec wp-cli wp db export /var/www/html/backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').sql",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🔄 Mettre à jour WordPress",
                "type": "shell",
                "command": "docker-compose exec wp-cli wp core update",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🔌 Lister les plugins",
                "type": "shell",
                "command": "docker-compose exec wp-cli wp plugin list",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🎨 Lister les thèmes",
                "type": "shell",
                "command": "docker-compose exec wp-cli wp theme list",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            },
            {
                "label": "🧹 Nettoyer cache WordPress",
                "type": "shell",
                "command": "docker-compose exec wp-cli wp cache flush",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                },
                "problemMatcher": []
            }
        ]
    }
}
"@

    # Écrire tous les fichiers
    $dockerCompose | Out-File -FilePath "$ProjectPath\docker-compose.yml" -Encoding UTF8
    $workspacePath = "$ProjectPath\$ProjectName.code-workspace"
    $workspace | Out-File -FilePath $workspacePath -Encoding UTF8

    Write-Success "Fichiers de configuration créés"

    return $workspacePath
}

function New-WordPressProject {
    # Étape 1: Vérification complète des prérequis
    Write-Header "🔍 VERIFICATION COMPLETE" "🔍"
    if (!(Test-CompleteCheck)) {
        Write-Error "Certains prérequis ne sont pas satisfaits."
        Write-Info "Corrigez les problèmes et relancez le script."
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour retourner au menu..."
        Read-Host
        return
    }
    
    # Charger la configuration
    $config = Get-Configuration
    
    # Obtenir le nom du projet
    $projectName = Get-ProjectName
    
    # Sélectionner les versions
    $versions = Select-Versions
    
    # Obtenir les ports disponibles
    $ports = Get-SmartPorts -ProjectName $projectName
    
    Write-Header "CRÉATION DU PROJET" "🏗️"
    
    # Créer la structure
    $projectPath = "C:\dev\wordpress-projects\$projectName"
    
    Write-Info "Création de la structure des dossiers..."
    if (!(Test-Path "C:\dev")) {
        New-Item -ItemType Directory -Path "C:\dev" -Force | Out-Null
    }
    if (!(Test-Path "C:\dev\wordpress-projects")) {
        New-Item -ItemType Directory -Path "C:\dev\wordpress-projects" -Force | Out-Null
    }
    
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    New-Item -ItemType Directory -Path "$projectPath\wordpress" -Force | Out-Null
    New-Item -ItemType Directory -Path "$projectPath\mysql" -Force | Out-Null
    
    # Créer tous les fichiers
    Write-Info "Génération des fichiers de configuration..."
    $workspacePath = New-ProjectFiles -ProjectPath $projectPath -ProjectName $projectName -Ports $ports -Versions $versions -Config $config
    
    # Créer le fichier d'informations système
    Write-Info "Création du fichier SYSTEM-INFO.md..."
    New-SystemInfoFile -ProjectPath $projectPath -ProjectName $projectName -Ports $ports -Versions $versions -Config $config
    
    # Créer le raccourci sur le bureau
    Write-Info "Création du raccourci sur le bureau..."
    New-DesktopShortcut -WorkspacePath $workspacePath -ProjectName $projectName
    
    # Améliorations VS Code
    Write-Info "Configuration avancée de VS Code..."
    Add-VSCodeSnippets -ProjectPath $projectPath
    
    # Validation Docker Compose
    Write-Info "Validation de la configuration Docker..."
    Test-DockerCompose -ProjectPath $projectPath | Out-Null
    
    # Extensions optionnelles VS Code
    if (Test-ToolInstalled -Command "code") {
        Write-Box "🔌 EXTENSIONS VISUAL STUDIO CODE OPTIONNELLES" $Global:Colors.Yellow
        $installOptional = Read-Host "Voulez-vous installer des extensions Visual Studio Code optionnelles ? (o/n)"
        if ($installOptional -match "^[oOyY]") {
            Install-OptionalVSCodeExtensions -ProjectPath $projectPath
        }
    }
    
    # Succès de création
    Write-Header "PROJET CRÉÉ AVEC SUCCÈS!" "✅"
    
    Write-Success "Projet : $projectName"
    Write-Info "Emplacement : $projectPath"
    Write-Info "Versions : PHP $($versions.PHP) • WordPress $($versions.WordPress) • MySQL $($versions.MySQL)"
    Write-Info "Langue : $($config.WordPressLanguage)"
    Write-Info "Ports : WordPress $($ports.WordPress) • phpMyAdmin $($ports.PHPMyAdmin) • MySQL $($ports.MySQL)"
    Write-Success "Raccourci créé sur le bureau : $projectName.lnk"
    Write-Host ""
    
    # Démarrage automatique de l'environnement
    Write-Box "🚀 DÉMARRAGE AUTOMATIQUE" $Global:Colors.Yellow
    Write-Info "Démarrage automatique de l'environnement..."
    Write-Host ""
    
    # Vérifier Docker une dernière fois
    $dockerStatus = Test-DockerStatus
    if ($dockerStatus.Status -ne "Running") {
        Write-Error "Docker n'est pas opérationnel. Veuillez démarrer Docker Desktop."
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour continuer..."
        Read-Host
        return
    }
    
    Write-Info "Démarrage de l'environnement..."
    Set-Location $projectPath
    
    # Arrêt des conteneurs du projet uniquement (conserve les autres)
    Stop-ProjectContainers -ProjectName $projectName
    
    # Démarrer les conteneurs
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Conteneurs démarrés !"
        Write-Info "Attente de la disponibilité de MySQL..."
        
        # Attendre que MySQL soit disponible
        $maxAttempts = 30
        $attempt = 0
        $mysqlReady = $false
        
        while ($attempt -lt $maxAttempts -and -not $mysqlReady) {
            $attempt++
            Write-Host "." -NoNewline
            
            $result = docker-compose exec -T mysql mysql -u wordpress -pwordpress_password -e "SELECT 1" 2>$null
            if ($LASTEXITCODE -eq 0) {
                $mysqlReady = $true
                Write-Host ""
                Write-Success "MySQL est maintenant disponible!"
            } else {
                Start-Sleep -Seconds 2
            }
        }
        
        if (-not $mysqlReady) {
            Write-Error "Impossible de se connecter à MySQL après $($maxAttempts * 2) secondes"
            return
        }
        
        # Configuration WordPress
        if ($versions.WordPress -eq "latest") {
            docker-compose exec -T wp-cli wp core download --force 2>$null
        } else {
            docker-compose exec -T wp-cli wp core download --version=$($versions.WordPress) --force 2>$null
        }
        
        docker-compose exec -T wp-cli wp config create --dbname=wordpress_db --dbuser=wordpress --dbpass=wordpress_password --dbhost=mysql --force 2>$null
        docker-compose exec -T wp-cli wp core install --url="localhost:$($ports.WordPress)" --title="$projectName" --admin_user=admin --admin_password=admin123 --admin_email=admin@localhost.local 2>$null
        
        # Configuration langue française
        Write-Info "Configuration de la langue française..."
        docker-compose exec -T wp-cli wp language core install $config.WordPressLanguage --activate 2>$null
        docker-compose exec -T wp-cli wp option update WPLANG $config.WordPressLanguage 2>$null
        
        # Supprimer plugins par défaut
        Write-Info "Suppression des plugins par défaut..."
        docker-compose exec -T wp-cli wp plugin delete hello 2>$null
        docker-compose exec -T wp-cli wp plugin delete akismet 2>$null
        
        # Installer Query Monitor
        Write-Info "Installation de Query Monitor..."
        docker-compose exec -T wp-cli wp plugin install query-monitor --activate 2>$null
        
        # Supprimer le fichier wp-config-docker.php inutile
        Write-Info "Suppression du fichier wp-config-docker.php..."
        docker-compose exec -T wp-cli rm -f /var/www/html/wp-config-docker.php 2>$null
        
        # Installer thème et autres plugins
        if ($config.DefaultTheme -ne "twentytwentyfour") {
            docker-compose exec -T wp-cli wp theme install $config.DefaultTheme --activate 2>$null
        }
        
        foreach ($plugin in $config.DefaultPlugins) {
            if ($plugin -ne "query-monitor") {
                docker-compose exec -T wp-cli wp plugin install $plugin --activate 2>$null
            }
        }
        
        Write-Header "ENVIRONNEMENT PRÊT!" "🎉"
        
        Write-ColorText "🌐 ACCÈS AU SITE :" $Global:Colors.Yellow
        Write-Host "   WordPress : http://localhost:$($ports.WordPress)"
        Write-Host "   Admin : http://localhost:$($ports.WordPress)/wp-admin"
        Write-Host "   phpMyAdmin : http://localhost:$($ports.PHPMyAdmin)"
        Write-Host ""
        Write-ColorText "🔐 CONNEXION :" $Global:Colors.Yellow
        Write-Host "   Utilisateur : admin"
        Write-Host "   Mot de passe : admin123" -ForegroundColor White
        Write-Host ""
        
        Write-ColorText "📁 FICHIERS UTILES :" $Global:Colors.Yellow
        Write-Host "   Raccourci Bureau : $projectName.lnk"
        Write-Host "   Workspace Visual Studio Code : $workspacePath"
        Write-Host "   Documentation : $projectPath\SYSTEM-INFO.md"
        Write-Host ""
        
        # Proposer d'ouvrir Visual Studio Code
        $openVSCode = Read-Host "Ouvrir Visual Studio Code maintenant ? (o/n)"
        if ($openVSCode -match "^[oOyY]") {
            if (Test-ToolInstalled -Command "code") {
                Write-Success "Ouverture de Visual Studio Code..."
                Start-Process "code" -ArgumentList "`"$workspacePath`""
                Write-Host ""
                Write-Host "Appuyez sur Entrée pour quitter le script..."
                Read-Host
                exit 0
            } else {
                Write-Warning "Visual Studio Code non trouvé, ouverture du dossier..."
                Start-Process "explorer.exe" -ArgumentList $projectPath
            }
        } else {
            Write-Host ""
            Write-ColorText "📋 PROCHAINES ÉTAPES :" $Global:Colors.Yellow
            Write-Host "1. Double-cliquer sur le raccourci du bureau : $projectName.lnk"
            Write-Host "2. Ou double-cliquez sur : $workspacePath"
            Write-Host "3. Consulter : $projectPath\SYSTEM-INFO.md"
            Write-Host "4. Aller sur : http://localhost:$($ports.WordPress)"
            Write-Host ""
            
            $openFolder = Read-Host "Ouvrir le dossier du projet maintenant ? (o/n)"
            if ($openFolder -match "^[oOyY]") {
                Start-Process "explorer.exe" -ArgumentList $projectPath
            }
        }
    } else {
        Write-Error "Erreur lors du démarrage des conteneurs"
    }
}

# ============================================================================
# 🔧 FONCTIONS D'AMÉLIORATION VS CODE
# ============================================================================

function Install-OptionalVSCodeExtensions {
    param([string]$ProjectPath)
    
    Write-Info "Extensions VS Code optionnelles disponibles..."
    Write-Host ""
    
    $optionalExtensions = @(
        @{Id="streetsidesoftware.code-spell-checker"; Name="Code Spell Checker"; Description="Vérificateur d'orthographe"},
        @{Id="ms-vscode.hexeditor"; Name="Hex Editor"; Description="Éditeur hexadécimal"},
        @{Id="pkief.material-icon-theme"; Name="Material Icon Theme"; Description="Thème d'icônes Material"}
    )
    
    foreach ($ext in $optionalExtensions) {
        if (!(Test-VSCodeExtension -ExtensionId $ext.Id)) {
            Write-Host "  📦 $($ext.Name) - $($ext.Description)" -ForegroundColor Gray
            $install = Read-Host "    Installer ? (o/n)"
            if ($install -match "^[oOyY]") {
                if (Install-VSCodeExtension -ExtensionId $ext.Id) {
                    Write-Success "    $($ext.Name) installée"
                } else {
                    Write-Warning "    Impossible d'installer $($ext.Name)"
                }
            }
        } else {
            Write-Success "  $($ext.Name) déjà installée"
        }
    }
    Write-Host ""
}

function Test-DockerCompose {
    param([string]$ProjectPath)
    
    Write-Info "Validation de la configuration Docker Compose..."
    
    try {
        $currentLocation = Get-Location
        Set-Location $ProjectPath
        $result = docker-compose config --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Configuration Docker Compose valide"
            Set-Location $currentLocation
            return $true
        } else {
            Write-Error "Erreur dans docker-compose.yml: $result"
            Set-Location $currentLocation
            return $false
        }
    } catch {
        Write-Error "Impossible de valider Docker Compose: $($_.Exception.Message)"
        if ($currentLocation) { Set-Location $currentLocation }
        return $false
    }
}

function Add-VSCodeSnippets {
    param([string]$ProjectPath)
    
    Write-Info "Création des snippets VS Code pour WordPress..."
    
    $vscodeDir = "$ProjectPath\.vscode"
    if (!(Test-Path $vscodeDir)) {
        New-Item -Path $vscodeDir -ItemType Directory -Force | Out-Null
    }
    
    $snippetsContent = @"
{
    "WordPress Hook": {
        "prefix": "wphook",
        "body": [
            "add_action( '\`${1:hook_name}', '\`${2:function_name}' );"
        ],
        "description": "Ajouter un hook WordPress"
    },
    "WordPress Filter": {
        "prefix": "wpfilter",
        "body": [
            "add_filter( '\`${1:filter_name}', '\`${2:function_name}' );"
        ],
        "description": "Ajouter un filtre WordPress"
    },
    "WordPress Function": {
        "prefix": "wpfunc",
        "body": [
            "function \`${1:function_name}() {",
            "\t\`${2:// Code here}",
            "}"
        ],
        "description": "Fonction WordPress standard"
    },
    "WordPress Enqueue Script": {
               "prefix": "wpenqueue",
        "body": [
            "wp_enqueue_script( '\`${1:handle}', get_template_directory_uri() . '/\`${2:path}', array(\`${3:'jquery'}), '\`${4:1.0}', \`${5:true} );"
        ],
        "description": "Enregistrer un script WordPress"
    },
    "WordPress Enqueue Style": {
        "prefix": "wpstyle",
        "body": [
            "wp_enqueue_style( '\`${1:handle}', get_template_directory_uri() . '/\`${2:path}', array(), '\`${3:1.0}' );"
        ],
        "description": "Enregistrer un style WordPress"
    }
}
"@

    $snippetsContent | Out-File -FilePath "$vscodeDir\php.json" -Encoding UTF8
    Write-Success "Snippets WordPress créés dans .vscode/php.json"
}

function Test-WordPressVersion {
    param([string]$Version)
    
    if ($Version -eq "latest") {
        return $true
    }
    
    if ($Version -match "^\d+\.\d+(\.\d+)?$") {
        return $true
    }
    
    return $false
}

# ============================================================================
# 📋 MENU AND USER INTERFACE FUNCTIONS
# ============================================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
    Displays the main menu and returns the user's choice.
    
    .DESCRIPTION
    Shows the main menu interface with all available options and validates user input.
    
    .EXAMPLE
    $choice = Show-MainMenu
    #>
    
    Write-Header "WORDPRESS PRO SETUP" "🚀"
    
    Write-ColorText "╭──────────────────────────────────────────────╮" $Global:Colors.Yellow
    Write-ColorText "│                                              │" $Global:Colors.Yellow
    Write-ColorText "│  Que voulez-vous faire ?                     │" $Global:Colors.Yellow
    Write-ColorText "│                                              │" $Global:Colors.Yellow
    Write-ColorText "│  1. Créer un nouveau projet WordPress        │" $Global:Colors.Yellow
    Write-ColorText "│  2. Lister mes projets existants             │" $Global:Colors.Yellow
    Write-ColorText "│  3. Vérifier les outils installés            │" $Global:Colors.Yellow
    Write-ColorText "│  4. Gestion des ports intelligents           │" $Global:Colors.Yellow
    Write-ColorText "│  5. Aide et documentation                    │" $Global:Colors.Yellow
    Write-ColorText "│  0. Quitter                                  │" $Global:Colors.Yellow
    Write-ColorText "│                                              │" $Global:Colors.Yellow
    Write-ColorText "╰──────────────────────────────────────────────╯" $Global:Colors.Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "👉 Votre choix (0-5)"
        if ($choice -match "^[0-5]$") {
            return [int]$choice
        }
        Write-Error "Choix invalide. Entrez un numéro entre 0 et 5."
    } while ($true)
}

function Show-ExistingProjects {
    <#
    .SYNOPSIS
    Lists all existing WordPress projects and allows selection.
    
    .DESCRIPTION
    Scans the projects directory and displays all WordPress projects with their status.
    
    .EXAMPLE
    Show-ExistingProjects
    #>
    
    Write-Header "PROJETS WORDPRESS EXISTANTS" "📁"
    
    $projectsPath = "C:\dev\wordpress-projects"
    
    if (!(Test-Path $projectsPath)) {
        Write-Warning "Aucun projet trouvé."
        Write-Info "Le dossier $projectsPath n'existe pas encore."
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour continuer..."
        Read-Host
        return
    }
    
    $projects = Get-ChildItem -Path $projectsPath -Directory -ErrorAction SilentlyContinue
    
    if ($projects.Count -eq 0) {
        Write-Warning "Aucun projet WordPress trouvé."
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour continuer..."
        Read-Host
        return
    }
    
    Write-Success "Projets trouvés :"
    Write-Host ""
    
    # Display projects with status
    for ($i = 0; $i -lt $projects.Count; $i++) {
        $project = $projects[$i]
        $status = Get-ProjectStatus -ProjectPath $project.FullName
        
        $projectLine = "$($i + 1). 📂 $($project.Name)"
        Write-Host $projectLine.PadRight(30) -NoNewline
        
        if ($status.IsComplete) {
            Write-ColorText " ✅ COMPLET" $Global:Colors.Green
        } else {
            Write-ColorText " ❌ INCOMPLET" $Global:Colors.Red
        }
    }
    
    Write-Host ""
    Write-ColorText "📋 Actions disponibles:" $Global:Colors.Cyan
    Write-Host "  • Entrez un numéro pour ouvrir le projet"
    Write-Host "  • Tapez 'menu' pour retourner au menu principal"
    Write-Host ""
    
    do {
        $choice = Read-Host "👉 Votre choix"
        
        if ($choice -eq "menu") {
            return
        }
        
        if ($choice -match "^\d+$") {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $projects.Count) {
                $selectedProject = $projects[$index]
                Write-Success "Ouverture du projet - $($selectedProject.Name)"
                Start-Process "explorer.exe" -ArgumentList $selectedProject.FullName
                Write-Host "Appuyez sur Entrée pour continuer..."
                Read-Host
                return
            }
        }
        
        Write-Error "Choix invalide."
    } while ($true)
}

function Get-ProjectStatus {
    <#
    .SYNOPSIS
    Evaluates the completeness status of a WordPress project.
    
    .PARAMETER ProjectPath
    The path to the project to evaluate.
    
    .EXAMPLE
    $status = Get-ProjectStatus -ProjectPath "C:\dev\wordpress-projects\myproject"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )
    
    $requiredFiles = @(
        "docker-compose.yml",
        "SYSTEM-INFO.md"
    )
    
    $requiredDirectories = @(
        "wordpress",
        "mysql"
    )
    
    $hasWorkspace = (Get-ChildItem -Path $ProjectPath -Filter "*.code-workspace" -ErrorAction SilentlyContinue).Count -gt 0
    
    $allRequiredFilesExist = $requiredFiles | ForEach-Object {
        Test-Path (Join-Path $ProjectPath $_)
    } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
    
    $allRequiredDirsExist = $requiredDirectories | ForEach-Object {
        Test-Path (Join-Path $ProjectPath $_)
    } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
    
    $isComplete = ($allRequiredFilesExist -eq 0) -and ($allRequiredDirsExist -eq 0) -and $hasWorkspace
    
    return @{
        IsComplete = $isComplete
        HasWorkspace = $hasWorkspace
        MissingFiles = $allRequiredFilesExist
        MissingDirectories = $allRequiredDirsExist
    }
}

function Show-ToolsStatus {
    Write-Header "VERIFICATION DES OUTILS" "🔧"
    
    Write-ColorText "📊 Outils requis :" $Global:Colors.Yellow
    Write-Host ""
    
    $tools = @(
        @{Name = "Chocolatey"; Command = "choco"; Icon = "•"},
        @{Name = "Git"; Command = "git"; Icon = "•"},
        @{Name = "Node.js"; Command = "node"; Icon = "•"},
        @{Name = "Composer"; Command = "composer"; Icon = "•"},
        @{Name = "Docker"; Command = "docker"; Icon = "•"},
        @{Name = "Visual Studio Code"; Command = "code"; Icon = "•"},
        @{Name = "PHP CodeSniffer"; Command = "phpcs"; Icon = "•"}
    )
    
    $missingTools = @()
    $installedTools = @()
    
    foreach ($tool in $tools) {
        if ($tool.Command -eq "phpcs") {
            # Test spécial pour PHP CodeSniffer
            $installed = Test-ComposerPackage -PackageName "squizlabs/php_codesniffer"
        } else {
            $installed = Test-ToolInstalled -Command $tool.Command
        }
        
        Write-Host "  $($tool.Icon) $($tool.Name)".PadRight(30) -NoNewline
        if ($installed) {
            if ($tool.Command -eq "phpcs") {
                Write-Host "INSTALLÉ" -ForegroundColor $Global:Colors.Green
            } else {
                $version = Get-ToolVersion -Command $tool.Command
                Write-Host "INSTALLÉ" -ForegroundColor $Global:Colors.Green -NoNewline
                Write-Host " (v$version)" -ForegroundColor Gray
            }
            $installedTools += $tool
        } else {
            Write-Host "MANQUANT" -ForegroundColor $Global:Colors.Red
            $missingTools += $tool
        }
    }
    
    Write-Host ""
    
    # Test spécial Docker
    if (Test-ToolInstalled -Command "docker") {
        $dockerStatus = Test-DockerStatus
        Write-Host "🐳 Docker Desktop :".PadRight(30) -NoNewline -ForegroundColor $Global:Colors.Yellow
        switch ($dockerStatus.Status) {
            "Running" { Write-ColorText "OPÉRATIONNEL" $Global:Colors.Green }
            "NotRunning" { Write-ColorText "NON DÉMARRÉ" $Global:Colors.Yellow }
            "Error" { Write-ColorText "KO" $Global:Colors.Red }
        }
    }
    
    Write-Host ""
    
    # Test extensions Visual Studio Code
    if (Test-ToolInstalled -Command "code") {
        Write-ColorText "🔌 Extensions Visual Studio Code :" $Global:Colors.Yellow
        Write-Host ""
        $missingExtensions = @()
        foreach ($extension in $Global:RequiredVSCodeExtensions) {
            $installed = Test-VSCodeExtension -ExtensionId $extension
            $friendlyName = switch ($extension) {
                "ms-azuretools.vscode-docker" { "• Docker" }
                "bmewburn.vscode-intelephense-client" { "• PHP IntelliSense" }
                "christian-kohler.path-intellisense" { "• Path Intellisense" }
                "wordpresstoolbox.wordpress-toolbox" { "• WordPress Toolbox" }
                "johnbillion.vscode-wordpress-hooks" { "• WordPress Hooks" }
                "neilbrayfield.php-docblocker" { "• PHP DocBlocker" }
                "esbenp.prettier-vscode" { "• Prettier" }
                "bradlc.vscode-tailwindcss" { "• Tailwind CSS IntelliSense" }
                "formulahendry.auto-rename-tag" { "• Auto Rename Tag" }
                default { $extension }
            }
            
            Write-Host "  $friendlyName".PadRight(30) -NoNewline
            if ($installed) {
                Write-ColorText "INSTALLÉ" $Global:Colors.Green
            } else {
                Write-ColorText "MANQUANT" $Global:Colors.Red
                $missingExtensions += @{Name=$friendlyName; Id=$extension}
            }
        }
        
        # Proposer d'installer les extensions manquantes
        if ($missingExtensions.Count -gt 0) {
            Write-Host ""
            Write-Warning "Extensions Visual Studio Code manquantes détectées!"
            $installExtensions = Read-Host "Voulez-vous installer les extensions manquantes maintenant ? (o/n)"
            if ($installExtensions -match "^[oOyY]") {
                Write-Info "Installation des extensions Visual Studio Code en cours..."
                foreach ($ext in $missingExtensions) {
                    Write-Host "  Installation de $($ext.Name)..." -NoNewline
                    if (Install-VSCodeExtension -ExtensionId $ext.Id) {
                        Write-ColorText " ✅" $Global:Colors.Green
                    } else {
                        Write-ColorText " ❌" $Global:Colors.Red
                    }
                }
                Write-Success "Installation des extensions terminée!"
            }
        }
    }
    
    Write-Host ""
    
    # Proposer l'installation des outils manquants
    if ($missingTools.Count -gt 0) {
        Write-Warning "Outils manquants: $($missingTools.Name -join ', ')"
        Write-Host ""
        $installMissing = Read-Host "Voulez-vous installer les outils manquants maintenant ? (o/n)"
        
        if ($installMissing -match "^[oOyY]") {
            Write-Header "🚀 INSTALLATION DES OUTILS MANQUANTS" "🚀"
            
            # Installer Chocolatey en premier si nécessaire
            $chocoMissing = $missingTools | Where-Object { $_.Command -eq "choco" }
            if ($chocoMissing) {
                Write-Info "Installation de Chocolatey (requis pour les autres outils)..."
                if (Install-Chocolatey) {
                    Write-Success "Chocolatey installé!"
                    # Recharger l'environnement
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                } else {
                    Write-Error "Échec de l'installation de Chocolatey. Installation annulée."
                    Write-Host "Appuyez sur Entrée pour continuer..."
                    Read-Host
                    return
                }
            }
            
            # Installer les autres outils
            foreach ($tool in $missingTools) {
                if ($tool.Command -eq "choco") {
                    # Chocolatey déjà installé plus haut
                    continue
                } elseif ($tool.Command -eq "phpcs") {
                    # PHP CodeSniffer nécessite Composer
                    if (Test-ToolInstalled -Command "composer") {
                        Write-Info "Installation de PHP CodeSniffer..."
                        Install-PHPCodeSniffer
                    } else {
                        Write-Warning "PHP CodeSniffer nécessite Composer. Installez Composer d'abord."
                    }
                } else {
                    $package = switch ($tool.Command) {
                        "git" { "git" }
                        "node" { "nodejs" }
                        "composer" { "composer" }
                        "docker" { "docker-desktop" }
                        "code" { "vscode" }
                        default { $tool.Command }
                    }
                    
                    Write-Info "Installation de $($tool.Name)..."
                    if (Install-Tool -ToolName $tool.Name -ChocoPackage $package) {
                        Write-Success "$($tool.Name) installé!"
                    } else {
                        Write-Error "Échec de l'installation de $($tool.Name)"
                    }
                }
            }
            
            Write-Success "Installation terminée!"
            Write-Info "Certains outils peuvent nécessiter un redémarrage pour être pleinement fonctionnels."
        }
    } else {
        Write-Success "Tous les outils requis sont installés!"
    }
    
    Write-Host ""
    Write-Host "Appuyez sur Entrée pour continuer..."
    Read-Host
}

function Show-Help {
    Write-Header "📚 AIDE ET DOCUMENTATION" "📚"
    
    Write-ColorText "🎯 FONCTIONNALITÉS PRINCIPALES :" $Global:Colors.Yellow
    Write-Host ""
    Write-Host "  ✅ Vérification complète des prérequis avant création"
    Write-Host "  ✅ Installation automatique des outils manquants"
    Write-Host "  ✅ Choix des versions PHP/WordPress/MySQL"
    Write-Host "  ✅ WordPress en français par défaut"
    Write-Host "  ✅ Query Monitor installé automatiquement"
    Write-Host "  ✅ Suppression des plugins indésirables (Hello Dolly, Akismet)"
    Write-Host "  ✅ Configuration PHPCS avec standards WordPress"
    Write-Host "  ✅ Extensions Visual Studio Code : Docker, PHP IntelliSense, WordPress Toolbox, WordPress Hooks, PHP DocBlocker, Prettier"
    Write-Host "  ✅ Raccourci sur le bureau pour démarrage rapide"
    Write-Host "  ✅ Documentation système complète (SYSTEM-INFO.md)"
    Write-Host "  ✅ Gestion automatique des ports (projets multiples)"
    Write-Host ""
    
    Write-ColorText "🛠️ EXTENSIONS VISUAL STUDIO CODE INSTALLÉES :" $Global:Colors.Yellow
    Write-Host "  🐳 Docker - Gestion des conteneurs et environnements"
    Write-Host "  🐘 PHP IntelliSense - Autocomplétion et analyse PHP avancée"
    Write-Host "  🌐 WordPress Toolbox - Outils spécialisés WordPress"
    Write-Host "  🔗 WordPress Hooks IntelliSense - IntelliSense pour hooks WordPress"
    Write-Host "  📝 PHP DocBlocker - Génération automatique de documentation PHP"
    Write-Host "  🎨 Prettier - Formatage automatique de code (JS, CSS, HTML)"
    Write-Host ""
    
    Write-ColorText "🔌 PLUGINS WORDPRESS :" $Global:Colors.Yellow
    Write-Host "  ✅ Query Monitor - Plugin de débogage et optimisation"
    Write-Host "  ❌ Hello Dolly - Supprimé automatiquement"
    Write-Host "  ❌ Akismet - Supprimé automatiquement"
    Write-Host ""
    
    Write-ColorText "🚀 UTILISATION RAPIDE :" $Global:Colors.Yellow
    Write-Host "  1. Créer un projet avec ce script"
    Write-Host "  2. Double-cliquez sur le raccourci du bureau"
    Write-Host "  3. Consulter SYSTEM-INFO.md pour tous les détails"
    Write-Host "  4. Commencer à développer !"
    Write-Host ""
    
    Write-Host "Appuyez sur Entrée pour continuer..."
    Read-Host
}

function Show-PortsMenu {
    Write-Header "GESTION DES PORTS INTELLIGENTS" "🔌"
    
    Write-ColorText "╭────────────────────────────────────────────╮" $Global:Colors.Yellow
    Write-ColorText "│                                            │" $Global:Colors.Yellow
    Write-ColorText "│  Gestion des ports intelligents            │" $Global:Colors.Yellow
    Write-ColorText "│                                            │" $Global:Colors.Yellow
    Write-ColorText "│  1. Afficher les ports des projets         │" $Global:Colors.Yellow
    Write-ColorText "│  2. Nettoyer les ports inutilisés          │" $Global:Colors.Yellow
    Write-ColorText "│  3. Statistiques des ports                 │" $Global:Colors.Yellow
    Write-ColorText "│  0. Retour au menu principal               │" $Global:Colors.Yellow
    Write-ColorText "│                                            │" $Global:Colors.Yellow
    Write-ColorText "╰────────────────────────────────────────────╯" $Global:Colors.Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "👉 Votre choix (0-3)"
        
        switch ($choice) {
            "1" { 
                Show-ProjectPorts
                Write-Host "Appuyez sur Entrée pour continuer..."
                Read-Host
            }
            "2" { 
                Remove-UnusedProjectPorts
                Write-Host "Appuyez sur Entrée pour continuer..."
                Read-Host
            }
            "3" { 
                Show-PortsStatistics
                Write-Host "Appuyez sur Entrée pour continuer..."
                Read-Host
            }
            "0" { return }
            default { Write-Error "Choix invalide. Entrez un numéro entre 0 et 3." }
        }
    } while ($true)
}

function Show-ProjectPorts {
    Write-Box "🔌 GESTION DES PORTS INTELLIGENTS" $Global:Colors.Yellow
    
    $portsDir = "$env:USERPROFILE\.wordpress-dev"
    if (-not (Test-Path $portsDir)) {
        Write-Warning "Aucun projet trouvé avec des ports sauvegardés."
        return
    }
    
    $portFiles = Get-ChildItem -Path $portsDir -Filter "*-ports.json" -ErrorAction SilentlyContinue
    if ($portFiles.Count -eq 0) {
        Write-Warning "Aucun projet avec ports sauvegardés trouvé."
        return
    }
    
    Write-Success "Projets avec ports fixes trouvés:"
    Write-Host ""
    
    foreach ($portFile in $portFiles) {
        try {
            $portsData = Get-Content -Path $portFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $projectName = $portsData.ProjectName
            $ports = $portsData.Ports
            $lastUsed = $portsData.LastUsed
            
            Write-ColorText "📂 $projectName" $Global:Colors.Cyan
            Write-Host "   🕐 Dernière utilisation : $lastUsed"
            foreach ($service in $ports.PSObject.Properties.Name) {
                $port = $ports.$service
                Write-Host "   • $service : $port"
            }
            Write-Host ""
        } catch {
            Write-Debug "Erreur lors de la lecture du fichier $($portFile.Name): $($_.Exception.Message)"
        }
    }
    
}

function Remove-UnusedProjectPorts {
    Write-Box "🧹 NETTOYAGE DES PORTS INUTILISÉS" $Global:Colors.Yellow
    
    $portsDir = "$env:USERPROFILE\.wordpress-dev"
    if (-not (Test-Path $portsDir)) {
        Write-Info "Aucun fichier de ports à nettoyer."
        return
    }
    
    $portFiles = Get-ChildItem -Path $portsDir -Filter "*-ports.json" -ErrorAction SilentlyContinue
    if ($portFiles.Count -eq 0) {
        Write-Info "Aucun fichier de ports à nettoyer."
        return
    }
    
    $projectsToDelete = @()
    
    foreach ($portFile in $portFiles) {
        try {
            $portsData = Get-Content -Path $portFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $projectName = $portsData.ProjectName
            $projectPath = "C:\dev\wordpress-projects\$projectName"
            
            if (-not (Test-Path $projectPath)) {
                $projectsToDelete += @{
                    Name = $projectName
                    File = $portFile.FullName
                    LastUsed = $portsData.LastUsed
                }
            }
        } catch {
            Write-Debug "Erreur lors de la lecture du fichier $($portFile.Name): $($_.Exception.Message)"
        }
    }
    
    if ($projectsToDelete.Count -eq 0) {
        Write-Success "Aucun port inutilisé trouvé. Tous les projets existent encore."
        return
    }
    
    Write-Warning "Projets avec ports sauvegardés mais dossiers supprimés:"
    foreach ($project in $projectsToDelete) {
        Write-Host "   📂 $($project.Name) (dernière utilisation: $($project.LastUsed))"
    }
    
    Write-Host ""
    $cleanup = Read-Host "Voulez-vous supprimer ces ports inutilisés ? (o/n)"
    
    if ($cleanup -match "^[oOyY]") {
        foreach ($project in $projectsToDelete) {
            try {
                Remove-Item -Path $project.File -Force
                Write-Success "Ports supprimés pour: $($project.Name)"
            } catch {
                Write-Error "Impossible de supprimer les ports pour: $($project.Name)"
            }
        }
    } else {
        Write-Info "Nettoyage annulé."
    }
}

function Show-PortsStatistics {
    Write-Box "📊 STATISTIQUES DES PORTS" $Global:Colors.Yellow
    
    $portsDir = "$env:USERPROFILE\.wordpress-dev"
    if (-not (Test-Path $portsDir)) {
        Write-Info "Aucune donnée de ports disponible."
        return
    }
    
    $portFiles = Get-ChildItem -Path $portsDir -Filter "*-ports.json" -ErrorAction SilentlyContinue
    if ($portFiles.Count -eq 0) {
        Write-Info "Aucune donnée de ports disponible."
        return
    }
    
    $usedPorts = @{}
    $totalProjects = 0
    $activeProjects = 0
    
    foreach ($portFile in $portFiles) {
        try {
            $portsData = Get-Content -Path $portFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $projectName = $portsData.ProjectName
            $ports = $portsData.Ports
            $totalProjects++
            
            # Vérifier si le projet existe encore
            $projectPath = "C:\dev\wordpress-projects\$projectName"
            if (Test-Path $projectPath) {
                $activeProjects++
            }
            
            # Compter les ports utilisés
            foreach ($service in $ports.PSObject.Properties.Name) {
                $port = $ports.$service
                if (-not $usedPorts.ContainsKey($port)) {
                    $usedPorts[$port] = @()
                }
                $usedPorts[$port] += "$projectName ($service)"
            }
        } catch {
            Write-Debug "Erreur lors de la lecture du fichier $($portFile.Name): $($_.Exception.Message)"
        }
    }
    
    Write-ColorText "📈 Résumé :" $Global:Colors.Cyan
    Write-Host "   📂 Projets total avec ports sauvegardés : $totalProjects"
    Write-Host "   ✅ Projets actifs : $activeProjects"
    Write-Host "   🗑️ Projets supprimés : $($totalProjects - $activeProjects)"
    Write-Host "   🔌 Ports uniques utilisés : $($usedPorts.Count)"
    Write-Host ""
    
    if ($usedPorts.Count -gt 0) {
        Write-ColorText "🔍 Détail des ports utilisés :" $Global:Colors.Cyan
        foreach ($port in ($usedPorts.Keys | Sort-Object)) {
            $projects = $usedPorts[$port]
            Write-Host "   Port $port : $($projects -join ', ')"
        }
        
        # Détecter les conflits potentiels
        $conflicts = $usedPorts.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($conflicts.Count -gt 0) {
            Write-Host ""
            Write-ColorText "⚠️ Conflits potentiels détectés :" $Global:Colors.Yellow
            foreach ($conflict in $conflicts) {
                Write-Host "   Port $($conflict.Key) utilisé par : $($conflict.Value -join ', ')"
            }
        } else {
            Write-Host ""
            Write-ColorText "✅ Aucun conflit de port détecté." $Global:Colors.Green
        }
    }
    Write-Host ""
}

# ============================================================================
# 🎯 PROGRAMME PRINCIPAL
# ============================================================================

try {
    # Initialiser la configuration
    $null = Get-Configuration
    
    do {
        $choice = Show-MainMenu
        
        switch ($choice) {
            1 { New-WordPressProject }
            2 { Show-ExistingProjects }
            3 { Show-ToolsStatus }
            4 { Show-PortsMenu }
            5 { Show-Help }
            0 {
                exit 0
            }
        }
    } while ($true)
} catch {
    Write-Error "Erreur dans le script - $($_.Exception.Message)"
    Write-Info "Ligne - $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host ""
    Write-Host "Appuyez sur Entrée pour quitter..."
    Read-Host
    exit 1
}