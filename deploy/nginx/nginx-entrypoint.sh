#!/bin/sh

# chmod +x nginx-entrypoint.sh
# or it won't work
#exec "$@"

nginx -g "daemon off;"