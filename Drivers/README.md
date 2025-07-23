# UC-1 Pro Drivers Directory

This directory contains scripts and references for system drivers needed for UC-1 Pro.

## NVIDIA Driver

**Version**: 570.172.08  
**Release Date**: July 17, 2025  
**Compatibility**: RTX 5090, RTX 5080, RTX 5070 series  
**Type**: Linux 64-bit

### Installation

Use the provided installation script:

```bash
sudo ./install-nvidia-driver.sh
```

### NVIDIA Container Toolkit

After installing the driver, install the container toolkit:

```bash
sudo ./install-nvidia-container-toolkit.sh
```

## BIOS Updates

**Motherboard**: ASUS TUF GAMING Z790-PLUS WIFI  
**Latest BIOS**: Version 1820 (2025/05/21)  
**System BIOS**: Version 1604 (12/15/2023) - Update recommended

**File**: TUF-GAMING-Z790-PLUS-WIFI-ASUS-1820.CAP

Store BIOS file in `Drivers/BIOS/` directory.
