#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

docker compose down
rm -rf ./data ./logs
docker compose up -d
