# Define the base dotfiles path
$dotfilesPath = "C:/dev/personal/.dotfiles/windows"

# Prompt user for setup type
$setupType = Read-Host "Set up for Work (W) or Personal (P) environment?"

# Apply base Git configuration and link .ideavimrc
Function Setup-CommonConfigurations {
    $sourceGitConfigPath = Join-Path $dotfilesPath ".gitconfig"
    $destGitConfigPath = "$env:USERPROFILE\.gitconfig"
    If (!(Test-Path $destGitConfigPath)) {
        New-Item -ItemType SymbolicLink -Path $destGitConfigPath -Target $sourceGitConfigPath -Force
        Write-Host "Base .gitconfig linked successfully."
    } Else {
        Write-Host "$destGitConfigPath already exists. Consider manual intervention."
    }

    $sourcePath = "$dotfilesPath/../.ideavimrc"
    $targetPath = "$env:USERPROFILE\.ideavimrc"
    If (!(Test-Path $targetPath)) {
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force
        Write-Host ".ideavimrc linked successfully."
    } Else {
        Write-Host ".ideavimc already exists at $targetPath. Consider manual intervention."
    }
}

# Configure Git with either work or personal settings
Function Configure-Git {
    param (
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    # Apply Git configuration for the specified environment
    git config --global include.path $ConfigPath
    Write-Host "Git configured with $ConfigPath settings."
}

# Main script logic
Setup-CommonConfigurations

switch ($setupType.ToUpper()) {
    "W" {
        $configPath = Join-Path $dotfilesPath ".gitconfig-work"
        Configure-Git -ConfigPath $configPath
        Write-Host "Work environment setup completed."
    }
    "P" {
        $configPath = Join-Path $dotfilesPath ".gitconfig-personal"
        Configure-Git -ConfigPath $configPath
        Write-Host "Personal environment setup completed."
    }
    Default {
        Write-Host "Invalid option selected. No changes applied."
    }
}