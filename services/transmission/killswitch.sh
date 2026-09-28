#!/bin/sh
# Kill switch for Transmission, run as transmission-ts's entrypoint BEFORE
# Tailscale starts (then execs containerboot).
#
# Why routing rules and not iptables: `tailscale down` (or tailscaled dying)
# makes containerboot exit, Docker restarts the container, and the network
# namespace — with any rules added later — is rebuilt from scratch. During
# the seconds before Tailscale reconnects, traffic would leave via eth0 on the
# home IP (seen in testing 2026-09-28). Installing the rule here, on every
# start, closes that window.
#
# How: Transmission runs as PUID (KILLSWITCH_UID). Its packets are sent to
# table 200, which only knows the local Docker subnet and otherwise says
# "unreachable". The rule sits at priority 5300 — AFTER Tailscale's own
# rules (5210–5270, table 52). With the Mullvad exit node up, table 52's
# `default dev tailscale0` matches first → traffic goes through the tunnel.
# With Tailscale down, starting, or up without an exit node, nothing earlier
# matches → table 200 → unreachable. Fail-closed. tailscaled itself runs as
# root, so it can still reach the internet to connect.
set -eu

uid="${KILLSWITCH_UID:?set KILLSWITCH_UID to the Transmission PUID}"
table=200

ip route flush table "$table" 2>/dev/null || true
ip route show table main | grep -v '^default' | while read -r route; do
  # shellcheck disable=SC2086  # route is a list of ip-route arguments
  ip route add $route table "$table"
done
ip route add unreachable default table "$table"
ip rule add priority 5300 uidrange "$uid-$uid" lookup "$table"

# Replies from the web UI/RPC port go out the normal way. Docker Desktop
# delivers published-port connections with a fake outside source address
# (seen as 8.8.8.8), so without this the SYN-ACK follows the exit-node
# default route into the tunnel and the UI times out. Only source port 9091
# is exempt; peer traffic (51413) never matches.
ip rule add priority 5200 ipproto tcp sport 9091 lookup main

ip -6 route add unreachable default table "$table" 2>/dev/null || true
ip -6 rule add priority 5300 uidrange "$uid-$uid" lookup "$table" 2>/dev/null || true

echo "killswitch: uid ${uid} uses table ${table}, unreachable unless the exit-node route matches"
exec /usr/local/bin/containerboot
