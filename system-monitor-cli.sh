#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' 

create_bar() {
    local percent=$1   
    local width=50
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local color

    if [ $percent -ge 80 ]; 
    then
        color=$RED
    elif [ $percent -ge 60 ]; 
    then
        color=$YELLOW
    else
        color=$GREEN
    fi

    printf "["
    printf "${color}"
    printf "%${filled}s" | tr ' ' '|'
    printf "${NC}"
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3d%%\n" $percent
}

get_system_info() {
    local chassis=$(hostnamectl | grep "Chassis:" | awk '{for(i=2;i<=NF;i++){printf "%s ",$i};print ""}')
    local model=$(lscpu | grep "^Model name:" | awk '{for(i=3;i<=NF;i++){printf "%s ",$i};print ""}')
    local cpu_count=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    local arch=$(hostnamectl | grep "Architecture:" | awk '{print $2}')
    local os=$(hostnamectl | grep "Operating System:" | awk '{for(i=3;i<=NF;i++){printf "%s ",$i};print ""}')
    local kernel=$(hostnamectl | grep "Kernel:" | awk '{for(i=3;i<=NF;i++){printf "%s ",$i};print ""}')
    local bootmode=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
    local pve_manager=""
    if command -v pveversion >/dev/null 2>&1; then
        pve_manager=$(pveversion | awk '{print $1}')
    fi
    
    echo "$chassis|$model|$cpu_count|$arch|$os|$kernel|$bootmode|$pve_manager"
}

get_cpu_usage() {
    local cpu_usage=$(LC_NUMERIC=C top -bn1 | grep "Cpu(s)" | sed 's/[,%]/ /g' | awk '{print int($2)}')
    local cpu_freq=$(grep "cpu MHz" /proc/cpuinfo | head -n1 | cut -d: -f2 | sed 's/^[ \t]*//' | cut -d. -f1)
    
    local cpu_temp=""
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ] ; 
    then
        cpu_temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    elif command -v sensors >/dev/null 2>&1; then
        cpu_temp=$(sensors | grep -i "CPU Temperature" | awk '{print $3}' | tr -d '+°C')
        if [ -z "$cpu_temp" ]; 
        then
            cpu_temp=$(sensors | grep -i "Package id 0:" | awk '{print $4}' | tr -d '+°C')
        fi
    fi
    
    local physical_cores=$(lscpu | grep "^Core(s) per socket:" | awk '{print $4}')
    local sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}')
    local total_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    local threads_per_core=$(lscpu | grep "^Thread(s) per core:" | awk '{print $4}')
    
    local load_avg=$(cat /proc/loadavg)
    local load_1min=$(echo $load_avg | awk '{print $1}')
    local load_5min=$(echo $load_avg | awk '{print $2}')
    local load_15min=$(echo $load_avg | awk '{print $3}')
    
    local cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
    local max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo "0")
    if [ "$max_freq" != "0" ]; then
        max_freq=$((max_freq / 1000))
    else
        max_freq="N/A"
    fi
    
    echo "$cpu_usage|$cpu_freq|$cpu_temp|$physical_cores|$sockets|$total_cores|$threads_per_core|$load_1min|$load_5min|$load_15min|$cpu_governor|$max_freq"
}

get_memory_info() {
    local memory_info=$(free -b)
    local total=$(echo "$memory_info" | grep Mem | awk '{print $2}')
    local used=$(echo "$memory_info" | grep Mem | awk '{print $3}')
    local percent=$((used * 100 / total))
    local total_gb=$((total / 1024 / 1024 / 1024))
    local used_gb=$((used / 1024 / 1024 / 1024))
    echo "$percent|$total_gb|$used_gb"
}

get_swap_info() {
    local swap_info=$(free -b)
    local total=$(echo "$swap_info" | grep Swap | awk '{print $2}')
    local used=$(echo "$swap_info" | grep Swap | awk '{print $3}')
    local percent=0
    local total_gb=0
    local used_gb=0
    
    if [ $total -ne 0 ]; then
        percent=$((used * 100 / total))
        total_gb=$((total / 1024 / 1024 / 1024))
        used_gb=$((used / 1024 / 1024 / 1024))
    fi
    echo "$percent|$total_gb|$used_gb"
}

get_disk_info() {
    local result=""
    df -h | grep '^/dev/' | while read -r line; do
        local filesystem=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local avail=$(echo "$line" | awk '{print $4}')
        local use_percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mountpoint=$(echo "$line" | awk '{print $6}')
        echo "$filesystem|$size|$used|$avail|$use_percent|$mountpoint"
    done
}

get_network_info() {
    local interfaces=""
    for interface in $(ls /sys/class/net/ | grep -v "lo"); do
        local state=$(cat /sys/class/net/$interface/operstate)
        local speed=$(cat /sys/class/net/$interface/speed 2>/dev/null || echo "N/A")
        local ip_addr=$(ip addr show $interface | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
        local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
        local rx_mb=$((rx_bytes / 1024 / 1024))
        local tx_mb=$((tx_bytes / 1024 / 1024))
        
        interfaces+="$interface|$state|$speed|$ip_addr|$rx_mb|$tx_mb\n"
    done
    echo -e "$interfaces"
}

get_process_info() {
    local total_processes=$(ps aux | wc -l)
    local running_processes=$(ps aux | grep -c "R")
    local zombie_processes=$(ps aux | grep -c "Z")
    local top_cpu=$(ps aux --sort=-%cpu | head -n 6 | tail -n 5)

    echo "$total_processes|$running_processes|$zombie_processes|$top_cpu "
}

get_smart_status() {
    local smart_info=""
    if command -v smartctl >/dev/null 2>&1;
    then
        for disk in $(lsblk -d -o name | grep -E '^sd|^nvme|^hd' || true); do
            local status=$(smartctl -H /dev/$disk 2>/dev/null | grep "SMART overall-health" | awk '{print $6}' || echo "N/A")
            smart_info+="$disk|$status\n"
        done
    fi
    echo -e "$smart_info"
}

get_raid_status() {
    local raid_info=""
    if [ -f "/proc/mdstat" ]; then
        raid_info=$(cat /proc/mdstat | grep ^md)
    fi
    echo "$raid_info"
}

format_uptime() {
    local uptime_sec=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
    local days=$((uptime_sec/86400))
    local hours=$(((uptime_sec%86400)/3600))
    local minutes=$(((uptime_sec%3600)/60))
    echo "$days days, $hours hours, $minutes minutes"
}

# For clearing screen and set locale
export LC_NUMERIC=C
clear

echo -e "${BOLD}System Information${NC}"
echo "===================="

IFS='|' read -r chassis model cpu_count arch os kernel bootmode pve_manager <<< "$(get_system_info)"

printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Hostname:" "$(hostname)"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Chassis:" "$chassis"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Model:" "$model"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "CPU Cores:" "$cpu_count"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Architecture:" "$arch"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Operating System:" "$os"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Kernel:" "$kernel"
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Boot Mode:" "$bootmode"
if [ ! -z "$pve_manager" ]; then
    printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "PVE Manager:" "$pve_manager"
fi
printf "${BOLD}%-20s${NC} ${CYAN}%s${NC}\n" "Uptime:" "$(format_uptime)"

echo -e "\n${BOLD}Resource Usage${NC}"
echo "===================="

IFS='|' read -r cpu_percent cpu_freq cpu_temp physical_cores sockets total_cores threads_per_core load_1min load_5min load_15min cpu_governor max_freq <<< "$(get_cpu_usage)"
echo -e "${BOLD}CPU Status:${NC}"
printf "├─ Frequency: ${CYAN}%d MHz${NC}" "$cpu_freq"
if [ ! -z "$cpu_temp" ];
then
    printf " | Temperature: ${CYAN}%d°C${NC}" "$cpu_temp"
fi
printf "\n├─ Cores: ${CYAN}%d Physical${NC} | ${CYAN}%d Total${NC} (${CYAN}%d${NC} Socket(s), ${CYAN}%d${NC} Threads/Core)" \
    "$physical_cores" "$total_cores" "$sockets" "$threads_per_core"
printf "\n├─ Governor: ${CYAN}%s${NC}" "$cpu_governor"
if [ "$max_freq" != "N/A" ]; 
then
    printf " | Max Frequency: ${CYAN}%d MHz${NC}" "$max_freq"
fi
printf "\n├─ Load Average: ${CYAN}%.2f${NC} (1m), ${CYAN}%.2f${NC} (5m), ${CYAN}%.2f${NC} (15m)" \
    "$load_1min" "$load_5min" "$load_15min"
printf "\n├─ Usage: "
create_bar $cpu_percent

IFS='|' read -r mem_percent mem_total mem_used <<< "$(get_memory_info)"
echo -e "\n${BOLD}Memory Status:${NC}"
printf "├─ Total: ${CYAN}%d GB${NC} | Used: ${CYAN}%d GB${NC}\n" "$mem_total" "$mem_used"
printf "├─ Usage: "
create_bar $mem_percent

IFS='|' read -r swap_percent swap_total swap_used <<< "$(get_swap_info)"
echo -e "\n${BOLD}Swap Status:${NC}"
printf "├─ Total: ${CYAN}%d GB${NC} | Used: ${CYAN}%d GB${NC}\n" "$swap_total" "$swap_used"
printf "├─ Usage: "
create_bar $swap_percent

echo -e "\n${BOLD}Load Average:${NC} ${CYAN}$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')${NC}"

echo -e "\n${BOLD}Disk Information${NC}"
echo "===================="
while IFS='|' read -r filesystem size used avail use_percent mountpoint; do
    if [ ! -z "$filesystem" ]; 
    then
        echo -e "${BOLD}$filesystem ($mountpoint):${NC}"
        printf "├─ Size: ${CYAN}%s${NC} | Used: ${CYAN}%s${NC} | Available: ${CYAN}%s${NC}\n" "$size" "$used" "$avail"
        printf "├─ Usage: "
        create_bar $use_percent
    fi
done < <(get_disk_info)

echo -e "\n${BOLD}Network Interfaces${NC}"
echo "===================="
while IFS='|' read -r interface state speed ip_addr rx_mb tx_mb; do
    if [ ! -z "$interface" ]; then
        echo -e "${BOLD}$interface:${NC}"
        printf "├─ State: ${CYAN}%s${NC} | Speed: ${CYAN}%s${NC} Mbps | IP: ${CYAN}%s${NC}\n" "$state" "$speed" "$ip_addr"
        printf "├─ Traffic: RX: ${CYAN}%s MB${NC} | TX: ${CYAN}%s MB${NC}\n" "$rx_mb" "$tx_mb"
    fi
done < <(get_network_info)

echo -e "\n${BOLD}Process Information${NC}"
echo "===================="
IFS='|' read -r total_proc running_proc zombie_proc top_cpu <<< "$(get_process_info)"
printf "Total Processes: ${CYAN}%s${NC} | Running: ${CYAN}%s${NC} | Zombie: ${CYAN}%s${NC}\n" "$total_proc" "$running_proc" "$zombie_proc"
echo -e "\n${BOLD}Top CPU Processes:${NC}"
echo "$top_cpu"

smart_status=$(get_smart_status)
if [ ! -z "$smart_status" ]; then
    echo -e "\n${BOLD}Disk Health (SMART)${NC}"
    echo "===================="
    while IFS='|' read -r disk status; do
        if [ ! -z "$disk" ]; then
            printf "${BOLD}%s:${NC} ${CYAN}%s${NC}\n" "$disk" "$status"
        fi
    done <<< "$smart_status"
fi

raid_status=$(get_raid_status)
if [ ! -z "$raid_status" ];
then
    echo -e "\n${BOLD}RAID Status${NC}"
    echo "===================="
    echo -e "${CYAN}$raid_status${NC}"
fi