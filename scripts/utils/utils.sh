#==================================
# Print
#==================================
print_section() {
    local TITLE="$*"
    local TITLE_LENGTH=${#TITLE}
    local BORDER_LENGTH=$((TITLE_LENGTH + 18))

    local i
    local BANNER_TOP
    for (( i = 0; i < BORDER_LENGTH; ++i )); do
        if [ $i = 0 ]; then
            BANNER_TOP+="╭"
        elif [ $i = $(($BORDER_LENGTH-1)) ]; then
            BANNER_TOP+="╮"
        else
            BANNER_TOP+="─"
        fi
    done

    local BANNER_BOTTOM
    for (( i = 0; i < BORDER_LENGTH; ++i )); do
        if [ $i = 0 ]; then
            BANNER_BOTTOM+="╰"
        elif [ $i = $(($BORDER_LENGTH-1)) ]; then
            BANNER_BOTTOM+="╯"
        else
            BANNER_BOTTOM+="─"
        fi
    done

    print_linke_break
    print_in_green "$BANNER_TOP"
    print_in_green "\n│        $TITLE        │\n"
    print_in_green "$BANNER_BOTTOM"
    print_linke_break

}

print_title() {
    print_in_purple "\n • $1\n"
}

print_success() {
    print_in_green "   [✔] $1\n"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

print_error() {
    print_in_red "   [✖] $1 $2\n"
}

print_question() {
    print_in_yellow "   [?] $1"
}

print_option() {
    print_in_yellow "   $1)"
    print_in_white " $2\n"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"
}

print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

print_in_red() {
    print_in_color "$1" 1
}

print_in_green() {
    print_in_color "$1" 2
}

print_in_yellow() {
    print_in_color "$1" 3
}

print_in_blue() {
    print_in_color "$1" 4
}

print_in_purple() {
    print_in_color "$1" 5
}

print_in_cyan() {
    print_in_color "$1" 6
}

print_in_white() {
    print_in_color "$1" 7
}

print_line_break() {
    printf "\n"
}

print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2> /dev/null)" \
        "$1" \
        "$(tput sgr0 2> /dev/null)"
}
