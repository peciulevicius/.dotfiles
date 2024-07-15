# Define the base dotfiles path
$dotfilesPath = "mnt/c/dev/personal/.dotfiles/os/windows"

# Import utility functions for colored output
. "..\..\scripts\utils\utils.sh" # Adjust the path as necessary

# Prompt user for setup type with enhanced feedback
$setupType = Read-Host "Set up for Work (W) or Personal (P) environment?"
Print-Question "Set up for Work (W) or Personal (P) environment?" # Assuming Print-Question is a utility function for colored output

Function Setup-CommonConfigurations {
    $sourceGitConfigPath = Join-Path $dotfilesPath ".gitconfig"
    $destGitConfigPath = "$env:USERPROFILE\.gitconfig"
    If (!(Test-Path $destGitConfigPath)) {
        New-Item -ItemType SymbolicLink -Path $destGitConfigPath -Target $sourceGitConfigPath -Force
        Print-Success "Base .gitconfig linked successfully." # Assuming Print-Success is a utility function for colored output
    } Else {
        Print-Warning "$destGitConfigPath already exists. Consider manual intervention." # Assuming Print-Warning is a utility function for colored output
    }

    $sourcePath = "$dotfilesPath/../.ideavimrc"
    $targetPath = "$env:USERPROFILE\.ideavimrc"
    If (!(Test-Path $targetPath)) {
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force
        Print-Success ".ideavimrc linked successfully."
    } Else {
        Print-Warning ".ideavimc already exists at $targetPath. Consider manual intervention."
    }
}

Function Configure-Git {
    param (
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    git config --global include.path $ConfigPath
    Print-Success "Git configured with $ConfigPath settings."
}

Setup-CommonConfigurations

switch ($setupType.ToUpper()) {
    "W" {
        $configPath = Join-Path $dotfilesPath ".gitconfig-work"
        Configure-Git -ConfigPath $configPath
        Print-Success "Work environment setup completed."
    }
    "P" {
        $configPath = Join-Path $dotfilesPath ".gitconfig-personal"
        Configure-Git -ConfigPath $configPath
        Print-Success "Personal environment setup completed."
    }
    Default {
        Print-Error "Invalid option selected. No changes applied." # Assuming Print-Error is a utility function for colored output
    }
}