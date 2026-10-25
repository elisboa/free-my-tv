#!/usr/bin/env bash
# Turns back on what 2-aplicar.sh turned off, last first.
#   TV=<ip> ./tools/debloat/9-reverter.sh            everything
#   TV=<ip> ./tools/debloat/9-reverter.sh <pacote>   one package
source "$(dirname "$0")/common.sh"
LOG="$OUT/aplicados.txt"
if [ -n "${1:-}" ]; then
  S pm enable "$1"; [ -f "$LOG" ] && { grep -vxF "$1" "$LOG" > "$LOG.tmp" || true; mv "$LOG.tmp" "$LOG"; }; exit 0
fi
[ -s "$LOG" ] || { echo "Nada a reverter"; exit 0; }
{ tail -r "$LOG" 2>/dev/null || tac "$LOG"; } | while IFS= read -r p; do S pm enable "$p"; done
mv "$LOG" "$LOG.revertido-$(date +%Y%m%d-%H%M)"
echo "Tudo religado."
