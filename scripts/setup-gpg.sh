#!/bin/bash

# GPG Commit Signing Setup
# Sets up GPG keys for signing Git commits
#
# Usage: ./setup-gpg.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header "GPG Commit Signing Setup"

# Check if GPG is installed
if ! command -v gpg &> /dev/null; then
    echo "GPG is not installed. Please install it first:"
    echo ""
    echo "  macOS:   brew install gnupg"
    echo "  Arch:    sudo pacman -S gnupg"
    echo "  Ubuntu:  sudo apt install gnupg"
    echo ""
    exit 1
fi

print_success "GPG is installed"

# Check if user already has a GPG key
echo "Checking for existing GPG keys..."
existing_keys=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep sec | wc -l)

if [ "$existing_keys" -gt 0 ]; then
    echo ""
    echo "Found existing GPG key(s):"
    gpg --list-secret-keys --keyid-format=long

    echo ""
    read -p "Do you want to use an existing key? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Your GPG keys:"
        gpg --list-secret-keys --keyid-format=long
        echo ""
        read -p "Enter the GPG key ID you want to use (e.g., 3AA5C34371567BD2): " gpg_key_id
    else
        generate_new_key=true
    fi
else
    echo "No existing GPG keys found."
    generate_new_key=true
fi

# Generate new GPG key if needed
if [ "$generate_new_key" = true ]; then
    print_header "Generating New GPG Key"

    read -p "Enter your name: " user_name
    read -p "Enter your email (must match GitHub email): " user_email

    echo ""
    echo "Generating GPG key for:"
    echo "  Name:  $user_name"
    echo "  Email: $user_email"
    echo ""
    echo "You'll be asked to set a passphrase (keep it safe!)"
    echo ""

    # Generate key with recommended settings
    gpg --full-generate-key --batch <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $user_name
Name-Email: $user_email
Expire-Date: 0
%commit
EOF

    print_success "GPG key generated"

    # Get the new key ID
    gpg_key_id=$(gpg --list-secret-keys --keyid-format=long | grep sec | head -n 1 | awk '{print $2}' | cut -d'/' -f2)
fi

print_header "Configuring Git"

# Configure Git to use the GPG key
git config --global user.signingkey "$gpg_key_id"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

print_success "Git configured to sign commits with GPG key: $gpg_key_id"

# Configure GPG TTY (needed for passphrase prompts)
echo ""
echo "Adding GPG TTY configuration to shell..."

shell_rc="$HOME/.zshrc"
if [ -f "$HOME/.bashrc" ]; then
    shell_rc="$HOME/.bashrc"
fi

if ! grep -q "GPG_TTY" "$shell_rc"; then
    echo "" >> "$shell_rc"
    echo "# GPG Configuration" >> "$shell_rc"
    echo "export GPG_TTY=\$(tty)" >> "$shell_rc"
    print_success "Added GPG_TTY to $shell_rc"
else
    print_info "GPG_TTY already configured in $shell_rc"
fi

# macOS specific: Configure GPG to use pinentry-mac
if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v pinentry-mac &> /dev/null; then
        gpg_agent_conf="$HOME/.gnupg/gpg-agent.conf"
        mkdir -p "$HOME/.gnupg"
        chmod 700 "$HOME/.gnupg"

        if ! grep -q "pinentry-program" "$gpg_agent_conf" 2>/dev/null; then
            echo "pinentry-program $(which pinentry-mac)" >> "$gpg_agent_conf"
            gpgconf --kill gpg-agent
            print_success "Configured pinentry-mac for macOS"
        fi
    else
        print_warning "pinentry-mac not found. Install with: brew install pinentry-mac"
    fi
fi

print_header "Adding GPG Key to GitHub"

# Export public key
public_key=$(gpg --armor --export "$gpg_key_id")

echo "Your GPG public key:"
echo ""
echo "$public_key"
echo ""

# Copy to clipboard if possible
if command -v pbcopy &> /dev/null; then
    echo "$public_key" | pbcopy
    print_success "Public key copied to clipboard!"
elif command -v xclip &> /dev/null; then
    echo "$public_key" | xclip -selection clipboard
    print_success "Public key copied to clipboard!"
fi

echo ""
echo "To add this key to GitHub:"
echo "  1. Go to: https://github.com/settings/keys"
echo "  2. Click 'New GPG key'"
echo "  3. Paste the key above"
echo "  4. Click 'Add GPG key'"
echo ""

read -p "Press Enter once you've added the key to GitHub..."

print_header "Testing GPG Signing"

echo "Making a test commit to verify GPG signing..."
test_file="$HOME/.gpg-test-$RANDOM.txt"
echo "GPG test" > "$test_file"
git init "$HOME/.gpg-test-repo" &> /dev/null
cd "$HOME/.gpg-test-repo"
git add .
git commit -m "Test GPG signing" &> /dev/null || {
    print_warning "Test commit failed. Make sure your GPG passphrase is correct."
    cd "$HOME"
    rm -rf "$HOME/.gpg-test-repo" "$test_file"
    exit 1
}

if git log --show-signature -1 2>&1 | grep -q "Good signature"; then
    print_success "GPG signing is working correctly!"
else
    print_warning "GPG signing may not be working correctly. Check your configuration."
fi

cd "$HOME"
rm -rf "$HOME/.gpg-test-repo" "$test_file"

print_header "Setup Complete!"

echo -e "${GREEN}GPG commit signing is now configured!${NC}"
echo ""
echo "Summary:"
echo "  • GPG key ID: $gpg_key_id"
echo "  • Git commits will be automatically signed"
echo "  • Git tags will be automatically signed"
echo "  • Public key added to GitHub"
echo ""
echo "Useful commands:"
echo "  gpg --list-keys                  # List all keys"
echo "  gpg --list-secret-keys           # List private keys"
echo "  gpg --armor --export <KEY_ID>    # Export public key"
echo "  git log --show-signature         # Verify signed commits"
echo "  git config --global commit.gpgsign false  # Disable signing"
echo ""
echo "Reload your shell: source $shell_rc"
echo ""
