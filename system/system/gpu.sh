#!/bin/bash

# Define the PCI address of the GPU
GPU_PCI_ADDRESS="0000:01:00.0"

# Function to disable the GPU
disable_gpu() {
    echo "Disabling the GPU..."
    echo "1" | sudo tee /sys/bus/pci/devices/$GPU_PCI_ADDRESS/remove > /dev/null
    sudo bash -c 'echo "auto" > /sys/class/drm/card0/device/power_dpm_state'
    sudo bash -c 'echo "low" > /sys/class/drm/card0/device/power_dpm_force_performance_level'
    echo "GPU disabled and power management set to low."
}

# Function to enable the GPU
enable_gpu() {
    echo "Enabling the GPU..."
    echo "1" | sudo tee /sys/bus/pci/rescan > /dev/null
    sudo bash -c 'echo "auto" > /sys/class/drm/card0/device/power_dpm_state'
    sudo bash -c 'echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level'
    echo "GPU enabled and power management set to high."
}

# Function to check the GPU state
check_gpu_state() {
    if [ -e /sys/bus/pci/devices/$GPU_PCI_ADDRESS ]; then
        echo "GPU is enabled."
    else
        echo "GPU is disabled."
    fi
}

# Parse the command line arguments
case $1 in
    enable)
        enable_gpu
        ;;
    disable)
        disable_gpu
        ;;
    state)
        check_gpu_state
        ;;
    *)
        echo "Usage: $0 {enable|disable|state}"
        exit 1
        ;;
esac
