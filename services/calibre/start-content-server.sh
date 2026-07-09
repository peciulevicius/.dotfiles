#!/bin/bash
# Auto-start Calibre Content Server on port 8081
# Port 8080 is taken by nginx (KasmVNC GUI) in this image
sleep 8
# 10.99.8.0/24 = calibre-web Docker network (Readarr lives here, needs write access)
/usr/bin/calibre-server /books \
  --port 8081 \
  --disable-use-bonjour \
  --enable-local-write \
  --trusted-ips=10.99.8.0/24 \
  --log=/config/content-server.log &
