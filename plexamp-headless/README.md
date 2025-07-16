# Plexamp headless
A lightweight, headless audio system for Raspberry Pi focused on high-fidelity audio playback and clean digital output.

Currently optimized for:
- Running **Plexamp headless** on Raspberry Pi 3 B+
- Output to external DACs via USB or S/PDIF
- Minimal interference: HDMI/video disabled, Wi-Fi muted
- Bit-perfect digital audio output

## 🔧 Features
- Simple installation via shell script
- Plexamp autostart via `systemd`
- HDMI & Wi-Fi disabled for noise reduction
- Ready for future expansion (MPD, RoonBridge, etc.)

## 🛠️ Requirements
- Raspberry Pi 3 B+ or newer
- Raspberry Pi OS Lite (64-bit)
- External DAC via USB or S/PDIF HAT
- Plexamp account and linked device

## 🚀 Quick Start
```bash
sudo apt-get install -y git
git clone https://github.com/BeeLazy/pi-hifi.git
cd pi-hifi/plexamp-headless/setup
sudo ./install.sh
```

## 🆕 Upgrading
```bash
cd pi-hifi/plexamp-headless/setup
sudo ./upgrade.sh
```
