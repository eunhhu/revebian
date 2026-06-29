#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="${IMAGE_NAME:-revebian}"
FRIDA_HOST_PORT="${FRIDA_HOST_PORT:-27042}"

usage() {
    cat <<'EOF'
usage: ./run.sh [command]

commands:
  shell      start container + frida-server, then enter fish (default)
  up         start container + frida-server in background
  server     run frida-server in foreground
  ps         list processes through frida-server
  attach     attach through frida-server: ./run.sh attach <pid|name> [frida args...]
  stop       stop containers
  rebuild    rebuild image
  help       show this help
EOF
}

compose() {
    USER_UID="${USER_UID:-$(id -u)}" USER_GID="${USER_GID:-$(id -g)}" docker compose "$@"
}

ensure_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker not found" >&2
        exit 1
    fi
    if ! docker compose version >/dev/null 2>&1; then
        echo "docker compose plugin not found" >&2
        exit 1
    fi
}

ensure_image() {
    if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
        ./setup.sh
    fi
}

wait_for_frida() {
    for _ in $(seq 1 40); do
        if compose exec -T revebian frida-ps-local >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.25
    done

    echo "frida-server did not become ready" >&2
    compose logs --tail=80 revebian >&2 || true
    exit 1
}

start_env() {
    ensure_image
    compose up -d revebian
    compose exec -T revebian start-frida-server >/dev/null
    wait_for_frida
    echo "frida-server: 127.0.0.1:${FRIDA_HOST_PORT}"
}

cmd="${1:-shell}"
if [[ $# -gt 0 ]]; then
    shift
fi

ensure_docker

case "${cmd}" in
    shell)
        start_env
        if [[ -t 0 && -t 1 ]]; then
            compose exec revebian fish -l
        else
            compose exec -T revebian fish -l
        fi
        ;;
    up|start|daemon)
        start_env
        ;;
    server)
        ensure_image
        compose --profile server up frida-server
        ;;
    ps)
        start_env
        compose exec -T revebian frida-ps-local "$@"
        ;;
    attach)
        start_env
        if [[ -t 0 && -t 1 ]]; then
            compose exec revebian frida-attach-local "$@"
        else
            compose exec -T revebian frida-attach-local "$@"
        fi
        ;;
    stop|down)
        compose --profile server down --remove-orphans
        ;;
    rebuild|build|setup)
        ./setup.sh "$@"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "unknown command: ${cmd}" >&2
        usage >&2
        exit 2
        ;;
esac
