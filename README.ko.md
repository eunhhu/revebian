# Revebian

Revebian은 가벼운 x64 Linux 디버깅 컨테이너를 실행하기 위한 설치형 CLI입니다.

동적 디버깅과 Frida 기반 리버스 엔지니어링에 맞춰 만들었습니다. 기본 이미지는 의도적으로 작게 유지합니다. Radare2, Ghidra, 컴파일러 툴체인, pwntools, rr, Valgrind, LLDB, 네트워크 스캐닝 번들은 넣지 않았습니다. Wine은 선택 빌드로만 넣을 수 있습니다.

English documentation: [README.md](README.md)

## 포함된 것

- 호스트에서 쓰는 단일 CLI: `revebian`
- Frida CLI와 버전이 맞는 `frida-server`
- GDB, GEF, `gdbserver`
- `strace`, `ltrace`, `lsof`, `file`, `binutils`, `xxd`
- `/opt/revenv` 아래 Python 3 가상환경
- `fish`, `zoxide`, `bat`, `neovim`, `tmux`, `eza`, `jq`, `jaq`, `ripgrep`
- localhost 전용 Frida 포트 포워딩이 설정된 Docker Compose 구성
- `revebian build --wine`으로 켤 수 있는 선택 Wine 빌드

## 요구사항

- Docker
- Docker Compose plugin
- `linux/amd64` 컨테이너를 실행할 수 있는 환경

Apple Silicon에서는 Docker Desktop이 amd64 emulation으로 이 이미지를 실행합니다. 이 환경은 x64 Linux 디버깅을 목표로 하므로 정상입니다.

## CLI 설치

이 repository에서:

```bash
./revebian install
```

기본 설치 위치:

```text
~/.local/bin/revebian
```

`~/.local/bin`이 `PATH`에 들어 있어야 합니다. 다른 위치에 설치할 수도 있습니다.

```bash
./revebian install --target /usr/local/bin/revebian
```

설치된 명령은 이 repository의 `revebian` 파일을 가리키는 symlink입니다. repository를 옮기면 다시 설치하거나 `REVEBIAN_HOME=/path/to/revebian`을 지정하세요.

`REVEBIAN_HOME`은 이 도구의 repository 위치입니다. 컨테이너에 마운트되는 작업 디렉터리가 아닙니다.

설치하지 않고 로컬 실행 파일을 바로 써도 됩니다.

```bash
./revebian doctor
```

## 빠른 시작

기본 슬림 이미지 빌드:

```bash
revebian build
```

컨테이너를 띄우고, `frida-server`를 시작하고, 포트를 포워딩한 뒤 `fish`로 진입:

```bash
revebian
```

포워딩된 Frida server로 프로세스 목록 확인:

```bash
revebian ps
```

컨테이너와 네트워크 정리:

```bash
revebian stop
```

## 선택 Wine 이미지

Wine은 이미지를 많이 무겁게 만들기 때문에 기본으로 포함하지 않습니다.

필요할 때만 Wine 포함 이미지로 빌드하세요.

```bash
revebian build --wine
```

그 다음 평소처럼 실행합니다.

```bash
revebian
```

다시 슬림 이미지로 돌아가려면:

```bash
revebian build --no-wine --no-cache
```

## Frida 포트 포워딩

기본 Compose 설정은 Frida 포트를 localhost에만 바인딩합니다.

```text
127.0.0.1:27042 -> container:27042
127.0.0.1:27043 -> container:27043
```

이렇게 하면 내 머신에서는 Frida server에 접근할 수 있지만 외부 네트워크에는 노출되지 않습니다.

호스트에서:

```bash
frida-ps -H 127.0.0.1:27042
```

컨테이너 안에서:

```bash
frida-ps-local
frida-attach-local <pid|process-name> -l hook.js
```

## 명령어

```bash
revebian              # 기본값: 컨테이너 + frida-server 시작 후 fish 진입
revebian shell        # 기본값과 동일
revebian up           # 컨테이너 + frida-server를 백그라운드로 시작
revebian server       # frida-server Compose 서비스를 foreground로 실행
revebian ps           # frida-server를 통해 프로세스 목록 확인
revebian attach ...   # frida-server를 통해 attach
revebian exec ...     # 컨테이너 안에서 명령 실행
revebian build        # 슬림 이미지 빌드
revebian build --wine # Wine 포함 이미지 빌드
revebian install      # CLI symlink 설치
revebian uninstall    # CLI symlink 제거
revebian doctor       # 환경 상태 출력
revebian stop         # 컨테이너를 멈추고 Compose 네트워크 제거
revebian help         # 도움말 출력
```

컨테이너 안에서는 `re-help`로 자주 쓰는 호스트/컨테이너 명령을 다시 볼 수 있습니다.

## 작업 디렉터리

`revebian`을 실행한 현재 디렉터리가 컨테이너 안에서 다음 위치에 마운트됩니다.

```text
/workspace
```

예를 들어 `~/targets/foo`에서 `revebian`을 실행하면, 컨테이너 안의 `/workspace`는 `~/targets/foo`입니다.

명시적으로 다른 디렉터리를 마운트할 수도 있습니다.

```bash
REVEBIAN_WORKSPACE=/path/to/target revebian
```

Revebian repository는 `Dockerfile`, `docker-compose.yml`, CLI 자체를 찾는 용도로만 쓰입니다.

Docker Desktop에서는 workspace 경로가 Docker에 공유된 host 경로여야 합니다. 임시 디렉터리나 공유되지 않은 경로에서 실행했을 때 `/workspace`가 비어 보이면, 홈 디렉터리처럼 공유된 경로에서 실행하거나 `REVEBIAN_WORKSPACE`를 공유된 경로로 지정하세요.

## 포트 변경

호스트 쪽 Frida 포트는 환경변수로 바꿀 수 있습니다.

```bash
FRIDA_HOST_PORT=37042 FRIDA_CONTROL_PORT=37043 revebian
```

컨테이너 내부에서는 계속 `27042`, `27043`으로 listen합니다. 바뀌는 것은 호스트 바인딩뿐입니다.

## 참고

- 기본 이미지는 의도적으로 최소 구성입니다. Wine은 실제로 필요할 때만 `--wine`으로 빌드하세요.
- `frida-server`는 컨테이너 안에서 실행됩니다. 같은 컨테이너 안에서 실행 중인 프로세스를 대상으로 쓰는 용도입니다.
- 기본 Compose 설정은 GDB와 Frida가 정상 동작하도록 ptrace 관련 capability를 추가하고 기본 seccomp profile을 끕니다.
