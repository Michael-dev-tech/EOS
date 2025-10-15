#!/bin/bash

# ==============================================================================
# eOS Setup & System Audit Script
#
# Author: Michael-dev-tech
# Repository: https://github.com/Michael-dev-tech/eOS
# Description: This script performs pre-flight checks, gathers system
#              information, and sets up the basic environment for eOS.
# ==============================================================================

# --- Configuration ---
LOG_FILE="/var/log/eOS_setup.log"
INSTALL_DIR="/opt/eOS"
REQUIRED_UTILS=("curl" "git" "gcc" "make")

# --- Colors for Output ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'

# --- Helper Functions ---

# Logs a message to both stdout and the log file
log_message() {
    local type="$1"
    local message="$2"
    local color="$C_RESET"
    local timestamp

    timestamp=$(date +"%Y-%m-%d %T")

    case "$type" in
        INFO) color="$C_GREEN" ;;
        WARN) color="$C_YELLOW" ;;
        ERROR) color="$C_RED" ;;
        STEP) color="$C_BLUE" ;;
    esac

    # Log to stdout with color
    echo -e "${color}[$type]${C_RESET} $message"
    # Log to file without color
    echo "[$timestamp] [$type] $message" >> "$LOG_FILE"
}

# Function to check if the script is run as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root. Please use sudo."
        exit 1
    fi
    touch "$LOG_FILE" # Ensure log file can be created/written to
    log_message "INFO" "Root privileges confirmed."
}

# Displays a welcome banner for the eOS project
display_banner() {
    echo -e "${C_CYAN}"
    echo "    ______ _____   ____   "
    echo "   / ____// ___/  / __ \  "
    echo "  / __/   \__ \  / / / /  "
    echo " / /___  ___/ / / /_/ /   "
    echo "/_____/ /____/  \____/    "
    echo "                          "
    echo -e " eOS Environment Setup Utility ${C_RESET}"
    echo "================================================="
}

# --- Main Logic Functions ---

# Checks for required system dependencies
check_dependencies() {
    log_message "STEP" "Checking for required system utilities..."
    local all_found=true
    for util in "${REQUIRED_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            log_message "INFO" " -> Found: $util"
        else
            log_message "WARN" " -> Missing: $util. Please install it."
            all_found=false
        fi
    done

    if [ "$all_found" = false ]; then
        log_message "ERROR" "One or more dependencies are missing. Aborting setup."
        exit 1
    fi
    log_message "INFO" "All system dependencies are met."
}

# Gathers and displays key system information
perform_system_audit() {
    log_message "STEP" "Performing system audit..."
    
    local os_kernel
    local hostname
    local uptime
    local mem_total
    local cpu_info

    os_kernel=$(uname -r)
    hostname=$(hostname)
    uptime=$(uptime -p)
    mem_total=$(grep MemTotal /proc/meminfo | awk '{printf "%.2f GiB", $2/1024/1024}')
    cpu_info=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')

    log_message "INFO" "System Audit Results:"
    echo "  - Hostname: $hostname" | tee -a "$LOG_FILE"
    echo "  - Kernel:   $os_kernel" | tee -a "$LOG_FILE"
    echo "  - Uptime:   $uptime" | tee -a "$LOG_FILE"
    echo "  - CPU:      $cpu_info" | tee -a "$LOG_FILE"
    echo "  - Memory:   $mem_total" | tee -a "$LOG_FILE"
}

# Creates the necessary filesystem structure for eOS
setup_filesystem() {
    log_message "STEP" "Setting up filesystem structure at $INSTALL_DIR..."
    
    if [ -d "$INSTALL_DIR" ]; then
        log_message "WARN" "Install directory $INSTALL_DIR already exists. Skipping creation."
    else
        mkdir -p "$INSTALL_DIR"/{bin,lib,etc,src,var/log}
        if [ $? -eq 0 ]; then
            log_message "INFO" "Successfully created eOS directory structure."
        else
            log_message "ERROR" "Failed to create directory structure. Check permissions."
            exit 1
        fi
    fi
    
    # Set permissions
    chmod -R 755 "$INSTALL_DIR"
    log_message "INFO" "Filesystem permissions set."
}

# --- Main Execution ---
main() {
    display_banner
    check_root
    
    log_message "INFO" "Starting eOS setup process. Log will be saved to $LOG_FILE"
    
    perform_system_audit
    check_dependencies
    
    echo "" # Add a newline for readability
    read -p "Proceed with filesystem setup at $INSTALL_DIR? [y/N]: " confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        setup_filesystem
        log_message "INFO" "eOS base setup completed successfully!"
        echo -e "${C_GREEN}Welcome to eOS!${C_RESET}"
    else
        log_message "WARN" "Setup aborted by user."
        echo "Exiting."
    fi
}

# Run the main function
main
