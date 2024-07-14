#!/bin/bash

# ==============================
# Source utilities
# ==============================
. "$HOME/dev/.dotfiles/scripts/utils/utils.sh"

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

