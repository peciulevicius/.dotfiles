#!/bin/bash
# Set up Cloudflare Tunnel for self-hosted services
# Routes *.peciulevicius.com subdomains to local Docker services
# Usage: ./setup-cloudflare-tunnel.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}→${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

DOMAIN="${CLOUDFLARE_DOMAIN:-peciulevicius.com}"
TUNNEL_NAME="${TUNNEL_NAME:-macmini}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Cloudflare Tunnel Setup               ║"
echo "║    Route *.${DOMAIN} to local services   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- 1. Check cloudflared ---
if ! command -v cloudflared &> /dev/null; then
    print_error "cloudflared not installed"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "  Install: brew install cloudflared"
    else
        echo "  Install: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
    fi
    exit 1
fi
print_success "cloudflared installed ($(cloudflared --version 2>&1 | head -1))"

# --- 2. Login ---
if [[ ! -f "$HOME/.cloudflared/cert.pem" ]]; then
    print_info "Logging in to Cloudflare (browser will open)..."
    cloudflared tunnel login
else
    print_success "Already logged in to Cloudflare"
fi

# --- 3. Create or reuse tunnel ---
EXISTING_TUNNEL=$(cloudflared tunnel list -o json 2>/dev/null | python3 -c "
import sys, json
tunnels = json.load(sys.stdin)
for t in tunnels:
    if t['name'] == '$TUNNEL_NAME' and not t.get('deleted_at'):
        print(t['id'])
        break
" 2>/dev/null || echo "")

if [[ -n "$EXISTING_TUNNEL" ]]; then
    TUNNEL_ID="$EXISTING_TUNNEL"
    print_success "Tunnel '$TUNNEL_NAME' already exists (ID: $TUNNEL_ID)"
else
    print_info "Creating tunnel '$TUNNEL_NAME'..."
    TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1)
    TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[0-9a-f-]{36}' | head -1)
    print_success "Tunnel created (ID: $TUNNEL_ID)"
fi

# --- 4. Find credentials file ---
CREDS_FILE="$HOME/.cloudflared/${TUNNEL_ID}.json"
if [[ ! -f "$CREDS_FILE" ]]; then
    print_error "Credentials file not found: $CREDS_FILE"
    exit 1
fi

# --- 5. Service subdomain mapping ---
# NOTE: Syncthing is Tailscale-only (no public tunnel)
# NOTE: Sonarr/Radarr/Prowlarr/Transmission are Tailscale-only (media management, set-and-forget)
declare -A SERVICES=(
    ["home"]=7575       # Glance dashboard
    ["vault"]=8001      # Vaultwarden
    ["photos"]=2283     # Immich
    ["cloud"]=8080      # Nextcloud
    ["papers"]=8000     # Paperless-ngx
    ["rss"]=8082        # FreshRSS
    ["status"]=3001     # Uptime Kuma
    ["books"]=8083      # Calibre-Web
    ["pihole"]=8053     # Pi-hole admin
    ["pdf"]=8084        # Stirling PDF
    ["tools"]=8085      # IT-Tools
    ["links"]=3006      # Karakeep
    ["recipes"]=9925    # Mealie
    ["watch"]=8096      # Jellyfin
    ["listen"]=13378    # Audiobookshelf
    ["portainer"]=9000  # Portainer
)

# --- 6. Write config ---
CONFIG_FILE="$HOME/.cloudflared/config.yml"
print_info "Writing tunnel config to $CONFIG_FILE"

cat > "$CONFIG_FILE" << EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CREDS_FILE}

ingress:
EOF

for sub in home vault photos cloud papers rss status books pihole pdf tools links recipes watch listen portainer; do
    port="${SERVICES[$sub]}"
    echo "  - hostname: ${sub}.${DOMAIN}" >> "$CONFIG_FILE"
    echo "    service: http://localhost:${port}" >> "$CONFIG_FILE"
done

echo "  - service: http_status:404" >> "$CONFIG_FILE"

print_success "Config written"

# --- 7. Create DNS records ---
print_info "Creating DNS records..."
for sub in home vault photos cloud papers rss status books pihole pdf tools links recipes watch listen portainer; do
    OUTPUT=$(cloudflared tunnel route dns "$TUNNEL_NAME" "${sub}.${DOMAIN}" 2>&1)
    if echo "$OUTPUT" | grep -q "Added CNAME"; then
        print_success "${sub}.${DOMAIN}"
    elif echo "$OUTPUT" | grep -q "already exists"; then
        print_warn "${sub}.${DOMAIN} — DNS record already exists (skipped)"
    else
        print_error "${sub}.${DOMAIN} — $OUTPUT"
    fi
done

# --- 8. Configure services that need the domain ---
print_info "Updating service configs..."

# Vaultwarden needs DOMAIN set for web vault
VW_ENV="$HOME/services/vaultwarden/.env"
if [[ -f "$VW_ENV" ]]; then
    sed -i '' "s|DOMAIN=.*|DOMAIN=https://vault.${DOMAIN}|" "$VW_ENV" 2>/dev/null || \
    sed -i "s|DOMAIN=.*|DOMAIN=https://vault.${DOMAIN}|" "$VW_ENV"
    print_success "Vaultwarden DOMAIN → https://vault.${DOMAIN}"
fi

# Nextcloud needs trusted_domains
if docker ps --format '{{.Names}}' | grep -q "^nextcloud$"; then
    docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value="cloud.${DOMAIN}" 2>/dev/null
    print_success "Nextcloud trusted domain → cloud.${DOMAIN}"
fi

# --- 9. Start tunnel ---
echo ""
print_info "Starting tunnel as background service..."
if [[ "$(uname)" == "Darwin" ]]; then
    brew services start cloudflared 2>/dev/null && \
        print_success "cloudflared service started (auto-starts on boot)" || \
        print_warn "Could not start brew service, run manually: cloudflared tunnel run $TUNNEL_NAME"
else
    print_info "To run as systemd service:"
    echo "  sudo cloudflared service install"
    echo "  sudo systemctl enable --now cloudflared"
fi

# --- 10. Summary ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Tunnel Active — All Services Live     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Service URLs (all HTTPS):"
echo ""
printf "  %-16s → %s\n" "Dashboard"      "https://home.${DOMAIN}"
printf "  %-16s → %s\n" "Vaultwarden"    "https://vault.${DOMAIN}"
printf "  %-16s → %s\n" "Immich"         "https://photos.${DOMAIN}"
printf "  %-16s → %s\n" "Nextcloud"      "https://cloud.${DOMAIN}"
printf "  %-16s → %s\n" "Paperless"      "https://papers.${DOMAIN}"
printf "  %-16s → %s\n" "FreshRSS"       "https://rss.${DOMAIN}"
printf "  %-16s → %s\n" "Uptime Kuma"    "https://status.${DOMAIN}"
printf "  %-16s → %s\n" "Calibre-Web"    "https://books.${DOMAIN}"
printf "  %-16s → %s\n" "Pi-hole"        "https://pihole.${DOMAIN}"
printf "  %-16s → %s\n" "Stirling PDF"   "https://pdf.${DOMAIN}"
printf "  %-16s → %s\n" "IT-Tools"       "https://tools.${DOMAIN}"
printf "  %-16s → %s\n" "Karakeep"       "https://links.${DOMAIN}"
printf "  %-16s → %s\n" "Mealie"         "https://recipes.${DOMAIN}"
printf "  %-16s → %s\n" "Jellyfin"       "https://watch.${DOMAIN}"
printf "  %-16s → %s\n" "Audiobookshelf" "https://listen.${DOMAIN}"
printf "  %-16s → %s\n" "Portainer"      "https://portainer.${DOMAIN}"
echo ""
echo "  Tailscale-only (not in tunnel — access via Tailscale IP):"
printf "  %-16s → %s\n" "Sonarr"         "http://<tailscale-ip>:8989"
printf "  %-16s → %s\n" "Radarr"         "http://<tailscale-ip>:7878"
printf "  %-16s → %s\n" "Prowlarr"       "http://<tailscale-ip>:9696"
printf "  %-16s → %s\n" "Transmission"   "http://<tailscale-ip>:9091"
printf "  %-16s → %s\n" "Syncthing"      "http://<tailscale-ip>:8384"
echo ""
print_info "Bitwarden app server URL: https://vault.${DOMAIN}"
echo ""
