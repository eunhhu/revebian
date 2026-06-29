# Revebian

Revebian은 동적 디버깅과 Frida 기반 리버스 엔지니어링을 위한 작은 Docker x64 Linux 작업 환경입니다.

의도적으로 가볍게 만들었습니다. Radare2, Ghidra, 컴파일러 툴체인, pwntools, rr, Valgrind, LLDB, 패킷 스캐너 같은 큰 도구는 넣지 않았습니다. 핵심은 Frida, frida-server, GDB, syscall/library tracing, 그리고 편한 shell 환경입니다.

English documentation: [README.md](README.md)

## 포함된 것

- Frida CLI와 버전이 맞는 `frida-server`
- GDB, GEF, `gdbserver`
- `strace`, `ltrace`, `lsof`, `file`, `binutils`, `xxd`
- `/opt/revenv` 아래 Python 3 가상환경
- `fish`, `zoxide`, `bat`, `neovim`, `tmux`, `eza`, `jq`, `jaq`, `ripgrep`
- 로컬 Frida 포트 포워딩이 설정된 Docker Compose 구성

## 요구사항

- Docker
- Docker Compose plugin
- `linux/amd64` 컨테이너를 실행할 수 있는 환경

Apple Silicon에서는 Docker Desktop이 amd64 emulation으로 이 이미지를 실행합니다. 이 환경은 x64 Linux 디버깅을 목표로 하므로 정상입니다.

## 빠른 시작

이미지 빌드:

```bash
./setup.sh
```

컨테이너를 띄우고, `frida-server`를 시작하고, 포트를 포워딩한 뒤 `fish`로 진입:

```bash
./run.sh
```

포워딩된 Frida server를 통해 프로세스 목록 확인:

```bash
./run.sh ps
```

컨테이너와 네트워크 정리:

```bash
./run.sh stop
```

## Frida 포트 포워딩

기본 Compose 설정은 Frida 포트를 localhost에만 바인딩합니다.

```text
127.0.0.1:27042 -> container:27042
127.0.0.1:27043 -> container:27043
```

이렇게 하면 내 머신에서는 Frida server에 접근할 수 있지만, 외부 네트워크에는 노출되지 않습니다.

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
./run.sh shell      # 기본값: 컨테이너 + frida-server 시작 후 fish 진입
./run.sh up         # 컨테이너 + frida-server를 백그라운드로 시작
./run.sh server     # frida-server Compose 서비스를 foreground로 실행
./run.sh ps         # frida-server를 통해 프로세스 목록 확인
./run.sh attach ... # frida-server를 통해 attach
./run.sh stop       # 컨테이너를 멈추고 Compose 네트워크 제거
./run.sh rebuild    # 이미지 다시 빌드
./run.sh help       # 도움말 출력
```

컨테이너 안에서는 `re-help`로 자주 쓰는 명령을 다시 볼 수 있습니다.

## 작업 디렉터리

프로젝트 디렉터리는 컨테이너 안에서 다음 위치에 마운트됩니다.

```text
/workspace
```

호스트의 이 repository에 둔 파일은 컨테이너 안에서도 그대로 보입니다.

## 포트 변경

호스트 쪽 Frida 포트는 환경변수로 바꿀 수 있습니다.

```bash
FRIDA_HOST_PORT=37042 FRIDA_CONTROL_PORT=37043 ./run.sh
```

컨테이너 내부에서는 계속 `27042`, `27043`으로 listen합니다. 바뀌는 것은 호스트 바인딩뿐입니다.

## 완전 새로 빌드

```bash
./run.sh stop
./setup.sh --no-cache
```

## 참고

- 이미지는 의도적으로 최소 구성입니다. 무거운 정적 분석 도구가 필요하면 별도 설치하거나 별도 이미지를 만드는 편이 낫습니다.
- `frida-server`는 컨테이너 안에서 실행됩니다. 같은 컨테이너 안에서 실행 중인 프로세스를 대상으로 쓰는 용도입니다.
- 기본 Compose 설정은 GDB와 Frida가 정상 동작하도록 ptrace 관련 capability를 추가하고 기본 seccomp profile을 끕니다.
