#!/bin/bash

# ==============================
# Source utilities
# ==============================
# FIXME: fix path
# . "$HOME/dev/.dotfiles/scripts/utils/utils.sh"
. "../../scripts/utils/utils.sh"

#==================================
# Print Section Title
#==================================
print_section "Running MacOS Dotfiles Setup"
print_title "Test title"

print_result 0 "This is a mock success message"
print_result 1 "This is a mock error message"
print_warning "warning"

print_in_red "This is red\n"
print_in_green "This is green\n"
print_in_yellow "This is yellow\n"
print_in_purple "This is purple\n"
print_in_cyan "This is cyan\n"
print_in_white "This is white\n"
print_in_blue "This is blue\n"

# Ask a question
print_question "What is your favorite programming language?"

# List options
print_option "1" "Python"
print_option "2" "JavaScript"
print_option "3" "Rust"

# Optionally, you can prompt the user to enter a choice
print_in_white "Enter your choice (1-3): "
read choice

# Handle the user's choice
case $choice in
    1) print_success "You chose Python." ;;
    2) print_success "You chose JavaScript." ;;
    3) print_success "You chose Rust." ;;
    *) print_error "Invalid choice. Please enter 1, 2, or 3." ;;
esac