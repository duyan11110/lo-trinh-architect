#!/usr/bin/env bash
# Send one raw HTTP/1.1 request to the local static site and print the raw response.
set -euo pipefail

printf 'GET /index.html HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' \
  | nc localhost 8080
