# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# Platform Detection and Powerlevel10k Setup
# ============================================================================

# Detect the operating system
case "$(uname -s)" in
  Darwin*)
    # macOS - Check for Homebrew installation (Apple Silicon vs Intel)
    if [[ -f "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      # Apple Silicon (M1/M2/M3)
      source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
    elif [[ -f "/usr/local/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      # Intel Mac
      source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
    fi
    ;;
  Linux*)
    # Linux - Check various installation locations
    if [[ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      # Standalone installation
      source ~/powerlevel10k/powerlevel10k.zsh-theme
    elif [[ -f "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      # Alternative standalone location
      source ~/.powerlevel10k/powerlevel10k.zsh-theme
    elif [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      # Oh My Zsh custom theme
      source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*)
    # Windows (Git Bash, MSYS2, etc.)
    if [[ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source ~/powerlevel10k/powerlevel10k.zsh-theme
    fi
    ;;
esac

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# Oh My Zsh Configuration (if installed)
# ============================================================================

# Path to your oh-my-zsh installation
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"

  # Set theme (if not using Powerlevel10k)
  # ZSH_THEME="robbyrussell"

  # Load Oh My Zsh
  source $ZSH/oh-my-zsh.sh
fi

# ============================================================================
# Custom Aliases and Functions
# ============================================================================

# Git aliases (supplement those in .gitconfig)
alias gs='git status'
alias gp='git pull'
alias gps='git push'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Common shortcuts
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Platform-specific aliases
case "$(uname -s)" in
  Darwin*)
    # macOS specific
    alias brewup='brew update && brew upgrade && brew cleanup'
    ;;
  Linux*)
    # Linux specific
    if command -v apt &> /dev/null; then
      alias aptup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
    elif command -v pacman &> /dev/null; then
      alias pacup='sudo pacman -Syu'
    fi
    ;;
esac

# ============================================================================
# Environment Variables
# ============================================================================

# Preferred editor
export EDITOR='vim'
export VISUAL='vim'

# ============================================================================
# Node Version Manager (NVM)
# ============================================================================

export NVM_DIR="$HOME/.nvm"
# Load nvm if installed
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi
# Load nvm bash_completion
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  source "$NVM_DIR/bash_completion"
fi

# ============================================================================
# Additional Tool Configurations
# ============================================================================

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Cargo (Rust)
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
