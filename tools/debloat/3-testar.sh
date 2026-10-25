#!/usr/bin/env bash
# Phase 4: restarts the TV and records its state afterwards. The eye test (picture, sound, HDMI, remote, Wi-Fi) is yours.
source "$(dirname "$0")/common.sh"
echo "Reiniciando a TV..."; A reboot || true
sleep 20; for i in $(seq 1 30); do adb connect "$TV" >/dev/null 2>&1; [ "$(S getprop sys.boot_completed 2>/dev/null)" = "1" ] && break; sleep 5; done
{
  echo "boot=$(S getprop sys.boot_completed)"; echo "home=$(home)"
  echo "wifi=$(S dumpsys wifi | grep -m1 -E 'mWifiInfo|Wi-Fi is')"
  echo "entradas:"; S dumpsys tv_input | grep -oE 'TvInputInfo\{id=[^,]+' | sort -u
  echo "crashes:"; S logcat -d -b crash | tail -30
} > "$OUT/teste-$(date +%Y%m%d-%H%M).txt"
echo "Coletado em $OUT. Confira na TV: imagem, som, cada HDMI, TV aberta, controle, Wi-Fi, Play Store."
