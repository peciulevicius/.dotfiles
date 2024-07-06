# Define the base dotfiles path
$dotfilesPath = "C:/dev/personal/.dotfiles"

# Link the base .gitconfig
$sourceGitConfigPath = Join-Path $dotfilesPath "windows-work/.gitconfig"
$destGitConfigPath = "$env:USERPROFILE\.gitconfig"
If (!(Test-Path $destGitConfigPath)) {
    New-Item -ItemType SymbolicLink -Path $destGitConfigPath -Target $sourceGitConfigPath -Force
} Else {
    Write-Host ".gitconfig already exists at $destGitConfigPath, manual intervention required."
}

# Set Git to include work-specific configurations for projects within C:/dev/work/
$workConfigPath = Join-Path $dotfilesPath "windows-work/.gitconfig-work"
$workProjectsRoot = "C:/dev/work/"
git config --global includeIf.gitdir:"$workProjectsRoot".path $workConfigPath

# Set Git to include personal-specific configurations for projects within C:/dev/personal/
$personalConfigPath = Join-Path $dotfilesPath "windows-work/.gitconfig-personal"
$personalProjectsRoot = "C:/dev/personal/"
git config --global includeIf.gitdir:"$personalProjectsGoot".path $personalConfigPath

# Linking .ideavimrc for Windows
$sourcePath = "C:/dev/personal/.dotfiles/.ideavimrc"
$targetPath = "$env:USERPROFILE\.ideavimrc"

if (Test-Path $targetPath) {
    Write-Output "$targetPath already exists. Creating a backup."
    Rename-Item $targetPath "$targetPath.backup" -Force
}

New-Item -ItemType SymbolicLink -Path $targetPath -Target $source_shPath -Force