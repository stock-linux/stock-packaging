print_header() {
    echo "===================================================="
    spaces=$((48 - ${#1}))
    printf "| $1 %${spaces}s|\n"
}

print_content() {
    spaces=$((48 - ${#1}))
    printf "| $1%${spaces}s |\n"
}

print_header_end() {
    echo "===================================================="
}

print_help() {
    print_header "Help:"
    print_content ""
    print_content "stmk -k => Keep build files"
    print_content "stmk help | -h => Show this help menu"
    print_content ""
    print_content ""
    print_content "Environment variables:"
    print_content ""
    print_content "VERBOSE=bool  => Show build output ?"
    print_header_end
}

print_info() {
    echo -e "\e[1;34m$1\e[0m"
}

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}