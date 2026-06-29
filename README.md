# system-monitor-cli

A lightweight CLI tool providing instant, comprehensive snapshot of system health with colorized visualizations. It is designed specifically for Linux systems and Proxmox environments to deliver quick insights into hardware, resources, and storage without the overhead of continuous monitoring tools. Perfect for quick checks or high load situations.

## Features

- Snapshot of system resources with colorized progress bars
- Comprehensive hardware information collection
- Memory and swap usage analysis
- Detailed CPU statistics and temperature monitoring
- Disk usage and health status (SMART)
- Native checks for ZFS pools, LVM volumes
- Network interface statistics
- Process monitoring with top CPU consumers
- RAID status monitoring
- Proxmox VE integration

## Prerequisites

- Linux based OS (Debian, Ubuntu, RHEL, Alpine, etc.) or Proxmox VE
- Bash shell

### Optional dependencies:

- `smartmontools` - for SMART disk health monitoring
- `lm-sensors` - for CPU temperature reading
- `pveversion` - for Proxmox VE specific information

## Installation

1. Clone the repository

```sh
git clone https://github.com/muhammad-owais-javed/system-monitor-cli.git
```

2. Navigate to the directory

```sh
cd system-monitor-cli
```

## Usage

Run as a standard user for basic system metrics:

```sh
./sysmon.sh
```
Run with sudo to unlock advanced storage metrics (SMART, RAID, LVM):

```sh
sudo ./sysmon.sh
```

## Output Sections

### System Information
- Hardware specifications
- OS and kernel details
- Architecture and boot mode
- Uptime statistics

### Resource Usage
- CPU utilization, frequency and temperature
- Memory and swap usage
- Load averages
- Process statistics

### Storage Information
- Partition usage statistics
- Disk health status (SMART)
- RAID array status (if applicable)
- ZFS pool status, and LVM volumes

### Network Statistics
- Interface status and speed
- IP configuration
- Traffic statistics (RX/TX)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Muhammad Owais Javed
