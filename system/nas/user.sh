#!/bin/bash

# Define colors and icons
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
ICON_SUCCESS='✔'
ICON_ERROR='✘'
ICON_INFO='ℹ'
ICON_WARNING='⚠'
ICON_FOLDER='📁'

# Path to the YAML configuration file
YAML_FILE="/data/scripts/control/user-defaults.yml"

# Parse YAML file to extract configuration variables
parse_yaml() {
    config_default_home_dir=$(yq e '.default_home_dir' "$YAML_FILE")
    config_pre_create_folders=$(yq e '.pre_create_folders | join(", ")' "$YAML_FILE")
}

# Load configuration variables
parse_yaml

# Function to display a colored message with an icon
print_message() {
    local color=$1
    local icon=$2
    local message=$3
    echo -e "${color}${icon} ${message}${COLOR_RESET}"
}

# Function to create a new user, set password, and configure Samba
create_user() {
    if [ -z "$config_default_home_dir" ]; then
        print_message $COLOR_RED "$ICON_ERROR Error: 'default_home_dir' is not defined in the YAML file."
        exit 1
    fi

    print_message $COLOR_GREEN "$ICON_INFO Home directories are located in: $config_default_home_dir"

    read -p "Enter the new username: " username
    if [ -z "$username" ]; then
        print_message $COLOR_RED "$ICON_ERROR Error: Username cannot be empty."
        exit 1
    fi

    read -p "Enter the quota size for the home directory (e.g., 1G, 500M): " quota_size
    home_dir="$config_default_home_dir/$username"
    sudo useradd -m -d "$home_dir" -s /bin/bash -G home "$username"
    sudo chmod 700 "$home_dir"

    IFS=', ' read -r -a folders <<< "$config_pre_create_folders"
    for folder in "${folders[@]}"; do
        sudo mkdir -p "$home_dir/$folder"
        sudo chown "$username:home" "$home_dir/$folder"
    done

    if [ -n "$quota_size" ]; then
        if command -v setquota &> /dev/null; then
            mount_point=$(df --output=target "$home_dir" | tail -n 1)
            if [ -z "$mount_point" ]; then
                print_message $COLOR_RED "$ICON_ERROR Error: Cannot determine the mount point for $home_dir."
                exit 1
            fi
            sudo setquota -u "$username" 0 "$quota_size" 0 0 "$mount_point"
            print_message $COLOR_GREEN "$ICON_SUCCESS Quota for user $username set to $quota_size."
        else
            print_message $COLOR_RED "$ICON_ERROR Error: 'setquota' command not found. Please install the quota tools."
            exit 1
        fi
    fi

    while true; do
        read -s -p "Enter password for the new user: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
        if [ "$password" == "$password_confirm" ]; then
            echo -e "$password\n$password" | sudo passwd "$username"
            break
        else
            print_message $COLOR_RED "$ICON_ERROR Passwords do not match. Please try again."
        fi
    done

    echo -e "$password\n$password" | sudo smbpasswd -a "$username"
    print_message $COLOR_GREEN "$ICON_SUCCESS User $username has been created and configured."
    display_user_info "$username"
}

# Function to remove a user
remove_user() {
    read -p "Enter the username to remove: " username
    sudo smbpasswd -x "$username"
    sudo userdel -r "$username"
    print_message $COLOR_GREEN "$ICON_SUCCESS User $username has been removed."
}

# Function to display user information including quota
display_user_info() {
    local username=$1
    local home_dir="$config_default_home_dir/$username"

    if ! id "$username" &>/dev/null; then
        print_message $COLOR_RED "$ICON_ERROR Error: User $username does not exist."
        exit 1
    fi

    local uid
    uid=$(id -u "$username")
    local groups
    groups=$(id -Gn "$username" | sed 's/ /, /g')

    local quota_info
    local space_info
    if command -v quota &> /dev/null; then
        local used
        local limit
        read -r used limit <<<$(sudo quota -u "$username" | awk 'NR == 3 {print $2, $4}')

        if [ -n "$limit" ] && [[ "$limit" =~ ^[0-9]+$ ]]; then
            used=$((used * 1024))
            limit=$((limit * 1024))

            local binary_used
            local binary_limit
            if [ "$limit" -ge $((1024**4)) ]; then
                binary_limit=$(printf "%.2f TiB" "$(bc <<< "scale=2; $limit / (1024^4)")")
            elif [ "$limit" -ge $((1024**3)) ]; then
                binary_limit=$(printf "%.2f GiB" "$(bc <<< "scale=2; $limit / (1024^3)")")
            elif [ "$limit" -ge $((1024**2)) ]; then
                binary_limit=$(printf "%.2f MiB" "$(bc <<< "scale=2; $limit / (1024^2)")")
            elif [ "$limit" -ge 1024 ]; then
                binary_limit=$(printf "%.2f KiB" "$(bc <<< "scale=2; $limit / 1024")")
            else
                binary_limit=$(printf "%d B" "$limit")
            fi

            if [ "$used" -ge $((1024**4)) ]; then
                binary_used=$(printf "%.2f TiB" "$(bc <<< "scale=2; $used / (1024^4)")")
            elif [ "$used" -ge $((1024**3)) ]; then
                binary_used=$(printf "%.2f GiB" "$(bc <<< "scale=2; $used / (1024^3)")")
            elif [ "$used" -ge $((1024**2)) ]; then
                binary_used=$(printf "%.2f MiB" "$(bc <<< "scale=2; $used / (1024^2)")")
            elif [ "$used" -ge 1024 ]; then
                binary_used=$(printf "%.2f KiB" "$(bc <<< "scale=2; $used / 1024")")
            else
                binary_used=$(printf "%d B" "$used")
            fi

            if [ "$limit" -eq 0 ]; then
                binary_limit="∞"
            fi

            quota_info="$binary_limit"
            space_info="$binary_used/$binary_limit"
        else
            quota_info="Error: Could not extract quota limit or quota is not set."
            space_info="Error: Could not extract used space or used space is not set."
        fi
    else
        quota_info="Quota command not found. Please install the quota tools."
        space_info="Quota command not found. Please install the quota tools."
    fi

    local library_info=""
    local max_folder_name_length=20
    IFS=', ' read -r -a folders <<< "$config_pre_create_folders"
    for folder in "${folders[@]}"; do
        local folder_size
        folder_size=$(sudo du -sh "$home_dir/$folder" 2>/dev/null | awk '{print $1}')
        library_info+=$(printf "%-${max_folder_name_length}s %s" "$ICON_FOLDER $folder" "$folder_size\n")
    done

    print_message $COLOR_CYAN "$ICON_INFO User Information for $username:"
    echo "--------------------------------"
    echo -e "${COLOR_BLUE}UID:${COLOR_RESET} $uid"
    echo -e "${COLOR_BLUE}Groups:${COLOR_RESET} $groups"
    echo -e "${COLOR_BLUE}Home Directory:${COLOR_RESET} $home_dir"
    echo -e "${COLOR_BLUE}Quota:${COLOR_RESET} $quota_info"
    echo -e "${COLOR_BLUE}Space:${COLOR_RESET} $space_info"
    echo "--------------------------------"
    echo -e "${COLOR_YELLOW}Libraries${COLOR_RESET}"
    echo "--------------------------------"
    echo -e "$library_info"
    echo "--------------------------------"
}

# Function to set or update user quota
update_user_quota() {
    local username=$1
    local quota_size=$2
    local home_dir="$config_default_home_dir/$username"

    if [ ! -d "$home_dir" ]; then
        print_message $COLOR_RED "$ICON_ERROR Error: Home directory for $username does not exist."
        exit 1
    fi

    if [ -n "$quota_size" ]; then
        if command -v setquota &> /dev/null; then
            local mount_point
            mount_point=$(df --output=target "$home_dir" | tail -n 1)
            if [ -z "$mount_point" ]; then
                print_message $COLOR_RED "$ICON_ERROR Error: Cannot determine the mount point for $home_dir."
                exit 1
            fi
            sudo setquota -u "$username" 0 "$quota_size" 0 0 "$mount_point"
            print_message $COLOR_GREEN "$ICON_SUCCESS Quota for user $username set to $quota_size."
        else
            print_message $COLOR_RED "$ICON_ERROR Error: 'setquota' command not found. Please install the quota tools."
            exit 1
        fi
    else
        print_message $COLOR_RED "$ICON_ERROR Error: No quota size provided."
        exit 1
    fi
}

# Function to list all users in the group 'home'
list_users() {
    local group="home"
    if getent group "$group" > /dev/null 2>&1; then
        print_message $COLOR_CYAN "$ICON_INFO Users in group '$group':"
        getent group "$group" | awk -F: '{print $4}' | tr ',' '\n' | sort
    else
        print_message $COLOR_RED "$ICON_ERROR Error: Group '$group' does not exist."
        exit 1
    fi
}

# Check if group 'home' exists, if not create it
if ! getent group home > /dev/null 2>&1; then
    sudo groupadd home
fi

# Check for command line arguments
case "$1" in
    create)
        create_user
        ;;
    remove)
        remove_user
        ;;
    info)
        read -p "Enter the username to display information: " username
        display_user_info "$username"
        ;;
    size)
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_message $COLOR_RED "$ICON_ERROR Usage: $0 size <username> <quota_size>"
            exit 1
        fi
        update_user_quota "$2" "$3"
        ;;
    list)
        list_users
        ;;
    *)
        print_message $COLOR_RED "$ICON_ERROR Usage: $0 {create|remove|info|size|list}"
        exit 1
        ;;
esac
