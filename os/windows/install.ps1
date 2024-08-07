# Install-Software.ps1

# Ensure script is running as Administrator
If (-Not [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator."
    Exit 1
}

function Print-Section($message) {
    Write-Host "###########################" -ForegroundColor Green
    Write-Host $message -ForegroundColor Green
    Write-Host "###########################" -ForegroundColor Green
}

function Install-Chocolatey {
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Print-Section "Installing Chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed"
    }
}

function Install-Scoop {
    if (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Print-Section "Installing Scoop"
        iex (Invoke-WebRequest -Uri 'https://get.scoop.sh' -UseBasicP)
    } else {
        Write-Host "Scoop is already installed"
    }
}

function Is-PackageInstalled($packageName) {
    choco list --local-only | Select-String "^$packageName "
}

function Install-Packages {
    $packages = @(
        "git",
        "vim",
        "neovim",
        "nvm",
        "nodejs",
        "gh",
        "yarn",
        "tree-sitter",
        "zsh",
        "tmux",
        "npm",
        "thefuck"
    )

    Print-Section "Installing Packages"
    foreach ($package in $packages) {
        if (-Not (Is-PackageInstalled $package)) {
            Write-Host "Installing $package..."
            choco install $package -y
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed to install $package. Continuing..."
            }
        } else {
            Write-Host "$package is already installed"
        }
    }
}

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
        "Figma.Figma",
        "NordSecurity.NordVPN",
        "Notion.NotionCalendar",
        "Doist.Todoist"
    )

    Print-Section "Installing Applications"
    foreach ($app in $apps) {
        if (-Not (Is-PackageInstalled $app)) {
            Write-Host "Installing $app..."
            winget install --id $app -e --source winget
        } else {
            Write-Host "$app is already installed"
        }
    }
}

function Install-CLITools {
    $cliTools = @(
        @{
            Name = "stripe-cli";
            InstallCommands = @(
                "scoop bucket add stripe https://github.com/stripe/scoop-stripe-cli.git",
                "scoop install stripe"
            );
            VerifyCommand = "stripe --version";
        },
        @{
            Name = "supabase";
            InstallCommands = @(
                "scoop bucket add supabase https://github.com/supabase/scoop-bucket.git",
                "scoop install supabase"
            );
            VerifyCommand = "supabase --version";
        },
        @{
            Name = "angular-cli";
            InstallCommands = @(
                "npm install -g @angular/cli"
            );
            VerifyCommand = "ng --version";
        }
    )

    Print-Section "Installing CLI Tools"
    foreach ($cli in $cliTools) {
        Write-Host "Attempting to install $($cli.Name)..."
        try {
            # Execute each install command
            foreach ($command in $cli.InstallCommands) {
                Write-Host "Running: $command"
                Invoke-Expression $command
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed to execute: $command"
                    continue
                }
            }

            # Verify installation
            $version = Invoke-Expression $cli.VerifyCommand
            Write-Host "$($cli.Name) installed successfully. Version: $version"
        } catch {
            Write-Host "Error installing $($cli.Name): $_"
        }
    }
}

function Setup-SSH {
    Print-Section "Setting Up SSH"
    if (-Not (Test-Path -Path "$HOME\.ssh\id_rsa")) {
        $email = Read-Host "Enter your email for SSH key"
        ssh-keygen -t rsa -b 4096 -C $email
        Start-Service ssh-agent
        ssh-add "$HOME\.ssh\id_rsa"
        Write-Host "SSH setup complete. Add the following public key to your GitHub account:"
        Get-Content "$HOME\.ssh\id_rsa.pub"
    } else {
        Write-Host "SSH is already set up"
    }
}

function Clone-DotfilesRepo {
    Print-Section "Cloning Dotfiles Repository"
    $dotfilesRepo = "$HOME\.dotfiles"
    if (-Not (Test-Path -Path $dotfilesRepo)) {
        if (-Not (Get-Command git -ErrorAction SilentlyContinue)) {
            choco install git -y
        }
        git clone https://github.com/peciulevicius/.dotfiles.git $dotfilesRepo
    } else {
        Write-Host "Dotfiles repository is already cloned"
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

function Main {
    Install-Chocolatey
    Install-Scoop
    Install-Packages
    Install-Applications
    Install-CLITools
    Setup-SSH
    Clone-DotfilesRepo

    Write-Host "All done! Your development environment is set up." -ForegroundColor Green
}

Main
