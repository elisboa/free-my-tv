#!/usr/bin/env bash
# Phase 1, read-only: nothing on the TV changes. Results in tools/debloat/out/<ip>/.
source "$(dirname "$0")/common.sh"
echo "Lendo a TV $TV..."
{
  echo "marca=$(S getprop ro.product.brand)"; echo "modelo=$(S getprop ro.product.model)"
  echo "device=$(S getprop ro.product.device)"; echo "android=$(S getprop ro.build.version.release)"
  echo "build=$(S getprop ro.build.display.id)"; echo "low_ram=$(S getprop ro.config.low_ram)"
  echo "ui_w=$(S getprop ro.surface_flinger.max_graphics_width)"
  echo "home=$(home)"
  echo "screensaver=$(S settings get secure screensaver_components)"
  echo "mem=$(S cat /proc/meminfo | head -1)"
} > "$OUT/modelo.txt"
S pm list packages -s -e -f | sed 's/^package://' | awk -F'=' '{print $NF"\t"substr($0,1,length($0)-length($NF)-1)}' | sort > "$OUT/sistema-ligados.tsv"
S pm list packages -d | sed 's/^package://' | sort > "$OUT/desligados.txt"
S pm list packages -3 | sed 's/^package://' | sort > "$OUT/instalados-por-voce.txt"
S dumpsys wifi | grep -oE '(cname|creatorName)=[^ ,]+' | cut -d= -f2 | sort -u > "$OUT/donos-do-wifi.txt" || true
echo "Procurando quem depende das entradas HDMI/tuner (leva ~1 min)..."
# 2>/dev/null on the TV: grep -q stops at the first match and dumpsys complains of a broken pipe
S 'for p in $(pm list packages -s -e | cut -d: -f2); do dumpsys package $p 2>/dev/null | grep -q TV_INPUT_HARDWARE && echo $p; done' | sort > "$OUT/usam-entradas-hdmi.txt" || true
S cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME > "$OUT/homes.txt" || true
S dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -60 > "$OUT/memoria.txt" || true
wc -l "$OUT"/*.txt "$OUT"/*.tsv
echo "Pronto: $OUT. Com o inventário, escreva um perfil em tools/debloat/perfis/ (ou peça ao Claude)."
