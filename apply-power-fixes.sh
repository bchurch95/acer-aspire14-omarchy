#!/usr/bin/env bash
# ==============================================================================
# Acer Aspire 14 (Lunar Lake) Power, Thermal & Battery Optimization Script
# Repository: https://github.com/bchurch95/acer-aspire14-omarchy-config
# ==============================================================================

set -euo pipefail

BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

log_info()    { echo "${BLUE}${BOLD}==>${RESET} $*"; }
log_success() { echo "${GREEN}${BOLD} [OK]${RESET} $*"; }
log_warn()    { echo "${YELLOW}${BOLD}[WARN]${RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

echo "${BOLD}====================================================================${RESET}"
echo "${BOLD}  Acer Aspire 14 Power, Thermal & Battery Optimization Suite       ${RESET}"
echo "${BOLD}====================================================================${RESET}"

# 1. Request sudo upfront
log_info "Acquiring root permissions for hardware sysfs & bootloader configs..."
sudo -v

# Keep sudo alive during the script run
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill "$SUDO_PID" 2>/dev/null || true' EXIT

# 2. Configure PCIe ASPM (Active State Power Management)
log_info "Configuring PCIe ASPM powersave policy..."
sudo mkdir -p /etc/tmpfiles.d
sudo cp -v "$CONFIGS_DIR/tmpfiles.d/aspm.conf" /etc/tmpfiles.d/aspm.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/aspm.conf || true

if [[ -f "$CONFIGS_DIR/limine-entry-tool.d/aspm.conf" && -d /etc/limine-entry-tool.d ]]; then
  sudo cp -v "$CONFIGS_DIR/limine-entry-tool.d/aspm.conf" /etc/limine-entry-tool.d/aspm.conf
  if command -v limine-update >/dev/null 2>&1; then
    log_info "Updating Limine bootloader entries..."
    sudo limine-update || true
  fi
fi
log_success "PCIe ASPM powersave policy deployed."

# 3. Disable Kernel NMI Watchdog (allows Package C8/C10 sleep)
log_info "Disabling Kernel NMI Watchdog to enable deep Package C-states..."
if [[ -f "$CONFIGS_DIR/sysctl.d/20-nmi-watchdog.conf" ]]; then
  sudo mkdir -p /etc/sysctl.d
  sudo cp -v "$CONFIGS_DIR/sysctl.d/20-nmi-watchdog.conf" /etc/sysctl.d/20-nmi-watchdog.conf
  sudo sysctl -w kernel.nmi_watchdog=0 >/dev/null 2>&1 || true
  log_success "Kernel NMI Watchdog disabled."
fi

# 4. Automatic AC / Battery Power Profile Switching (udev rule)
log_info "Configuring automatic AC/Battery power profile switching via udev..."
if [[ -f "$CONFIGS_DIR/udev/rules.d/99-power-profile-switch.rules" ]]; then
  sudo mkdir -p /etc/udev/rules.d
  sudo cp -v "$CONFIGS_DIR/udev/rules.d/99-power-profile-switch.rules" /etc/udev/rules.d/99-power-profile-switch.rules
  sudo udevadm control --reload-rules 2>/dev/null || true
  sudo udevadm trigger --subsystem-match=power_supply 2>/dev/null || true
  log_success "AC/Battery dynamic power profile udev rule installed."
fi

# 5. CPU EPP & Power Profiles Daemon
log_info "Configuring CPU Energy Performance Preference (EPP)..."
if command -v powerprofilesctl >/dev/null 2>&1; then
  powerprofilesctl set balanced
  log_success "Power profile set to balanced (CPU EPP: balance_performance)."
fi

# 6. Install PowerTop for diagnostics
if ! command -v powertop >/dev/null 2>&1; then
  log_info "Installing powertop for real-time power diagnostics..."
  sudo pacman -S --needed --noconfirm powertop 2>/dev/null || true
fi

# 7. Battery Charge Threshold (80% Care Center Limit via WMI)
log_info "Configuring Acer Battery Threshold Driver (acer-wmi-battery)..."
if [[ -f "$CONFIGS_DIR/modprobe.d/acer-wmi-battery.conf" ]]; then
  sudo cp -v "$CONFIGS_DIR/modprobe.d/acer-wmi-battery.conf" /etc/modprobe.d/acer-wmi-battery.conf
fi

if ! lsmod | grep -q "acer_wmi_battery"; then
  if ! pacman -Qi acer-wmi-battery-dkms >/dev/null 2>&1 && ! pacman -Qi acer-wmi-battery-dkms-git >/dev/null 2>&1; then
    log_info "Installing acer-wmi-battery-dkms via AUR..."
    if command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm dkms acer-wmi-battery-dkms || true
    fi
  fi
  sudo modprobe acer-wmi-battery enable_health_mode=1 2>/dev/null || true
fi

# Apply 80% threshold to driver sysfs node
WMI_HEALTH_NODE="/sys/bus/wmi/drivers/acer-wmi-battery/health_mode"
if [[ -w "$WMI_HEALTH_NODE" ]]; then
  echo 1 | sudo tee "$WMI_HEALTH_NODE" >/dev/null
  log_success "Battery Health Mode set to 1 (80% charge limit active)."
elif [[ -w /sys/class/power_supply/BAT1/charge_control_end_threshold ]]; then
  echo 80 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold >/dev/null
  log_success "Battery charge limit set to 80% (/sys/class/power_supply/BAT1/charge_control_end_threshold)."
else
  log_warn "Battery health control node not yet writable (reboot may be required if DKMS just built)."
fi

# 8. Summary Verification
echo ""
echo "${BOLD}----------------- Power & Hardware Verification -----------------${RESET}"
echo -n "  PCIe ASPM Policy:     "
cat /sys/module/pcie_aspm/parameters/policy 2>/dev/null || echo "N/A"
echo -n "  Active Power Profile: "
powerprofilesctl get 2>/dev/null || echo "N/A"
echo -n "  CPU0 EPP State:       "
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A"
echo -n "  NMI Watchdog:         "
cat /proc/sys/kernel/nmi_watchdog 2>/dev/null || echo "N/A"
echo -n "  Battery Health Mode:  "
if [ -f "$WMI_HEALTH_NODE" ]; then
  val=$(cat "$WMI_HEALTH_NODE" 2>/dev/null || echo "0")
  if [ "$val" = "1" ]; then
    echo "Active (80% charge limit enforced)"
  else
    echo "Disabled ($val)"
  fi
elif [ -f /sys/class/power_supply/BAT1/charge_control_end_threshold ]; then
  echo "Active ($(cat /sys/class/power_supply/BAT1/charge_control_end_threshold)% limit)"
else
  echo "Not exposed"
fi
echo -n "  Intel DTT / Thermald: "
systemctl is-active thermald 2>/dev/null || echo "N/A"
echo -n "  Intel LPMD (SoC Low Power): "
systemctl is-active intel_lpmd 2>/dev/null || echo "N/A"
echo "${BOLD}-----------------------------------------------------------------${RESET}"
echo ""
log_success "All power optimizations verified!"
