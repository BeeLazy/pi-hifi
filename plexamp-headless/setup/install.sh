#!/bin/bash
set -e

# Plexamp release channel is passed as first argument
# Beta, alpha or no argument for stable

# Get projectroot
PROJECT_ROOT=$(dirname "$(dirname "$PWD")")

echo "🔧 Setting up pi-hifi..."

# Disable Wi-Fi
if ! grep -q "^dtoverlay=disable-wifi" /boot/firmware/config.txt; then
  echo ""
  echo -n "📡 Do you want to disable Wi-Fi for noise reduction [y/N]: " > /dev/tty
  read -r DISABLE_WIFI
  DISABLE_WIFI=$(echo "$DISABLE_WIFI" | tr '[:upper:]' '[:lower:]')
  if [ "$DISABLE_WIFI" = "y" ]; then
    echo "Disabling Wi-Fi..."
    echo "dtoverlay=disable-wifi" | sudo tee -a /boot/firmware/config.txt > /dev/null
	echo "Wi-Fi diabled"
  fi
fi

# Disable IPv6
if ! grep -q "ipv6.disable=1" /boot/firmware/cmdline.txt; then
  echo ""
  echo -n "🌐 Do you want to disable IPv6 [y/N]: " > /dev/tty
  read -r answer
  answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
  if [ "$answer" = "y" ]; then
    echo "Disabling IPv6..."
    echo -n " ipv6.disable=1" | sudo tee -a /boot/firmware/cmdline.txt > /dev/null
    echo "IPv6 disabled via kernel parameter. Reboot required for change to take effect."
  fi
fi

echo "🔧 Updating system..."
echo "This can take some time, please be patient"
sudo apt-get -qq update > /dev/null
sudo apt-get upgrade -y > /dev/null

echo "📦 Installing dependencies..."
sudo apt-get install -y unzip curl alsa-utils jq > /dev/null
echo "📦 Installing nodejs..."
sudo curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null
sudo apt-get install nodejs -y > /dev/null
echo "📦 Installing node packages..."
sudo npm install fast-png > /dev/null

echo "🔌 Disabling HDMI video..."
sudo cp ../services/disable-hdmi.service /etc/systemd/system/disable-hdmi.service
sudo systemctl enable disable-hdmi.service

echo "🔇 Disabling HDMI audio..."
sudo cp ../services/set-audio-output.service /etc/systemd/system/set-audio-output.service
sudo systemctl enable set-audio-output.service

echo "🔊 Enabling USB audio support..."
echo "snd-usb-audio" | sudo tee -a /etc/modules > /dev/null

echo "📥 Downloading and setting up Plexamp headless..."
sudo mkdir -p /opt/plexamp
PLEXAMP_URL=$(curl -s "https://plexamp.plex.tv/headless/version$1.json" | jq -r '.updateUrl')
# Confirm URL found
if [[ -z "$PLEXAMP_URL" ]]; then
  echo "❌ Failed to locate latest Plexamp headless package URL"
  exit 1
fi
echo "📥 Latest Plexamp URL: $PLEXAMP_URL"
sudo curl -Ls "$PLEXAMP_URL" -o /tmp/plexamp.tar.bz2
sudo tar -xjf /tmp/plexamp.tar.bz2 -C /opt
sudo rm /tmp/plexamp.tar.bz2

# Prefer system jackd
if [ -f /usr/bin/jackd ]; then
    sudo rm /opt/plexamp/treble/*/libjack*
fi

# Create user for Plexamp
# User will be created with a password, so we can interactively start plexamp as the user when getting the claim token
RANDOM_PASSWORD=$(openssl rand -base64 32)
PASSWORDCRYPTED=$(openssl passwd -6 "$RANDOM_PASSWORD")
sudo useradd -m -p "$PASSWORDCRYPTED" plexamp
unset RANDOM_PASSWORD PASSWORDCRYPTED
# Ensure user is in audio group for DAC access
sudo usermod -aG audio plexamp
sudo chown -R plexamp:plexamp /opt/plexamp
sudo chmod -R 750 /opt/plexamp

# Install plexamp service
sudo cp ../services/plexamp.service /etc/systemd/system/plexamp.service
sudo systemctl enable plexamp

# Run plexamp as plexamp user to set claim token
echo "📦 Starting plexamp to set claim token..."
echo "Visit https://plex.tv/claim, copy the claim code, paste it in the terminal, and follow the prompts"
echo ""
if [ "$DISABLE_WIFI" = "y" ]; then
  echo "Nevermind the messages about Wi-Fi being blocked by rfkill,"
  echo "we chose to disable WiFi"
fi
echo "Nevermind the message that Plexamp cannot load cloud players (yet...)"
sudo runuser -l plexamp -c 'node /opt/plexamp/js/index.js'

# Change plexamp user to nologin
sudo usermod -s /sbin/nologin plexamp
sudo passwd -d plexamp > /dev/null

# Get IP address
IP_ADDRESS=$(ip -4 addr show scope global | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)

echo ""
echo "🥳 Installation complete. Reboot with 'sudo reboot' for all settings to take effect"
echo "⚠️ Reboot before you continue with the last setup in the web-GUI!"
echo ""
echo "🌐 The web-GUI should be available on http://$IP_ADDRESS:32500 from a browser"
echo "On that GUI you will be asked to login to your Plex-account for security-reasons,"
echo "and then choose a library to stream music from."
echo ""
echo "🔊 If using a HAT or USB connected DAC, it is possible you need to select it via:"
echo "Settings (cogwheel lower right corner) > Playback > Audio Output > Audio Device."
echo ""
echo "🔊 For bit-perfect audio:"
echo "Settings > Playback > Audio Output > Sample Rate Matching > Smart or Strict."
echo "Reboot required for setting to take effect."
echo ""
echo "🧾 Logs are located at: /home/plexamp/.cache/Plexamp/log/Plexamp.log"
echo ""
echo "🆕 Upgrading Plexamp is done with upgrade.sh in the setup folder:"
echo "$PROJECT_ROOT/plexamp-headless/setup/upgrade.sh"
echo ""
echo "♫ Enjoy streaming ♫"
