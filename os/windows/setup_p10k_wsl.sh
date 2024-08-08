#!/bin/bash

# Update package list and install necessary packages
sudo apt update && sudo apt install -y zsh git curl

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set Powerlevel10k as the default theme
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Add Powerlevel10k configuration to .zshrc
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >>~/.zshrc

# Source .zshrc to apply changes
zsh -c 'source ~/.zshrc && p10k configure'

echo "p10k setup for WSL completed. Please restart your WSL terminal."