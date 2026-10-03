#!/bin/sh
# PAPERLESS_POST_CONSUME_SCRIPT: Paperless runs this after every consumed
# document with DOCUMENT_ID set. Failures here never block consumption.
python3 /usr/src/paperless/src/manage.py shell < /usr/src/paperless/scripts/payslip.py || true
