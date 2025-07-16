#!/bin/bash
set -e

# Release channel is passed as first argument
# Beta, alpha or no argument for stable

echo "📥 Downloading latest Plexamp headless..."
PLEXAMP_URL=$(curl -s "https://plexamp.plex.tv/headless/version$1.json" | jq -r '.updateUrl')
#Confirm URL found
if [[ -z "$PLEXAMP_URL" ]]; then
  echo "❌ Failed to locate latest Plexamp headless package URL"
  exit 1
fi
echo "📥 Latest Plexamp URL: $PLEXAMP_URL"

# Download and install
sudo curl -Ls "$PLEXAMP_URL" -o /tmp/plexamp.tar.bz2
sudo rm -rf /opt/plexamp.last
sudo mv /opt/plexamp /opt/plexamp.last
sudo tar -xjf /tmp/plexamp.tar.bz2 -C /opt
sudo rm /tmp/plexamp.tar.bz2
sudo chown -R plexamp:plexamp /opt/plexamp
sudo chmod -R 750 /opt/plexamp

# Remove upgrade.sh from install to ensure system is upgraded with project upgrade.sh
sudo rm /opt/plexamp/upgrade.sh

# Prefer system jackd
if [ -f /usr/bin/jackd ]; then
    sudo rm /opt/plexamp/treble/*/libjack*
fi

# Restart service
sudo systemctl -q restart plexamp
echo "🥳 Plexamp has been upgraded to latest version"
