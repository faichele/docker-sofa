#!/bin/bash
set -e

/lib/systemd/systemd &

exec "$@"
