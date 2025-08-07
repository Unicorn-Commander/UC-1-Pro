#!/bin/bash
# Check Intel GPU status and availability

echo "=== Intel GPU Status Check ==="
echo

echo "1. CPU Information:"
lscpu | grep -E "Model name|Vendor ID" | sed 's/^/   /'
echo

echo "2. Graphics Devices:"
lspci | grep -E "VGA|Display" | sed 's/^/   /'
echo

echo "3. DRI Devices:"
if [ -d /dev/dri ]; then
    ls -la /dev/dri/ | sed 's/^/   /'
else
    echo "   /dev/dri not found - Intel GPU drivers may not be installed"
fi
echo

echo "4. Intel GPU Kernel Module (i915):"
if lsmod | grep -q i915; then
    lsmod | grep i915 | sed 's/^/   /'
else
    echo "   i915 module not loaded - Intel GPU may be disabled"
fi
echo

echo "5. OpenCL Devices:"
if command -v clinfo &> /dev/null; then
    clinfo 2>/dev/null | grep -E "Platform Name|Device Name" | sed 's/^/   /'
else
    echo "   clinfo not installed - install with: sudo apt install clinfo"
fi
echo

echo "6. Video/Render Groups:"
echo -n "   Current user ($USER) groups: "
groups $USER | grep -E "video|render" || echo "Not in video/render groups"
echo

echo "7. Intel GPU Packages:"
dpkg -l 2>/dev/null | grep -E "intel-(opencl|compute|graphics|media|level-zero)" | awk '{print "   " $2 " - " $3}'
if [ $? -ne 0 ] || [ -z "$(dpkg -l 2>/dev/null | grep -E 'intel-(opencl|compute|graphics|media|level-zero)')" ]; then
    echo "   No Intel GPU packages found"
fi
echo

echo "=== Recommendations ==="
if [ ! -d /dev/dri ]; then
    echo "• Intel GPU drivers are not installed or iGPU is disabled in BIOS"
    echo "• Check BIOS settings to ensure Intel iGPU is enabled (Multi-Monitor mode)"
    echo "• Run install-intel-gpu-runtime.sh to install drivers"
elif ! lsmod | grep -q i915; then
    echo "• Intel GPU kernel module is not loaded"
    echo "• Try: sudo modprobe i915"
elif ! groups $USER | grep -qE "video|render"; then
    echo "• Add user to video/render groups:"
    echo "  sudo usermod -a -G video,render $USER"
    echo "  Then logout and login again"
fi