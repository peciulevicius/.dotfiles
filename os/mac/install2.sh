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
print_title "Dock Settings"

#ask_for_confirmation "'Would you like to add Dock shortcuts?"
#printf "\n"

# Mock a success
print_result 0 "This is a mock success message"

# Mock an error
print_result 1 "This is a mock error message"

print_success "success"
print_warning "warning"
print_error "error"
print_question "question"
print_option "option"
print_option "option2"
print_option "option3"

print_in_red "This is red"
print_line_break
print_in_green "This is green"
print_line_break
print_in_yellow "This is yellow"
print_line_break
print_in_purple "This is purple"
print_line_break
print_in_cyan "This is cyan"
print_line_break
print_in_white "This is white"
print_line_break
print_in_blue "This is blue"
print_line_break



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