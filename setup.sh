#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v docker >/dev/null 2>&1; then
    echo "docker not found" >&2
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose plugin not found" >&2
    exit 1
fi

export USER_UID="${USER_UID:-$(id -u)}"
export USER_GID="${USER_GID:-$(id -g)}"

docker compose build "$@" revebian

echo "ready: ./run.sh"
