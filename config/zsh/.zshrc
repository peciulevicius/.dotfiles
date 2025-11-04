# ===========================================================================
# Zsh Configuration - Cross-Platform Compatible
# ===========================================================================

# ----------------------------------------------------------------------------
# Powerlevel10k Instant Prompt (Optional)
# ----------------------------------------------------------------------------
# Enable instant prompt if p10k is installed. Keep this near the top of .zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----------------------------------------------------------------------------
# Powerlevel10k Theme (Optional - works fine without it!)
# ----------------------------------------------------------------------------
P10K_LOADED=false

# Try to load Powerlevel10k based on OS
case "$(uname -s)" in
  Darwin*)
    # macOS - Check Homebrew locations (Apple Silicon vs Intel)
    if [[ -f "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    elif [[ -f "/usr/local/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    fi
    ;;
  Linux*)
    # Linux - Check various installation locations
    if [[ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source ~/powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    elif [[ -f "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source ~/.powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    elif [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*)
    # Windows
    if [[ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
      source ~/powerlevel10k/powerlevel10k.zsh-theme
      P10K_LOADED=true
    fi
    ;;
esac

# Load p10k config if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----------------------------------------------------------------------------
# Basic Prompt (Fallback if p10k not installed)
# ----------------------------------------------------------------------------
if [[ "$P10K_LOADED" != "true" ]]; then
  # Enable command substitution in prompts
  setopt PROMPT_SUBST

  # Git branch info
  autoload -Uz vcs_info
  precmd() { vcs_info }
  zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'

  # Clean, informative prompt
  PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} %F{green}❯%f '
fi

# ----------------------------------------------------------------------------
# Oh My Zsh (Optional)
# ----------------------------------------------------------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  # ZSH_THEME is ignored if p10k is loaded
  source $ZSH/oh-my-zsh.sh
fi

# ----------------------------------------------------------------------------
# History Configuration
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY           # Append rather than overwrite
setopt INC_APPEND_HISTORY       # Write to history file immediately
setopt SHARE_HISTORY            # Share history between sessions
setopt HIST_IGNORE_DUPS         # Don't record duplicate entries
setopt HIST_IGNORE_SPACE        # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks

# ----------------------------------------------------------------------------
# Environment Variables
# ----------------------------------------------------------------------------
export EDITOR='vim'
export VISUAL='vim'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# ----------------------------------------------------------------------------
# Completion
# ----------------------------------------------------------------------------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select                          # Select completions with arrow keys
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # Case-insensitive completion

# ----------------------------------------------------------------------------
# Key Bindings
# ----------------------------------------------------------------------------
bindkey -e  # Emacs-style keybindings (Ctrl+A, Ctrl+E, etc.)

# ----------------------------------------------------------------------------
# Git Aliases (Supplement .gitconfig)
# ----------------------------------------------------------------------------
alias gs='git status'
alias gst='git st'              # Uses git st alias (short status)
alias gp='git pull'
alias gps='git push'
alias gd='git diff'
alias gds='git ds'              # Staged diff
alias gco='git co'
alias gb='git br'
alias ga='git add'
alias gaa='git aa'              # Add all
alias gc='git ci'
alias gcm='git cm'
alias gl='git lg'               # Pretty log
alias gundo='git undo'          # Undo last commit

# ----------------------------------------------------------------------------
# Common Aliases
# ----------------------------------------------------------------------------
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ----------------------------------------------------------------------------
# Platform-Specific Aliases
# ----------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin*)
    # macOS specific
    alias brewup='brew update && brew upgrade && brew cleanup'
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

    # Open current directory in Finder
    alias finder='open -a Finder .'
    ;;
  Linux*)
    # Linux specific
    if command -v apt &> /dev/null; then
      alias aptup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
    elif command -v pacman &> /dev/null; then
      alias pacup='sudo pacman -Syu'
    fi

    # Open current directory in file manager
    if command -v xdg-open &> /dev/null; then
      alias open='xdg-open'
    fi
    ;;
esac

# ----------------------------------------------------------------------------
# Node Version Manager (NVM)
# ----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
# Load nvm if installed
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi
# Load nvm bash completion
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  source "$NVM_DIR/bash_completion"
fi

# ----------------------------------------------------------------------------
# pnpm
# ----------------------------------------------------------------------------
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ----------------------------------------------------------------------------
# Rust/Cargo
# ----------------------------------------------------------------------------
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# ----------------------------------------------------------------------------
# Homebrew (macOS)
# ----------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ----------------------------------------------------------------------------
# GitHub CLI Completion
# ----------------------------------------------------------------------------
if command -v gh &> /dev/null; then
  eval "$(gh completion -s zsh)"
fi

# ----------------------------------------------------------------------------
# Custom Functions
# ----------------------------------------------------------------------------

# Extract various archive formats
extract() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)          echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick server
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# ----------------------------------------------------------------------------
# Local Customizations
# ----------------------------------------------------------------------------
# Load local customizations that shouldn't be in dotfiles
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
