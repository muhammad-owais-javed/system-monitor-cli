# system-monitor-cli

A lightweight CLI tool providing real-time system monitoring with colorized visualizations. Features comprehensive hardware information, resource monitoring, and health checks for Linux/Unix systems and Proxmox environments. Perfect for system administrators who need quick insights through an intuitive interface.

## Features

- Real-time system resource monitoring with colorized progress bars
- Comprehensive hardware information collection
- Memory and swap usage analysis
- Detailed CPU statistics and temperature monitoring
- Disk usage and health status (SMART)
- Network interface statistics
- Process monitoring with top CPU consumers
- RAID status monitoring
- Proxmox VE integration

## Prerequisites

- UNIX/Linux based OS
- Root/sudo privileges

### Optional dependencies:

- `smartmontools` - for SMART disk health monitoring
- `lm-sensors` - for CPU temperature reading
- `pveversion` - for Proxmox VE specific information

## Installation

```bash
# Clone the repository
git clone https://github.com/muhammad-owais-javed/system-monitor-cli.git

# Navigate to the directory
cd system-monitor-cli

# Make the script executable
chmod +x sysstat.sh
```

## Usage

```bash
sudo ./sysstat.sh
```

## Output Sections

### System Information
- Hardware specifications
- OS and kernel details
- Architecture and boot mode
- Uptime statistics

### Resource Usage
- CPU utilization and temperature
- Memory and swap usage
- Load averages
- Process statistics

### Storage Information
- Partition usage statistics
- Disk health status (SMART)
- RAID array status (if applicable)

### Network Statistics
- Interface status and speed
- IP configuration
- Traffic statistics (RX/TX)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/newFeature`)
3. Commit your changes (`git commit -m 'Add some New Feature'`)
4. Push to the branch (`git push origin feature/newFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Muhammad Owais Javed

## Acknowledgments

- Inspired by various system monitoring tools
- Thanks to the Linux community for valuable resources
- Special thanks to contributors and testers
