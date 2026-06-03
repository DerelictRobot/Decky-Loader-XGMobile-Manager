# XG Mobile Manager for Handheld Linux

> Native, UI-driven support for the ASUS ROG XG Mobile eGPU ecosystem on SteamOS and Bazzite.

[![SteamOS Compatible](https://img.shields.io/badge/SteamOS-Compatible-1A9FFF)](https://store.steampowered.com/steamos)
[![Kernel Dynamic](https://img.shields.io/badge/kernel-Dynamic-orange)](https://gitlab.steamos.cloud/jupiter/linux-integration)
[![Kernel SteamOS Main/Beta](https://img.shields.io/badge/kernel-SteamOS_Main%2FBeta-orange)](https://gitlab.steamos.cloud/jupiter/linux-integration)
[![NVIDIA 595](https://img.shields.io/badge/nvidia--dkms-595.71.05-76B900)](https://www.nvidia.com/Download/index.aspx)
[![CUDA 12.8](https://img.shields.io/badge/CUDA-12.8-76B900)](https://developer.nvidia.com/cuda-downloads)
[![License GPLv3](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

![XG Mobile Manager UI](assets/images/mainUI.png)

A Decky Loader plugin that brings seamless, UI-driven support for the ASUS ROG XG Mobile eGPU ecosystem to Arch-based handhelds (like the ROG Ally running SteamOS , Bazzite or CachyOS).

This plugin manages the complex hardware handshakes, dynamically compiles and intercepts NVIDIA drivers using safe bind-mount architecture on SteamOS, injects Wayland/Vulkan environment variables to make eGPUs work natively inside Steam's Gaming Mode, and provides direct motherboard-level control over the eGPU's power limits and thermals.

---

## Table of Contents
- [Important Disclaimers & Risks](#-important-disclaimers--risks)
- [Compatibility Matrix](#-compatibility-matrix)
- [How It Works (Under the Hood)](#-how-it-works-under-the-hood)
- [Installation](#-installation)
- [How To Use](#-how-to-use)
- [NVIDIA GameMode Optimizations](#️-nvidia-gamemode-optimizations)
- [Building From Source](#️-building-from-source)
- [Known Issues](#-known-issues)
- [Support & Troubleshooting](#-support--troubleshooting)
- [Buy Me a Coffee](#-buy-me-a-coffee)
- [Credits](#-credits)
- [Pictures](#-pictures)

---

## ⚠️ Important Disclaimers & Risks
**Read this before installing. You are modifying core system behaviors.**

* **Beta Software:** This is a community-driven project and is currently in Beta. You are using this at your own risk.
* **Data Corruption Risk:** This plugin modifies the read-only root filesystem of SteamOS when using NVIDIA only. It compiles kernel modules via DKMS, and manipulates `/etc/environment`. While it uses a highly protective "Bind Mount" architecture to prevent permanent system bricking, unexpected power loss during installation *could* result in a boot loop requiring a SteamOS reinstall.
* **Sleep/Resume on BazziteOS with NVIDIA forces a Hard Reboot:** When putting the device to sleep with the NVIDIA eGPU active, the GPU cuts power to its Video RAM. Waking the device causes an internal fault on the XG Mobile and triggers the kernel panic. These are caused by upstream issues with the nvidia-open drivers that Bazzite team uses, and my plugin cannot do anything about this. It is recommended to disable sleep when on AC to avoid any complications. If you do find yourself in this scenario, to recover, hold down the power button until the device reboots.
* **External Display Limitations:** Due to current upstream limitations in `gamescope`, **4K/8K and UltraWide resolutions may not function correctly in Game Mode**. 1080p and 1440p are generally stable with the width being 2560p or less. Desktop Mode provides wider resolution support (Wayland and X11).
* **Power Profile overwritten by other TDP controllers:** Other TDP controls (like SimpleDeckyTDP and HHD) will override the setting of the Power Profile. Use the dropdown in this app to monitor what the current power profile is (this plugin pings the xg mobile every 3 seconds to determine the current Power Profile setting).

---

## 📊 Compatibility Matrix

| Hardware | SteamOS | Bazzite | Notes |
| :--- | :--- | :--- | :--- |
| **NVIDIA XG Mobile (4090)** | 🟢 Tested & Working | 🟢 Tested & Working | Full DKMS driver compilation supported. BazziteOS cannot recover from sleep/hibernate. |
| **NVIDIA XG Mobile (3080)** | 🟡 Experimental | 🟡 Experimental | Untested, but should follow all the same rules as the 4090. |
| **AMD XG Mobile (6850M XT)** | 🟡 Experimental | 🟢 Tested & Working | Uses native `amdgpu` kernel drivers. |
| **NVIDIA XG Mobile 2025 (5070 Ti / 5090)** | 🟡 Experimental | 🟡 Experimental | **Thunderbolt 5 / USB4 connector** — no proprietary handshake. Works on any TB4/USB4 host (incl. **Lenovo Legion Go 2**). Blackwell **requires the NVIDIA open kernel modules** — use **bazzite-nvidia** (ships them) so no DKMS install is needed. |

> **Host backend.** On ASUS hardware the plugin uses the proprietary `asus-nb-wmi` firmware
> interface. On any other host (e.g. the Legion Go 2 over USB4) it auto-detects a **generic
> Thunderbolt/USB4 + PCI** path: Enable authorizes the Thunderbolt device and rescans the PCI
> bus; Eject removes the PCI device and deauthorizes the tunnel. The power-profile dropdown
> maps to the kernel's ACPI `platform_profile` when ASUS WMI is absent.
>
> **Legion Go 2 BIOS:** set Thunderbolt/USB4 **security to "auto" or "none"** so the eGPU can
> hotplug-authorize; resizable BAR / PCIe tunneling may also need to be enabled.

---

## ⚙️ How It Works (Under the Hood)
SteamOS is an immutable (read-only) operating system. Traditional NVIDIA driver installations fail because they run out of space on the root partition and get wiped out during every OS update. 

**For SteamOS (The Bind Mount Architecture):**

**The Bind Mount Architecture:**
Instead of fighting the OS, this plugin uses "Smart Bind Mounts." When you click Install, it temporarily links the system's root directories (`/usr/lib`, `/var/lib/dkms`) to your massive `/home` partition. The 1.8GB NVIDIA driver payload and compilation tools are downloaded, the kernel modules are built, and the files are safely stored on your user drive. Permanent symlinks are then created. 

**Dynamic Fanging:**
When you enable the eGPU, the plugin "Re-Fangs" the OS by injecting NVIDIA's EGL, Vulkan, and X11 configurations into the system and reloading the display manager. When you eject, it "De-Fangs" the OS, securely ripping the NVIDIA configs out to protect your native AMD APU Handheld Mode.

**Self-Healing:**
If a SteamOS update wipes out the background services, the plugin will automatically detect the missing files and self-repair the next time you enable the XG Mobile.

**For Bazzite / CachyOS (WMI God-Mode):**
Bazzite completely strips out standard ASUS daemons (like asusd) to preserve native Steam TDP slider functionality. Because of this, the XG Mobile usually defaults to maximum power/noise. This plugin bypasses the missing daemons and writes hardware WMI codes directly to the motherboard, giving you native UI dropdowns to control the XG Mobile's Quiet/Balanced/Performance modes without breaking Bazzite's APU controls. Because of this, the plugin disables superfgxctl since it was providing inconsistent results, and interrupting this plugins' commands. 
*(Note: Other TDP controls (like SimpleDeckyTDP and HHD) will override the setting of the Power Profile).*

---

## 📥 Installation

**Prerequisites:**
1. You must have [Decky Loader](https://github.com/SteamDeckHomebrew/decky-loader) installed.
2. An NVIDIA-capable OS image (or, on SteamOS, the in-plugin DKMS installer). See **Platform setup** below.
3. **SteamOS NVIDIA Users:** You must have at least **4GB of free space** on your `/home` drive and **600MB** on your root (`/`) drive.
4. **Bazzite NVIDIA Users:** Ensure you are running an NVIDIA-specific image (e.g., `bazzite-deck-nvidia`).
5. **Legion Go 2 / other USB4 · Thunderbolt hosts:** no ASUS firmware required — the plugin auto-detects a generic Thunderbolt/USB4 backend. You must set the BIOS USB4 security correctly (see below).

### 🧩 Platform setup — Legion Go 2 & other USB4 / Thunderbolt eGPU hosts

The 2025 XG Mobile (5070 Ti / 5090) connects over **Thunderbolt 5** (backward-compatible with TB4/USB4), so it works on any USB4 host — **there is no proprietary ASUS handshake to emulate.** The plugin detects this automatically and uses a generic Thunderbolt/USB4 + PCI path (authorize → PCI rescan on enable; PCI remove → deauthorize on eject). Bring-up:

**1. BIOS**
- Set **Thunderbolt / USB4 Security** to **Auto** or **None** (so the eGPU can hotplug-authorize).
- Enable **Resizable BAR / Above-4G Decoding** if your firmware exposes it.

**2. OS — an NVIDIA-capable atomic image**
The 5070 Ti is Blackwell (GB203) and **requires the NVIDIA *open* kernel modules**, which ship in the **`bazzite-…-nvidia`** images (so no DKMS compilation is needed). On a Legion Go 2 use the handheld Game Mode flavor, **`bazzite-deck-nvidia`**. If you are already on `bazzite-deck`, rebase in place — it's atomic, reversible, and keeps your `/home`:

```bash
# Run ON THE HANDHELD (Desktop Mode → Konsole, or via SSH) — not on another computer
rpm-ostree status                                   # confirm your current image
sudo ostree admin pin 0                             # keep current deployment as a permanent boot fallback
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck-nvidia:stable
systemctl reboot
```
- Confirm the exact image tag at <https://bazzite.gg> first — variant names occasionally change.
- After reboot, verify the open driver bound:
  ```bash
  modinfo nvidia | grep -iE 'version|license'        # expect 595.x and "Dual MIT/GPL"
  ```
- Roll back any time with `rpm-ostree rollback`, or pick the pinned deployment from the boot menu. (`/home` is shared across deployments, so Decky and this plugin persist in both.)

> **SteamOS note:** the plugin *can* compile the open DKMS modules itself via the "Install NVIDIA Drivers" button, but SteamOS on the Legion Go 2 is unproven; `bazzite-deck-nvidia` is the recommended base.

**3. Install Decky Loader (on the handheld)**
Easiest on Bazzite is the built-in helper — run `ujust` and pick the Decky recipe, or use the **Bazzite Portal** app. Otherwise the official installer:
```bash
curl -L https://github.com/SteamDeckHomebrew/decky-installer/raw/main/cli/install_release.sh | sh
```
Reboot, then continue to **Quick Install** below. *(Run this on the handheld — it needs `systemctl` and a writable `~/homebrew`, so it will not work from a Mac/PC.)*

**Quick Install:**
Run this single command in your device's terminal (Desktop Mode or via SSH) to download and install the latest release automatically:

```bash
curl -sL "https://raw.githubusercontent.com/DerelictRobot/Decky-Loader-XGMobile-Manager/refs/heads/main/bin/install.sh" > /tmp/install.sh && bash /tmp/install.sh
```
*(Note: Restart your Device after installation to ensure the UI loads).*

---

## 📖 How To Use

### The First-Time Setup
1. Plug in the XG Mobile and lock the connector (ensure the LED is white).
2. Open the Quick Access Menu -> XG Mobile Manager.
3. Select your Vendor Mode (NVIDIA or AMD). If AMD, skip to Daily Use. NVIDIA users on SteamOS, please continue.
4. **SteamOS NVIDIA ONLY:** Make sure you are on the latest SteamOS update. Click Install NVIDIA Drivers. A live terminal will appear. Do not turn off your device. This downloads ~1.8GB of data and compiles the Linux kernel modules. Reboot when prompted.
5. **Bazzite ONLY:** No installation is required. The Advanced menu will intentionally hide the driver installer to protect your immutable OS.
6. Click Create Desktop Icons to make Desktop Shortcuts for Enabling and Ejecting the XG Mobile

### Daily Use

> ### 🚀 New in v0.2.3
> * **[Desktop on Enable]:** Enable the Desktop on Enable toggle to automatically switch to Desktop Mode when running the Enable XG Mobile button. Recommended for 4K/8K and Ultrawide resolutions.
> * **[Set Desktop to Default]:** Enable this toggle to set Desktop Mode to persistent when Enabling the XG Mobile. Run the Eject XG Mobile Desktop Link to eject the XG Mobile and revert to GameMode.

* **To Play:** Plug in the XG Mobile, lock it, and click **Enable XG Mobile**. The light on the XG Mobile connector will turn red. The screen will then briefly go black as `gamescope` restarts on the external GPU, please be patient. Some external monitors alternate On/Off during this process.
* **Power Profiles:** Once active, use the **ASUS Hardware Controls** dropdown to toggle between Quiet, Balanced, and Performance thermal limits for the eGPU.
* **To Disconnect:** Click **Eject XG Mobile**. Wait for the UI to restart and return to the handheld screen and the light on the XG Mobile connector is white before unlocking the cable.

### 🛑 The "SteamOS Update Tax" SteamOS Users only
Because the NVIDIA drivers are compiled explicitly for the kernel version running at the time of installation, **a SteamOS System Update will break your drivers.**

When there is a SteamOS update available, follow this exact sequence for safety:
1. Open the plugin and click **Reset Driver Environment** (This safely uninstalls the old drivers and restores your native OS architecture).
2. Go to Steam Settings -> System and apply the SteamOS Update.
3. Reboot.
4. Open the plugin and click **Install NVIDIA Drivers** to compile them for the new kernel. 
*(Note: Bazzite users do not need to do this, as the drivers update natively with the OS image).*

---

## NVIDIA GameMode Optimizations
* **HDR STILL IN TESTING** If you experience color issues, disable HDR under Display in Steam Settings.
* **Auto-Dimming:** If the screen is constantly dimming on you, enable "Use Native Color Tempeture" in Steam Display Settings.
* **Tearing/Vsync:** Enable VRR and Allow Screen Tearing in the Quick Access Menu. (Don't worry, the screen won't actually tear, this is required for how NVIDIA communicates its layers to Wayland/Gamescope).

---

## 🛠️ Building From Source
If you wish to contribute or build the plugin from your own development environment:

1. Clone the repository:
   ```bash
   git clone https://github.com/Kentronix57/Decky-Loader-XGMobile-Manager.git
   cd Decky-Loader-XGMobile-Manager
   ```
2. Install dependencies (requires Node.js and pnpm):
   ```bash
   pnpm install
   ```
3. Build the plugin using the included wrapper script:
   ```bash
   ./build.sh
   ```
   Or by using pnpm:
   ```bash
   pnpm run release
   ```
4. Transfer the resulting folder to `/home/deck/homebrew/plugins/` on your device and restart the Decky Plugin Loader service.

---

## 🐛 Known Issues
* **Sleep/Resume BazziteOS with NVIDIA forces a Hard Reboot:** When putting the device to sleep with the NVIDIA eGPU active, the GPU cuts power to its Video RAM. Waking the device causes an internal fault on the XG Mobile and triggers the kernel panic. To recover, hold down the power button until the device reboots.
* **Boot Loop after SteamOS Update:** If you update SteamOS *without* running the Reset script first, the system may try to load orphaned kernel modules. Run the Reset script from recovery or TTY to fix.
* **Internal Display still on:** When leaving the eGPU active and rebooting/shutdown in GameMode, the internal display stays on and displays the boot logo. This doesn't affect performance, but is actively being investigated.
* **Power Profile overwritten by other TDP controllers:** Other TDP controls (like SimpleDeckyTDP and HHD) will override the setting of the Power Profile. Use the dropdown in this app to monitor what the current power profile is (this plugin pings the xg mobile every 3 seconds to determine the current Power Profile setting).
* **Set Desktop to Default on BazziteOS:** Setting desktop mode to persistent is not currently possible on BazziteOS. With the deck image of bazzite, they have made it over-write the desktop persistence on a reboot. This is still under investigation

---

## 🆘 Support & Troubleshooting
**If you encounter a black screen, failed installation, or other bugs:**

Do not panic. Your system can always be recovered using the Reset Driver Environment button, or by running the /home/deck/homebrew/plugins/xgmobile-manager/bin/uninstall.sh script via SSH or TTY if running SteamOS. If you experience black screens with the eGPU enabled no matter what you try, it is safe to force shutdown the device and remove the XG Mobile and boot the device back up, ignoring the ASUS BIOS warning that is given. 

Check the Issues Tab: See if someone else has already reported your problem on GitHub.

Open a New Issue: If you need help, please open an Issue on GitHub and include:

Your OS and version (e.g., Bazzite, SteamOS 3.5.19)

The exact model of your XG Mobile (4090, 3080, 6850M)

The output of your corresponding logs. (IE. enable, eject, etc.)

Please use GitHub Issues rather than Reddit DMs for technical support so the community can benefit from the solutions!

## ☕ Buy Me a Coffee
This plugin required countless hours of kernel-level debugging, file system reverse-engineering, and risk to my personal hardware to build. I offer it completely free and open-source.

If this tool saved you hours of troubleshooting or finally made your portable eGPU setup viable, consider buying me a coffee or an energy drink to keep the updates coming!

**[(Buy me a coffee)](https://buymeacoffee.com/kentronix)**

**[(Ko-Fi)](https://ko-fi.com/kentronix)**

## 🏆 Credits
* **Development & Architecture:** Kentronix
* Protocol reverse engineering: [osy/XG_Mobile_Station](https://github.com/osy/XG_Mobile_Station)
* asus-linux kernel patches: [asus-linux.org](https://asus-linux.org)
* Valve for shipping the SteamOS kernel with `asus-wmi` + `egpu_enable`
* [Decky Loader](https://decky.xyz/) — the plugin platform
* Stensmir for the symlink NVIDIA architecture idea. [stesmir/xg-mobile-linux](https://github.com/stensmir/xg-mobile-linux/tree/master).
* Built using the [@decky/ui](https://github.com/SteamDeckHomebrew/decky-ui) framework.

---

## Pictures
![SteamOS version and NVIDIA driver version displayed in GameMode](assets/images/595-71-05-linux-6.18.25.png)
![NVIDIA Settings and Readings in Wayland Desktop. BazziteOS](assets/images/wayland-nvidia-bazzite1.png)
![NVIDIA Settings and Readings in X11 Desktop. SteamOS](assets/images/x11-nvidia1.png)
![NVIDIA Settings and Readings in X11 Desktop. SteamOS](assets/images/x11-nvidia2.png)
![NVIDIA Settings and Readings in X11 Desktop. SteamOS](assets/images/x11-nvidia3.png)
![Example of the Activity Log](assets/images/activitylog.png)
