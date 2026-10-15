# Studio preview runner: serves one branch of a Studio app at a time
# (Expo dev server for the phone + web build) and runs Playwright against it.
FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && corepack enable \
 && corepack prepare pnpm@10 --activate

# Chromium + its system libraries for the screenshot runs, in a shared path:
# installed as root at build time, used as `node` at run time.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install -g playwright@1.64.1 \
 && playwright install --with-deps chromium \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /srv
COPY package.json ./
RUN npm install --omit=dev && npm link playwright
COPY server.mjs smoke.mjs ./

# Same uid as the host user's files on the VirtioFS bind mount.
USER node
EXPOSE 7301 8081
CMD ["node", "server.mjs"]
