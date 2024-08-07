# Install-Software.ps1

# Ensure script is running as Administrator
If (-Not [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator."
    Exit 1
}

# Function to print section headers
function Print-Section($message) {
    Write-Host "###########################" -ForegroundColor Green
    Write-Host $message -ForegroundColor Green
    Write-Host "###########################" -ForegroundColor Green
}

# Function to install Chocolatey
function Install-Chocolatey {
    Print-Section "Installing Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Function to install packages using Chocolatey
function Install-Packages {
    $packages = @(
        "git",
        "vim",
        "neovim",
        "zsh",
        "tmux",
        "docker-desktop",
        "nvm",
        "nodejs",
        "npm",
        "gh",
        "thefuck",
        "yarn",
        "tree-sitter"
    )

    Print-Section "Installing Packages"
    foreach ($package in $packages) {
        choco install $package -y
    }
}

# Function to install applications using winget
function Install-Applications {
    $apps = @(
        "NordPass.NordPass",
        "Spotify.Spotify",
        "Google.Chrome",
        "Notion.Notion",
        "JetBrains.WebStorm",
        "Microsoft.VisualStudioCode",
        "Postman.Postman",
        "Discord.Discord",
        "Figma.Figma"
    )

    Print-Section "Installing Applications"
    foreach ($app in $apps) {
        winget install --id $app -e --source winget
    }
}

# Function to setup SSH
function Setup-SSH {
    Print-Section "Setting Up SSH"
    if (-Not (Test-Path -Path "$HOME\.ssh\id_rsa")) {
        $email = Read-Host "Enter your email for SSH key"
        ssh-keygen -t rsa -b 4096 -C $email
        Start-SshAgent -Quiet | Out-Null
        ssh-add "$HOME\.ssh\id_rsa"
        Write-Host "SSH setup complete. Add the following public key to your GitHub account:"
        Get-Content "$HOME\.ssh\id_rsa.pub"
    } else {
        Write-Host "SSH is already set up"
    }
}

# Function to clone dotfiles repository and setup symlinks
function Clone-DotfilesRepo {
    Print-Section "Cloning Dotfiles Repository"
    $dotfilesRepo = "$HOME\.dotfiles"
    if (-Not (Test-Path -Path $dotfilesRepo)) {
        git clone https://github.com/peciulevicius/.dotfiles.git $dotfilesRepo
    }

    $files = @(
        "windows\.gitconfig",
        "windows\.ideavimrc",
        "windows\.p10k.zsh",
        "windows\.zshrc"
    )

    # Backup and remove existing dotfiles before checkout
    foreach ($file in $files) {
        $targetPath = "$HOME\$(Split-Path $file -Leaf)"
        if (Test-Path -Path $targetPath) {
            Write-Host "$(Split-Path $file -Leaf) already exists. Creating a backup."
            Rename-Item -Path $targetPath -NewName "$($targetPath).backup"
        }
    }

    # Checkout dotfiles
    Set-Location -Path $dotfilesRepo
    git checkout
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error checking out dotfiles, possible conflicts."
    } else {
        Write-Host "Dotfiles checked out successfully."
    }

    Setup-Symlinks -files $files -dotfilesRepo $dotfilesRepo
}

# Function to setup symlinks for dotfiles
function Setup-Symlinks {
    param (
        [array]$files,
        [string]$dotfilesRepo
    )

    Print-Section "Setting Up Symlinks for Dotfiles"
    foreach ($file in $files) {
        $sourcePath = "$dotfilesRepo\$file"
        $targetPath = "$HOME\$(Split-Path $file -Leaf)"
        Write-Host "Creating symlink for $file..."
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force
    }
}

# Main function to run the setup
function Main {
    Install-Chocolatey
    Install-Packages
    Install-Applications
    Setup-SSH
    Clone-DotfilesRepo

    Write-Host "All done! Your development environment is set up." -ForegroundColor Green
}

# Run the main function
Main
