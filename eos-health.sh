// This is linked with setup.sh

#!/bin/bash

# ==============================================================================
# eOS System Health & Monitoring Script
#
# Author: Michael-dev-tech
# Repository: https://github.com/Michael-dev-tech/eOS
# Description: This script checks the health of the system where eOS is
#              installed, reporting on disk usage, system load, and logs.
# ==============================================================================

# --- Configuration ---
INSTALL_DIR="/opt/eOS"
LOG_DIR="$INSTALL_DIR/var/log"
HEALTH_REPORT_FILE="$LOG_DIR/health-report-$(date +%Y-%m-%d_%H-%M-%S).txt"
DISK_THRESHOLD=85 # Warn if disk usage is over this percentage
LOG_ROTATE_SIZE_KB=1024 # Rotate logs larger than 1MB (1024 KB)

# --- Colors for Output ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'

# --- Helper Functions ---

# Prints a formatted section header
print_header() {
    echo ""
    echo -e "${C_CYAN}===== $1 =====${C_RESET}"
}

# Checks if the eOS environment seems to be installed
check_eos_installation() {
    print_header "Verifying eOS Installation"
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${C_RED}Error: eOS installation directory not found at $INSTALL_DIR.${C_RESET}"
        echo "Please run the setup.sh script first."
        exit 1
    fi
    echo -e "${C_GREEN}eOS installation found.${C_RESET}"
}

# --- Health Check Functions ---

# 1. Checks disk space usage for the root partition
check_disk_usage() {
    print_header "Disk Usage Monitor"
    # Get usage percentage for the root filesystem, removing the '%' sign
    local usage
    usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "Root filesystem ('/') usage is at ${usage}%."

    if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${C_YELLOW}WARNING: Disk usage has exceeded the threshold of ${DISK_THRESHOLD}%.${C_RESET}"
    else
        echo -e "${C_GREEN}Disk space is within normal limits.${C_RESET}"
    fi
}

# 2. Checks system load and memory usage
check_system_load() {
    print_header "CPU & Memory Load"
    
    # Get load average
    local load_avg
    load_avg=$(uptime | awk -F'load average: ' '{print $2}')
    echo "CPU Load Average (1m, 5m, 15m): ${load_avg}"
    
    # Get memory usage
    echo "Memory Usage:"
    free -h | grep "Mem:" | sed 's/Mem\:/ /'
}

# 3. Lists the top 5 processes consuming the most memory
check_top_processes() {
    print_header "Top 5 Memory-Intensive Processes"
    # ps command: shows PID, User, %MEM, Command, sorted by memory usage
    ps -eo pid,user,%mem,comm --sort=-%mem | head -n 6
}

# 4. Manages the main eOS log file, rotating it if it's too large
manage_logs() {
    print_header "Log Management"
    local setup_log="/var/log/eOS_setup.log"
    
    if [ ! -f "$setup_log" ]; then
        echo -e "${C_YELLOW}Setup log not found at $setup_log.${C_RESET}"
        return
    fi

    # Get file size in kilobytes
    local log_size_kb
    log_size_kb=$(du -k "$setup_log" | cut -f1)

    echo "Current setup log size: ${log_size_kb} KB."

    if [ "$log_size_kb" -gt "$LOG_ROTATE_SIZE_KB" ]; then
        echo -e "${C_YELLOW}Log file exceeds ${LOG_ROTATE_SIZE_KB} KB. Rotating...${C_RESET}"
        # Simple rotation: just rename the old file
        mv "$setup_log" "${setup_log}.$(date +%Y%m%d).bak"
        touch "$setup_log" # Create a new empty log file
        echo -e "${C_GREEN}Log rotated successfully.${C_RESET}"
    else
        echo -e "${C_GREEN}Log file size is normal.${C_RESET}"
    fi
}

# --- Main Execution ---
main() {
    echo -e "${C_BLUE}eOS System Health Check Utility Initializing...${C_RESET}"
    
    check_eos_installation
    
    # Generate report by redirecting function output to the report file
    {
        echo "eOS Health Report - Generated on $(date)"
        echo "=================================================="
        
        # We need to capture the output of our functions
        # This is a bit tricky with colors, so we'll call them
        # again without colors for the report.
        
        echo -e "\n--- Disk Usage ---"
        df -h /
        
        echo -e "\n--- System Load ---"
        uptime
        free -m
        
        echo -e "\n--- Top 5 Memory Processes ---"
        ps -eo pid,user,%mem,comm --sort=-%mem | head -n 6
        
        echo -e "\n--- Log Status ---"
        du -h /var/log/eOS_setup.log 2>/dev/null || echo "Log file not found."
        
    } > "$HEALTH_REPORT_FILE"
    
    # Run checks with colors for the console
    check_disk_usage
    check_system_load
    check_top_processes
    manage_logs
    
    print_header "Report Generation"
    echo -e "${C_GREEN}System health report has been saved to:${C_RESET}"
    echo "$HEALTH_REPORT_FILE"
    echo ""
}

# Run the main function
main
