ARG BASE_PLATFORM=linux/amd64
FROM --platform=${BASE_PLATFORM} ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH=/opt/revenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    EDITOR=nvim

ARG USERNAME=re
ARG USER_UID=1000
ARG USER_GID=1000
ARG FRIDA_VERSION=17.15.3
ARG FRIDA_TOOLS_VERSION=14.10.4
ARG JAQ_VERSION=3.1.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bat \
        binutils \
        ca-certificates \
        curl \
        eza \
        file \
        fish \
        gdb \
        gdbserver \
        iproute2 \
        jq \
        less \
        libglib2.0-0 \
        lsof \
        ltrace \
        neovim \
        net-tools \
        netcat-openbsd \
        procps \
        psmisc \
        python3 \
        python3-venv \
        ripgrep \
        socat \
        strace \
        sudo \
        tmux \
        xxd \
        xz-utils \
        zoxide; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    python3 -m venv /opt/revenv; \
    /opt/revenv/bin/pip install --upgrade --no-cache-dir --no-compile pip setuptools wheel; \
    /opt/revenv/bin/pip install --no-cache-dir --no-compile \
        "frida==${FRIDA_VERSION}" \
        "frida-tools==${FRIDA_TOOLS_VERSION}"; \
    find /opt/revenv -type d -name __pycache__ -prune -exec rm -rf '{}' +; \
    frida_arch="$(dpkg --print-architecture)"; \
    case "${frida_arch}" in \
        amd64) frida_asset_arch=x86_64 ;; \
        arm64) frida_asset_arch=arm64 ;; \
        armhf) frida_asset_arch=armhf ;; \
        *) echo "Unsupported Frida server architecture: ${frida_arch}" >&2; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/frida-server-${FRIDA_VERSION}-linux-${frida_asset_arch}.xz" -o /tmp/frida-server.xz; \
    xz -dc /tmp/frida-server.xz >/usr/local/bin/frida-server; \
    chmod 0755 /usr/local/bin/frida-server; \
    rm -f /tmp/frida-server.xz; \
    ln -sf /usr/bin/python3 /usr/local/bin/python

RUN set -eux; \
    jaq_arch="$(dpkg --print-architecture)"; \
    case "${jaq_arch}" in \
        amd64) jaq_asset_arch=x86_64-unknown-linux-gnu ;; \
        arm64) jaq_asset_arch=aarch64-unknown-linux-gnu ;; \
        armhf) jaq_asset_arch=armv7-unknown-linux-gnueabihf ;; \
        *) echo "Unsupported jaq architecture: ${jaq_arch}" >&2; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/01mf02/jaq/releases/download/v${JAQ_VERSION}/jaq-${jaq_asset_arch}" -o /usr/local/bin/jaq; \
    chmod 0755 /usr/local/bin/jaq

RUN set -eux; \
    curl -fL https://raw.githubusercontent.com/hugsy/gef/main/gef.py -o /opt/gef.py; \
    printf '%s\n' \
        'set disassembly-flavor intel' \
        'set pagination off' \
        'source /opt/gef.py' \
        >/etc/gdb/gdbinit

RUN set -eux; \
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then \
        ln -s "$(command -v batcat)" /usr/local/bin/bat; \
    fi; \
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then \
        ln -s "$(command -v fdfind)" /usr/local/bin/fd; \
    fi; \
    mkdir -p /etc/fish/conf.d; \
    printf '%s\n' \
        'set -gx EDITOR nvim' \
        'fish_add_path /opt/revenv/bin' \
        '' \
        'if command -q zoxide' \
        '    zoxide init fish | source' \
        'end' \
        '' \
        "alias cat='bat --paging=never'" \
        "alias la='eza -lah --group-directories-first --git --icons=auto'" \
        "alias ll='eza -lh --group-directories-first --git --icons=auto'" \
        "alias ls='eza --group-directories-first --icons=auto'" \
        "alias py='python3'" \
        >/etc/fish/conf.d/re-toolkit.fish; \
    printf '%s\n' \
        'export EDITOR=nvim' \
        'export PATH=/opt/revenv/bin:$PATH' \
        "alias cat='bat --paging=never'" \
        "alias la='eza -lah --group-directories-first --git --icons=auto'" \
        "alias ll='eza -lh --group-directories-first --git --icons=auto'" \
        "alias ls='eza --group-directories-first --icons=auto'" \
        "alias py='python3'" \
        'if command -v zoxide >/dev/null 2>&1; then' \
        '    eval "$(zoxide init bash)"' \
        'fi' \
        >/etc/profile.d/re-toolkit.sh

RUN set -eux; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'listen="${FRIDA_LISTEN:-0.0.0.0:${FRIDA_PORT:-27042}}"' \
        'log="${FRIDA_LOG:-/tmp/frida-server.log}"' \
        'if pgrep -x frida-server >/dev/null 2>&1; then' \
        '    echo "frida-server already running"' \
        '    exit 0' \
        'fi' \
        'sudo --preserve-env=PATH,FRIDA_LISTEN,FRIDA_PORT,FRIDA_LOG nohup frida-server -l "${listen}" "$@" >"${log}" 2>&1 &' \
        'sleep 0.5' \
        'if ! pgrep -x frida-server >/dev/null 2>&1; then' \
        '    test -f "${log}" && cat "${log}" >&2' \
        '    exit 1' \
        'fi' \
        'echo "frida-server listening on ${listen}"' \
        'echo "log: ${log}"' \
        >/usr/local/bin/start-frida-server; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'listen="${FRIDA_LISTEN:-0.0.0.0:${FRIDA_PORT:-27042}}"' \
        'exec sudo --preserve-env=PATH frida-server -l "${listen}" "$@"' \
        >/usr/local/bin/frida-server-foreground; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'sudo pkill -x frida-server 2>/dev/null || true' \
        'echo "frida-server stopped"' \
        >/usr/local/bin/stop-frida-server; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'host="${FRIDA_HOST:-127.0.0.1:${FRIDA_PORT:-27042}}"' \
        'exec frida-ps -H "${host}" "$@"' \
        >/usr/local/bin/frida-ps-local; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'if [[ $# -lt 1 ]]; then' \
        '    echo "usage: frida-attach-local <pid|process-name> [frida args...]" >&2' \
        '    exit 2' \
        'fi' \
        'target="$1"' \
        'shift' \
        'host="${FRIDA_HOST:-127.0.0.1:${FRIDA_PORT:-27042}}"' \
        'if [[ "${target}" =~ ^[0-9]+$ ]]; then' \
        '    exec frida -H "${host}" -p "${target}" "$@"' \
        'fi' \
        'exec frida -H "${host}" -n "${target}" "$@"' \
        >/usr/local/bin/frida-attach-local; \
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'cat <<EOF' \
        'setup:       ./setup.sh' \
        'shell:       ./run.sh' \
        'up:          ./run.sh up' \
        'server:      ./run.sh server' \
        'stop:        ./run.sh stop' \
        'daemon:      start-frida-server' \
        'ps:          frida-ps-local' \
        'attach:      frida-attach-local <pid|name> -l hook.js' \
        'host ps:     frida-ps -H 127.0.0.1:27042 -a' \
        'foreground:  frida-server-foreground' \
        'EOF' \
        >/usr/local/bin/re-help; \
    chmod 0755 \
        /usr/local/bin/start-frida-server \
        /usr/local/bin/frida-server-foreground \
        /usr/local/bin/stop-frida-server \
        /usr/local/bin/frida-ps-local \
        /usr/local/bin/frida-attach-local \
        /usr/local/bin/re-help

RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    user_group="$(getent group "${USER_GID}" | cut -d: -f1)"; \
    useradd --uid "${USER_UID}" --gid "${user_group}" --create-home --shell /usr/bin/fish "${USERNAME}"; \
    usermod -aG sudo "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/"${USERNAME}"; \
    chmod 0440 /etc/sudoers.d/"${USERNAME}"; \
    mkdir -p /workspace; \
    chown -R "${USERNAME}:${user_group}" /workspace /opt/revenv

EXPOSE 27042 27043
WORKDIR /workspace
USER ${USERNAME}
CMD ["fish", "-l"]
