#!/usr/bin/env bash
# Phase 3: turns off (pm disable-user, never uninstall) each package of a profile, with Free My TV's own protections.
#   TV=<ip> ./tools/debloat/2-aplicar.sh perfis/tcl-c06.txt           shows what it would do
#   TV=<ip> ./tools/debloat/2-aplicar.sh perfis/tcl-c06.txt --valer   does it
source "$(dirname "$0")/common.sh"
PLAN="${1:-}"; APPLY=false; [ "${2:-}" = "--valer" ] && APPLY=true
[ -n "$PLAN" ] || { echo "Uso: TV=<ip> $0 perfis/<perfil>.txt [--valer]"; exit 1; }
[ -f "$PLAN" ] || PLAN="$HERE/$PLAN"
[ -f "$PLAN" ] || { echo "Perfil não encontrado: $1"; exit 1; }
LOG="$OUT/aplicados.txt"
[ -f "$OUT/donos-do-wifi.txt" ] || { echo "Rode o 1-inventario.sh nesta TV antes"; exit 1; }
# Free My TV's PROTECTED list, read from the code so it stays current
awk '/Set<String> PROTECTED/,/\)\);/' "$ROOT/app/src/io/freemytv/HomeMode.java" | grep -oE '"[^"]+"' | tr -d '"' > "$OUT/.protected.txt"
[ -s "$OUT/.protected.txt" ] || { echo "Não li a lista PROTECTED do HomeMode.java"; exit 1; }
# HomeMode's CORE and FACTORY patterns, plus Google's services, the Play Store and Free My TV itself
CORE='^(android|com\.android\.(systemui|shell|phone|settings|tv\.settings)|com\.(google\.)?android\.(permissioncontroller|packageinstaller|ext\.services|ext\.shared|modulemetadata)|com\.google\.android\.overlay\.modules.*|com\.android\.providers\..*|com\.google\.android\.(gms|gsf)|com\.android\.vending|io\.freemytv)$'
FACTORY='^(.*\.)?(factory|factorymenu|facmenu|fac|hkcfac|testpq)(\..*)?$'
ok=0; skip=0
while IFS= read -r line; do
  p="$(printf '%s' "${line%%#*}" | tr -d ' \t')"; [ -z "$p" ] && continue
  why=""
  grep -qxF "$p" "$OUT/.protected.txt" && why="protegido no HomeMode"
  [ -z "$why" ] && printf '%s' "$p" | grep -qE "$CORE" && why="peça do Android"
  [ -z "$why" ] && printf '%s' "$p" | grep -qE "$FACTORY" && why="menu de fábrica"
  [ -z "$why" ] && grep -qxF "$p" "$OUT/donos-do-wifi.txt" && why="salvou uma rede Wi-Fi"
  [ -z "$why" ] && grep -qxF "$p" "$OUT/usam-entradas-hdmi.txt" && why="usado pelas entradas HDMI/tuner"
  [ -z "$why" ] && ! S pm list packages -e "$p" | grep -qxF "package:$p" && why="já desligado ou ausente"
  if [ -n "$why" ]; then echo "PULA  $p ($why)"; skip=$((skip+1)); continue; fi
  if $APPLY; then
    if S pm disable-user --user 0 "$p" | grep -q "disabled"; then echo "$p" >> "$LOG"; echo "OFF   $p"; ok=$((ok+1))
    else echo "FALHA $p"; fi
  else echo "FARIA $p"; ok=$((ok+1)); fi
done < "$PLAN"
if $APPLY; then echo "---- $ok desligados, $skip pulados. Registro: $LOG. Agora: TV=$TV $HERE/3-testar.sh"
else echo "---- $ok para desligar, $skip pulados. Para aplicar: acrescente --valer"; fi
