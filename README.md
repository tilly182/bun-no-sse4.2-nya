# bun-barcelona

Automatic [Bun](https://bun.sh) builds for x86_64 CPUs **without SSE4.2 / SSE4.1 / SSSE3 / AVX** — AMD K10 (Athlon II X4, Phenom, Opteron), pre-2008 microarchitectures. Every upstream Bun release gets its own release page and binary here.

## Install the newest build

```sh
curl -fsSL https://raw.githubusercontent.com/tilly182/bun-no-sse4.2-nya/main/install.sh | sh
```

`~/.bun-barcelona/{bun,bun-barcelona,lib}` + a `bun` symlink in `~/.local/bin`. Call the wrapper `bun`, never `bun-barcelona` (it needs `LD_LIBRARY_PATH` for the bundled ICU).

```sh
bun -e 'console.log([...new Int32Array([5,3,8,1,9]).sort()])'   # → [ 1, 3, 5, 8, 9 ]
```

Env: `BARCELONA_REPO=owner/repo` (release source), `BARCELONA_TAG=v1.4.2-barcelona` (pin), `BARCELONA_HOME`, `BARCELONA_BIN=''` (no PATH link), `BARCELONA_DRY=1` (resolve only).

## How it works

`.github/workflows/barcelona.yml` runs hourly: resolve the newest unshipped `bun-vX.Y.Z` tag → clone that tag → `-march=barcelona` for C/C++ and Rust → WebKit/JavaScriptCore compiled locally → `--baseline=true` → **execute the binary under `qemu -cpu core2duo`** (SSE3-only, no popcnt: stricter than K10) → publish release `vX.Y.Z-barcelona`.

Stable download link, always the newest: `releases/latest/download/bun-barcelona-linux-x64.tar.gz`.

Recipe from [bunihateyou/bun-no-sse4.2](https://github.com/bunihateyou/bun-no-sse4.2); this repo is standalone (not a fork), so Actions runs by default — if no build ever appears, check **Settings → Actions → General → Allow all actions**.

Programs *built on* Bun (omp, claude-code, opencode) ship their own SSE4.2 binaries and `.node` addons — those need separate treatment: [run-without-sse4.2](https://github.com/bunihateyou/run-without-sse4.2).
