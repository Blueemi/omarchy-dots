#!/usr/bin/env bash
# Install these dotfiles on an Omarchy machine.
#   ./install.sh           user config (~/.config, ~/.zshrc), backs up anything it replaces
#   ./install.sh --system  also the /etc + /usr/local bits (keyd, fonts, trackpad haptics); needs sudo
set -euo pipefail
cd "$(dirname "$0")"
STAMP=$(date +%s)

put() { # src dest
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [[ -e $dest ]] && ! cmp -s "$src" "$dest"; then cp -a "$dest" "$dest.bak.$STAMP"; fi
  cp -a "$src" "$dest"
  echo "  $dest"
}

echo "User config:"
while IFS= read -r -d '' f; do put "$f" "$HOME/.config/${f#config/}"; done < <(find config -type f -print0)
put home/.zshrc "$HOME/.zshrc"

# Plugins that live in their own repos
for p in "blueemi.blackout https://github.com/Blueemi/omarchy-blackout.git" \
         "blueemi.omausage https://github.com/Blueemi/omausage.git"; do
  set -- $p; d="$HOME/.config/omarchy/plugins/$1"
  [[ -d $d ]] || git clone --depth 1 "$2" "$d"
done

if [[ ${1:-} == --system ]]; then
  echo "System config:"
  while IFS= read -r -d '' f; do
    dest="/${f#system/}"; sudo mkdir -p "$(dirname "$dest")"
    [[ -e $dest ]] && sudo cp -a "$dest" "$dest.bak.$STAMP"
    sudo cp "$f" "$dest"; echo "  $dest"
  done < <(find system -type f -print0)
  sudo chmod +x /usr/local/bin/trackpad-light-click
  sudo systemctl daemon-reload
  sudo systemctl enable --now keyd trackpad-light-click || true
  sudo systemctl reload keyd || true
  fc-cache -f >/dev/null
fi

omarchy theme set "$(cat THEME)" 2>/dev/null || echo "Set the theme with: omarchy theme set $(cat THEME)"
hyprctl reload >/dev/null 2>&1 || true
echo "Done. Restart the shell with: omarchy restart shell"
