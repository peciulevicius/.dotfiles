#!/usr/bin/env bash
# Wake the NAS over the LAN (Wake-on-LAN magic packet from the Mac mini).
# Run from anywhere you can SSH into the Mac mini (Tailscale):
#   ~/.dotfiles/scripts/utils/wake-nas.sh
# Needs WoL enabled in UGOS and NAS_MAC in ~/.config/homelab/nas.env.
set -euo pipefail
source "$HOME/.config/homelab/nas.env"
: "${NAS_MAC:?set NAS_MAC in ~/.config/homelab/nas.env}"
python3 - "$NAS_MAC" <<'PY'
import socket, sys
mac = bytes.fromhex(sys.argv[1].replace(":", "").replace("-", ""))
packet = b"\xff" * 6 + mac * 16
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    for port in (9, 7):
        s.sendto(packet, ("255.255.255.255", port))
print("magic packet sent")
PY
host="${NAS_HOST:-DH4300PLUS-DP.local}"
echo "Waiting up to 3 min for $host ..."
for _ in $(seq 1 36); do
  if ping -c1 -t2 "$host" >/dev/null 2>&1; then
    echo "NAS is up. Shares remount via nas-watchdog within a few minutes."
    exit 0
  fi
  sleep 5
done
echo "No answer yet — it may still be booting (UGOS takes 2–4 min)."
