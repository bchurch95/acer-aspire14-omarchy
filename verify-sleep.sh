#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo " Acer Aspire 14 Power & Sleep Diagnostics "
echo "========================================="

echo ""
echo "1. Checking Kernel Command Line for dangerous masks..."
if grep -q "acpi_mask_gpe" /proc/cmdline; then
    echo "❌ WARNING: acpi_mask_gpe is present in /proc/cmdline! This can break sleep/EC handling."
else
    echo "✅ /proc/cmdline is clean (no acpi_mask_gpe)."
fi

echo ""
echo "2. Checking ACPI Interrupt Counts..."
grep -rn '[1-9]' /sys/firmware/acpi/interrupts/ || echo "No active non-zero interrupts found."

echo ""
echo "3. Checking Sleep Mode Support..."
echo "Supported sleep states: $(cat /sys/power/state)"
echo "Current mem_sleep mode: $(cat /sys/power/mem_sleep)"

echo ""
echo "4. Checking NetworkManager VPN Autoconnect..."
nmcli -f NAME,TYPE,AUTOCONNECT connection show

echo ""
echo "5. Testing s2idle sleep (suspending in 3 seconds)..."
echo "Press power button, open lid, or press key to wake."
sleep 3
systemctl suspend

echo ""
echo "✅ Resumed from sleep! Checking recent journal entries for s2idle entry/exit..."
journalctl -k -b --since "1 minute ago" | grep -E "PM:|suspend|wake|ACPI|s2idle" || true
