#!/bin/bash

# Function to disable WiFi
disable_wifi() {
    nmcli radio wifi off
    echo "WiFi has been disabled."
}

# Function to enable WiFi
enable_wifi() {
    nmcli radio wifi on
    echo "WiFi has been enabled."
}

# Main script starts here
echo "Do you want to ENABLE or DISABLE WiFi? Enter 'enable' or 'disable':"
read -r choice

case $choice in
    enable)
        enable_wifi
        ;;
    disable)
        disable_wifi
        ;;
    *)
        echo "Invalid input. Please enter 'enable' or 'disable'."
        exit 1
        ;;
esac
