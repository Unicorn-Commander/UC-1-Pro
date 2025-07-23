# ASUS TUF Gaming Z790-PLUS WIFI BIOS Settings for UC-1 Pro

**Motherboard**: ASUS TUF Gaming Z790-PLUS WIFI  
**BIOS Version**: 1820 (Updated from 1604)  
**Purpose**: Optimize for NVIDIA RTX 5090 and eliminate ACPI errors

## Quick Access
1. Press **DEL** during boot to enter BIOS
2. Press **F7** to enter Advanced Mode
3. Apply settings below
4. Press **F10** to Save & Exit

## Required Settings for RTX 5090

### Advanced → System Agent Configuration → PCI Express Configuration
- **Above 4G Decoding**: **Enabled** ✅
- **Re-Size BAR Support**: **Enabled** ✅
- **SR-IOV Support**: **Disabled**
- **PCI Express Native Power Management**: **Disabled** ✅
- **ASPM (Active State Power Management)**: **Disabled** ✅

### Advanced → PCH Configuration → PCI Express Configuration
- **PCIe Speed**: **Auto** (or Gen4 if stable)
- **ASPM**: **Disabled** ✅
- **L1 Substates**: **Disabled**
- **PCIe Spread Spectrum**: **Disabled**

### Advanced → Platform Misc Configuration
- **PCI Express Native Control**: **Disabled**
- **Native ASPM**: **Disabled**

### Advanced → CPU Configuration → Power Management Control
- **Intel SpeedStep**: **Enabled** (for CPU efficiency)
- **Intel Speed Shift**: **Enabled**
- **C-States**: **Enabled** (doesn't affect GPU)
- **Package C State Limit**: **C10**

### Boot → CSM (Compatibility Support Module)
- **Launch CSM**: **Disabled** (Pure UEFI mode)

### Boot → Secure Boot
- **Secure Boot**: **Enabled** (since you have it working)
- **Secure Boot Mode**: **Standard**

## Optional Performance Settings

### AI Tweaker (for stability)
- **AI Overclock Tuner**: **XMP I** (if using XMP memory)
- **DIGI+ VRM**: 
  - CPU Load-line Calibration: **Level 3-4**
  - CPU Power Phase Control: **Extreme**

### Advanced → Onboard Devices Configuration
- **HD Audio Controller**: **Enabled**
- **USB power delivery in Soft Off state**: **Disabled**
- **Serial Port Configuration**: **Disabled** (unless needed)

## Settings That Fix ACPI Errors

The key settings that resolve the ACPI BIOS errors are:
1. **ASPM Disabled** - Prevents power state conflicts
2. **Above 4G Decoding Enabled** - Proper GPU memory mapping
3. **Native Power Management Disabled** - Avoids duplicate power controls
4. **Re-Size BAR Enabled** - Better GPU performance & compatibility

## After Applying Settings

1. Save and exit BIOS (F10)
2. Boot into Ubuntu
3. Verify GPU is detected:
   ```bash
   nvidia-smi
   ```
4. Check for remaining ACPI errors:
   ```bash
   sudo dmesg | grep ACPI | tail -20
   ```

## Notes

- BIOS 1820 includes better RTX 40-series support than 1604
- These settings prioritize stability over power saving
- ACPI errors may still appear briefly during boot but should be reduced
- If errors persist, they're cosmetic and don't affect operation

## Future BIOS Updates

Check for updates at: https://www.asus.com/us/motherboards-components/motherboards/tuf-gaming/tuf-gaming-z790-plus-wifi/helpdesk_bios

Consider updating if:
- New version mentions "Improved NVIDIA GPU compatibility"
- "Fixed ACPI tables" in changelog
- "RTX 50-series support" (when available)

## Troubleshooting

If system won't boot after changes:
1. Power off completely
2. Clear CMOS (remove battery or use jumper)
3. Re-enter BIOS and load defaults
4. Re-apply settings one section at a time

---
*Document created for UC-1 Pro by Magic Unicorn Unconventional Technology & Stuff Inc*