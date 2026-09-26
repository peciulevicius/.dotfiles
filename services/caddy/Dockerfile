# Caddy + the Sablier plugin (scale-to-zero reverse proxy).
# The plugin has no prebuilt image (sablierapp/sablier-caddy-plugin#10), so
# build Caddy with xcaddy. Pin both the Caddy base and the plugin version —
# bump deliberately after testing, never track :latest.
# sablier-caddy-plugin v1.0.2 requires caddy/v2 >= v2.11.2 (2.10.2 fails the
# build: "requires github.com/caddyserver/caddy/v2@v2.11.2, but v2.10.2 is
# requested"), so the base is 2.11.4, not the plugin README's 2.10.2 example.
FROM caddy:2.11.4-builder AS builder

RUN xcaddy build \
    --with github.com/sablierapp/sablier-caddy-plugin@v1.0.2

FROM caddy:2.11.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
