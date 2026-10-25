#!/usr/bin/env bash
# Shared by the debloat scripts. The TV is required: TV=192.168.1.50 ./tools/debloat/1-inventario.sh
# (port 5555 is added when missing). Each TV gets its own folder in out/ (git-ignored: it describes your TV).
set -euo pipefail
[ -n "${TV:-}" ] || { echo "Diga qual TV: TV=<ip> $0 ..."; exit 1; }
case "$TV" in *:*) ;; *) TV="$TV:5555" ;; esac
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$HERE/out/${TV%%:*}"
mkdir -p "$OUT"
command -v adb >/dev/null || { echo "adb não encontrado no PATH"; exit 1; }
adb connect "$TV" >/dev/null 2>&1 || true
adb -s "$TV" get-state >/dev/null 2>&1 || { echo "A TV $TV não responde ao adb (depuração USB ligada? mesma rede?)"; exit 1; }
A() { adb -s "$TV" "$@"; }
# </dev/null: adb shell reads stdin, and inside a while-read loop it would swallow the rest of the list
S() { adb -s "$TV" shell "$@" </dev/null | tr -d '\r'; }
# The default home: `cmd role` exists only on Android 12 and newer
home() { S cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1; }
