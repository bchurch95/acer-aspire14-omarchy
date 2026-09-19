# Acer Aspire 14 (Lunar Lake) Power, Shell & System Configuration for Omarchy / Arch Linux

Comprehensive hardware notes, validated configurations, and one-command restoration tool for the **Acer Aspire 14 (`Aspire A14-52M`)** running **Omarchy 4.0.1 / Arch Linux** on the **Intel Core Ultra 5 226V (Lunar Lake)** platform.

---

## 🚀 Quick Restore to a New Computer

To restore this entire setup (configurations, keybinds, bar widgets, terminal configs, sleep drop-ins, and shell plugins) onto a new Omarchy installation:

```bash
git clone https://github.com/bchurch95/acer-aspire14-omarchy-config.git ~/Work/acer-aspire14-omarchy-config
cd ~/Work/acer-aspire14-omarchy-config
./restore.sh --all
```

Or run interactively:
```bash
./restore.sh
```

---

## Hardware Specifications

- **Device:** Acer Aspire 14 (`Aspire A14-52M`)
- **CPU:** Intel Core Ultra 5 226V (Lunar Lake, 8-core / 8-thread)
- **GPU:** Intel Arc Graphics (Lunar Lake Xe2 / `xe` driver)
- **OS / Kernel:** Omarchy 4.0.1 / Linux Kernel `7.1.9-arch1-2`
- **Bootloader:** Limine with Unified Kernel Images (UKIs)
- **Desktop:** Hyprland (Wayland) + Omarchy Quickshell

---

## 1. Sleep & Suspend Architecture (`s2idle`)

### Key Findings & Fixes
1. **Intel Lunar Lake Sleep State:**
   - Intel Core Ultra Lunar Lake silicon **only supports `s2idle` (Modern Standby / S0 Low-Power Idle)**. Legacy S3 sleep (`deep`) is not supported by the silicon architecture.
   - `/sys/power/mem_sleep` must remain `[s2idle]`.
2. **ACPI Interrupt Masking Warning (`acpi_mask_gpe=0x6E`):**
   - **DO NOT mask GPE `0x6E` in the kernel commandline.**
   - Earlier attempts to mask `0x6E` blocked the Embedded Controller (EC) from managing sleep/wake transactions, resulting in immediate suspend abort loops (`PM: Triggering wakeup from IRQ 9`).
   - GPE `0x6E` must remain unmasked and enabled. Under normal operation with clean bootloader entries, it does not storm.
3. **Power LED Behavior:**
   - On this Acer model under `s2idle`, the power LED stays solid on rather than blinking (pulsing was an S3 indicator). The display, keyboard backlight, and internal fans turn off, and the CPU enters deep Package C10 sleep.
4. **Systemd Watchdog Expiration During Sleep Fix (`WatchdogSec=0`):**
   - Under `s2idle`, system monotonic clocks advance while userland daemons remain frozen. Because daemons cannot ping `sd_notify` heartbeats while sleeping, systemd's default `WatchdogSec=3min` timer expires during suspends longer than 3 minutes.
   - Upon resume, systemd PID 1 aborted core daemons (`systemd-logind`, `systemd-journald`, `systemd-udevd`, `bolt`) with `SIGABRT` (`Watchdog timeout (limit 3min)`), breaking desktop sessions and leaving NetworkManager asleep / Wi-Fi disconnected.
   - Fixed by deploying `/etc/systemd/system/service.d/10-disable-watchdog.conf` with `WatchdogSec=0`.
5. **UCSI ACPI Firmware Quirk (`ucsi_acpi`):**
   - The Acer EC firmware contains an internal ACPI table mismatch that logs `ucsi_acpi USBC000:00: bogus connector number in CCI: 2`. This is a cosmetic firmware reporting quirk that does not impact USB-C charging or DisplayPort functionality. With the watchdog fix in place, these interrupts do not cause daemon aborts upon wake.

---

## 2. Bootloader & Kernel Configuration (`Limine`)

All kernel command line drop-ins are located in `/etc/limine-entry-tool.d/` (copies backed up in `configs/limine-entry-tool.d/`):

- **`/etc/limine-entry-tool.d/rtc-alarm.conf`**:
  ```ini
  KERNEL_CMDLINE[default]+=" rtc_cmos.use_acpi_alarm=1"
  ```
- **`/etc/limine-entry-tool.d/omarchy-defaults.conf`**:
  ```ini
  TARGET_OS_NAME="Omarchy"
  KERNEL_CMDLINE[default]+=" quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"
  KERNEL_CMDLINE[default]+=" initramfs_async=0"
  CUSTOM_UKI_NAME="omarchy"
  ENABLE_LIMINE_FALLBACK=yes
  FIND_BOOTLOADERS=yes
  BOOT_ORDER="*, *fallback, Snapshots"
  MAX_SNAPSHOT_ENTRIES=6
  SNAPSHOT_FORMAT_CHOICE=5
  ```
- **`/etc/limine-entry-tool.d/resume.conf`**:
  ```ini
  KERNEL_CMDLINE[default]+=" resume=/dev/mapper/root resume_offset=1901559"
  ```

### To Regenerate Bootloader Entries & UKIs:
```bash
sudo limine-update
```

---

## 3. Modprobe Configurations (`/etc/modprobe.d/`)

Backed up in `configs/modprobe.d/`:

- **`omarchy-usb-autosuspend.conf`**:
  ```ini
  options usbcore autosuspend=-1
  ```
- **`hid_apple.conf`**:
  ```ini
  options hid_apple fnmode=2
  ```

---

## 4. Systemd, Lock & Watchdog Management

### Logind Configuration (`/etc/systemd/logind.conf.d/`)
Backed up in `configs/logind.conf.d/`:

- **`10-ignore-power-button.conf`**:
  ```ini
  [Login]
  HandlePowerKey=ignore
  ```
- **`20-inhibit-delay.conf`**:
  ```ini
  [Login]
  InhibitDelayMaxSec=15
  ```
  *(Provides Quickshell sufficient delay inhibitor time to lock all displays before logind enters suspend).*

### Global Service Watchdog Override (`/etc/systemd/system/service.d/`)
Backed up in `configs/systemd/service.d/`:

- **`10-disable-watchdog.conf`**:
  ```ini
  [Service]
  WatchdogSec=0
  ```
  *(Disables software watchdog aborts across all system services on wake from `s2idle`).*

---

## 5. Network & VPN Autoconnect

To prevent WireGuard VPNs from interfering with network reconnection upon waking from suspend, all WireGuard profiles have autoconnect disabled:

```bash
# Verify connection properties
nmcli -f NAME,TYPE,AUTOCONNECT connection show
```

| Name | Type | Autoconnect |
| :--- | :--- | :--- |
| `Media` (Wi-Fi) | 802-11-wireless | **yes** |
| `Church Farms` | wireguard | **no** |
| `Cloudflare WARP` | wireguard | **no** |
| `Elm` | wireguard | **no** |

---

## 6. Verification Script

To test the system anytime, run:

```bash
./verify-sleep.sh
```

Or manually test suspend:

```bash
sleep 2 && systemctl suspend
```

---

## 7. Apple Music Web App & Chrome Media Controls Isolation

### Problem
By default, Google Chrome enables `HardwareMediaKeyHandling` and registers an MPRIS media player on D-Bus for every media stream in browser tabs (e.g., YouTube, Twitter/X, Reddit). When running Apple Music as a web app attached to the default browser session, browsing tabs continually steal the media session and hardware media keys (Play/Pause, Next, Previous).

### Solution Architecture
1. **Disable Chrome Browser Media Key Stealing**:
   Add `--disable-features=HardwareMediaKeyHandling` to `~/.config/chrome-flags.conf` (backed up in `configs/chrome-flags.conf`). Regular browser tabs will no longer hijack hardware media keys or register MPRIS players on D-Bus.

2. **Isolated Apple Music Web App Launcher (`~/.local/bin/apple-music`)**:
   Runs Apple Music in a dedicated `--user-data-dir` (`~/.local/share/omarchy/webapps/apple-music`) with explicit `--enable-features=HardwareMediaKeyHandling,MediaSessionService` enabled. This gives Apple Music an isolated D-Bus MPRIS endpoint and dedicated hardware media key control without interference from regular browsing tabs.
   - Script backed up in `configs/local-bin/apple-music`.

3. **Desktop Launcher (`~/.local/share/applications/Apple Music.desktop`)**:
   Configured to launch `apple-music` with `StartupWMClass=apple-music`.
   - Backed up in `configs/applications/Apple Music.desktop`.

4. **Hyprland Keybinding (`~/.config/hypr/bindings.lua`)**:
   - `SUPER + SHIFT + M`: Launch or focus Apple Music (`apple-music`).
   - Backed up in `configs/hypr/bindings.lua`.

---

## 8. Custom Hyprland Keybindings (`~/.config/hypr/bindings.lua`)

All custom shortcuts and overrides are defined in `~/.config/hypr/bindings.lua` (backed up in `configs/hypr/bindings.lua`):

| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `SUPER + A` | **Select all** | Universal shortcut that sends `Ctrl + A` to the active application. |
| `SUPER + T` | **New tab** | Universal shortcut that sends `Ctrl + T` in standard apps (or `Ctrl + Shift + T` in terminals). |
| `SUPER + ALT + T` | **Toggle floating** | Toggles active window between floating and tiled layout (rebound from `Super + T`). |
| `SUPER + SHIFT + A` | **Antigravity** | Launches Antigravity agent terminal with `--dangerously-skip-permissions`. |
| `SUPER + SHIFT + M` | **Apple Music** | Launches or focuses the isolated Apple Music web app. |
| `SUPER + SHIFT + RETURN` | **Chrome (Personal)** | Opens personal Chrome profile directly bypassing profile picker. |
| `SUPER + CTRL + SHIFT + RETURN` | **Chrome (Work)** | Opens work Chrome profile directly bypassing profile picker. |

---

## 9. Shell Plugins & Status Bar Ecosystem

All custom and forked shell plugins are synchronized using the centralized [`bchurch95/omarchy-plugins`](https://github.com/bchurch95/omarchy-plugins) repository.

| Plugin ID | Name | Source / Fork | Description |
| :--- | :--- | :--- | :--- |
| `ben.menu` | My Menu | [`bchurch95/omarchy-menu`](https://github.com/bchurch95/omarchy-menu) | Quake II emblem menu button and command launcher. |
| `ben.network` | My Network | [`bchurch95/omarchy-network`](https://github.com/bchurch95/omarchy-network) | Keeps underlying Wi-Fi visible when VPN is active. |
| `ben.media` | My Media | [`bchurch95/omarchy-media`](https://github.com/bchurch95/omarchy-media) | MPRIS widget with wide next button and marquee scroll. |
| `ben.agents` | My Agents | [`bchurch95/omarchy-agents-plugin`](https://github.com/bchurch95/omarchy-agents-plugin) | Antigravity, Claude Code, Codex token tracker. |
| `ben.apple-music-button` | Apple Music Button | [`bchurch95/omarchy-apple-music-button`](https://github.com/bchurch95/omarchy-apple-music-button) | Compact Apple Music scratchpad toggle. |
| `io.github.jainprashul.omacast` | Oma Cast | [`bchurch95/oma-cast`](https://github.com/bchurch95/oma-cast) | Chromecast audio streaming from the status bar. |
| `io.github.vuhungthang.monitor-studio` | Monitor Studio | [`bchurch95/omarchy-monitor-studio`](https://github.com/bchurch95/omarchy-monitor-studio) | Visual multi-display profile & layout manager. |
| `omamail` | Omamail | [`bchurch95/omamail`](https://github.com/bchurch95/omamail) | Fastmail / iCloud IMAP / Gmail / HEY mail client. |
| `io.github.etroll.omarchy-airplay` | AirPlay & HomePods | [`bchurch95/omarchy-airplay`](https://github.com/bchurch95/omarchy-airplay) | Apple HomePod AirPlay 2 synchronized multi-room streaming & screen mirror. |
| `io.github.thisisgm.omapods` | AirPods | [`bchurch95/omarchy-pods`](https://github.com/bchurch95/omarchy-pods) | AirPods battery and ANC mode switcher. |
| `jkoestinger.vpn` | VPN Switcher | [`bchurch95/omarchy-vpn-jkoestinger`](https://github.com/bchurch95/omarchy-vpn-jkoestinger) | Proton / Mullvad / WireGuard VPN selector. |
| `nosignal.omasend` | Omasend | [`bchurch95/omasend-quattro`](https://github.com/bchurch95/omasend-quattro) | LocalSend LAN transfer engine. |
| `jankeesvw.time-machine` | Time Machine | [`jankeesvw/time-machine`](https://github.com/jankeesvw/time-machine) | Restic snapshot browser and scheduler. |

### Custom Bar Modules (`configs/omarchy/bar/modules/`)
- `sysinfo.qml`: Live CPU & Memory graph module with click-to-launch `btop`.
- `kdeconnect.qml`: Phone connectivity, clipboard sync, and ping module.

---

## 10. Backup Contents & Repository Structure

```
.
├── apply-power-fixes.sh                     # Hardware power, ASPM & battery limit suite
├── restore.sh                               # One-command restoration tool
├── verify-sleep.sh                          # Sleep state validation test
├── README.md                                # System and architecture documentation
└── configs/
    ├── applications/                        # Desktop entry files (.desktop)
    ├── bash/                                # Shell aliases and environment additions
    ├── chrome-flags.conf                    # Hardware media keys override
    ├── hypr/                                # Hyprland bindings, looknfeel, input, monitors
    ├── icons/                               # Application icons
    ├── limine-entry-tool.d/                 # Kernel cmdline and bootloader entries (aspm, uki)
    ├── local-bin/                           # Custom launcher scripts
    ├── logind.conf.d/                       # Systemd lock inhibitors
    ├── modprobe.d/                          # Kernel driver options
    ├── omarchy/
    │   ├── bar/modules/                     # Custom QML bar modules (sysinfo, kdeconnect)
    │   ├── shell.json                       # Exact status bar layout and plugin order
    │   └── smb/shares.json                  # SMB network shares setup
    ├── packages/
    │   └── explicit-packages.txt            # Explicit pacman/yay package manifest
    ├── plugins/                             # Local plugin sources
    ├── ssh/                                 # Server SSH configuration
    ├── sysctl.d/                            # Kernel sysctl parameters (NMI watchdog disable)
    ├── systemd/
    │   └── service.d/                       # Global service watchdog overrides
    ├── terminals/                           # Alacritty, Ghostty, Kitty, Foot font configs
    ├── themes/                              # Custom themes (purple-rising, q2dm1)
    ├── tmpfiles.d/                          # Systemd tmpfiles (PCIe ASPM powersave policy)
    └── udev/
        └── rules.d/                         # Dynamic AC/Battery power profile switching
```

---

## 11. Acer Platform Power, Thermal & Battery Management

Acer routes platform profiles, fan curves, and battery features through proprietary ACPI-WMI calls directly to the Embedded Controller (EC). Under Linux on the **Acer Aspire 14 (`Aspire A14-52M`, Lunar Lake)**, the architecture operates as follows:

### 1. ACPI / WMI & Platform Profiles
* **Mainline `acer-wmi` Driver:** Mainline Linux connects to basic hotkeys, rfkill switches, and video devices. On this Lunar Lake chassis, `/sys/firmware/acpi/platform_profile_choices` is not natively exposed by mainline `acer-wmi`.
* **Userspace Fallback:** `power-profiles-daemon` falls back to `CpuDriver: intel_pstate` with `PlatformDriver: placeholder`. Power scaling is handled directly at the silicon level via Energy Performance Preference (EPP) registers.

### 2. CPU Power Scaling & Dynamic AC/Battery Switching
* Managed by the `intel_pstate` driver with governor `powersave`.
* Switching profiles via `powerprofilesctl set balanced` or `power-saver` dynamically writes to `/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`.
* **Dynamic AC/Battery Udev Rule:** Located at `configs/udev/rules.d/99-power-profile-switch.rules`. Automatically transitions the laptop to `power-saver` (EPP: `power`) when the charger is unplugged, and restores `balanced` (EPP: `balance_performance`) when plugged back into AC.

### 3. Intel DPTF / Thermald Adaptive Mode
* `thermald.service` runs automatically with `--adaptive` (`/usr/bin/thermald --systemd --dbus-enable --adaptive`).
* The kernel loads `int3400_thermal`, `int3403_thermal`, and `int340x_thermal_zone`.
* The `INT3400 Thermal` zone operates under `user_space` policy, actively enforcing OEM Dynamic Tuning Technology (DTT) tables found in the ACPI DSDT to prevent thermal throttling without needing proprietary Windows utilities.

### 4. 80% Battery Health Threshold (`health_mode`) & Status Bar Widget
* Acer Care Center manages battery limits over WMI GUID `79772EC5-04B1-4BFD-843C-61E7F77B6CC9`.
* This repository includes the DKMS package definition `acer-wmi-battery-dkms` which binds to this exact WMI GUID and exposes the driver interface at `/sys/bus/wmi/drivers/acer-wmi-battery/health_mode`.
* Configured permanently on boot via `/etc/modprobe.d/acer-wmi-battery.conf` (`options acer_wmi_battery enable_health_mode=1`).
* **Omarchy Status Bar Widget Integration (`ben.power`):**
  * Click the Battery widget in the Omarchy bar to open the popup panel.
  * Under **BATTERY CHARGE LIMIT**, toggle between `[ 󱐌 80% Cap ]` and `[ 󰁹 100% Full ]`.
  * **Quick Toggle:** Middle-click the battery icon directly on the status bar to toggle the 80% cap without opening the popup!
* **Command Line Control:**
  ```bash
  acer-battery-limit status   # Returns "on" or "off"
  acer-battery-limit toggle   # Toggles between 80% and 100%
  acer-battery-limit on       # Enforce 80% cap
  acer-battery-limit off      # Allow 100% charge
  ```

### 5. PCIe Active State Power Management (ASPM)
* By default, PCIe ASPM policy is initialized as `[default]`, which may leave NVMe drives, Wi-Fi 7 controllers, and bridge interconnects in higher-power link states.
* Configured permanently to `powersave` via `/etc/tmpfiles.d/aspm.conf` and `configs/limine-entry-tool.d/aspm.conf`:
  ```bash
  cat /sys/module/pcie_aspm/parameters/policy
  # Output: default performance [powersave] powersupersave
  ```

### 6. Kernel NMI Watchdog Disabling (Deep Package C-States)
* The kernel NMI watchdog periodically interrupts CPU cores, preventing the Lunar Lake SoC package from remaining in deep **Package C8 / C10** low-power states.
* Disabled via `configs/sysctl.d/20-nmi-watchdog.conf`:
  ```ini
  kernel.nmi_watchdog = 0
  ```

### 7. Real-Time Discharge Tuning (`powertop`)
* Use `sudo powertop` on battery to inspect real-time discharge wattage.
* A well-tuned Lunar Lake laptop idling with low screen brightness typically draws **3.5W to 5.0W**.

### 8. One-Command Application
Run the included optimization tool to deploy ASPM policies, NMI watchdog sysctl, dynamic udev rules, and install the battery threshold driver:
```bash
cd ~/Work/acer-aspire14-omarchy-config
./apply-power-fixes.sh
```

