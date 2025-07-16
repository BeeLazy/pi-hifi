#!/usr/bin/env bash
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
sudo curl -Ls "$PLEXAMP_URL" -o /tmp/plexamp.tar.bz2
echo "✅ Downloaded Plexamp to /tmp/plexamp.tar.bz2"