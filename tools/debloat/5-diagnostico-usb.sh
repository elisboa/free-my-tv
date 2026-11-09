#!/usr/bin/env bash
# USB step by step: for each thing you plug (pendrive, keyboard receiver, with or without a hub), records what the
# TV's USB bus, input system and storage see, plus the kernel log when the TV allows reading it. Read-only.
#   TV=<ip> ./tools/debloat/5-diagnostico-usb.sh
source "$(dirname "$0")/common.sh"
D="$OUT/usb-$(date +%Y%m%d-%H%M)"; mkdir -p "$D"
{
  echo "modelo=$(S getprop ro.product.model) android=$(S getprop ro.build.version.release) build=$(S getprop ro.build.display.id)"
  echo "recursos:"; S pm list features | grep -iE 'usb|otg|gamepad|keyboard' || true
  echo "props:"; S getprop | grep -iE 'usb|otg' || true
} > "$D/info.txt" 2>&1
snap() {   # $1: step name. Each probe may find nothing (grep exits 1): that must not stop the script.
  local f="$D/$1"
  { echo "## barramento"; S 'ls /dev/bus/usb/*' || true
    echo "## dumpsys usb"; S dumpsys usb | grep -E 'name=/dev/bus|vendor_id|product_id|manufacturer_name|product_name|^ *class=' || true
    echo "## entrada"; S dumpsys input | grep -E '^ +[0-9]+: ' || true
    echo "## armazenamento"; S sm list-volumes all || true
    echo "## kernel"; S logcat -b kernel -d -t 60 2>&1 | grep -iE 'usb|hid|input|ehci|xhci|ohci|denied|invalid' | tail -40 || true
  } > "$f.txt" 2>&1
}
etapa() {   # $1: name, $2: instruction
  echo; echo ">> $2"
  read -r -p "   Plugue, espere 5 segundos e aperte Enter (ou digite p + Enter para pular)... " r
  [ "$r" = p ] && { echo "   pulado"; return; }
  snap "$1"
  local novos; novos="$(diff <(grep -E 'name=/dev/bus|product_name' "$D/0-nada.txt") <(grep -E 'name=/dev/bus|product_name' "$D/$1.txt") | grep '^>' || true)"
  if [ -n "$novos" ]; then echo "   NOVO no USB:"; echo "$novos" | sed 's/^>/     /'
  else echo "   Nada novo no USB."; fi
}
echo "Deixe TUDO desplugado das portas USB da TV e aperte Enter."; read -r _
snap 0-nada
etapa 1-pendrive-direto     "Pendrive direto na porta USB 1 da TV."
etapa 2-pendrive-porta2     "Pendrive direto na porta USB 2 (se a TV tiver; senão, pule)."
etapa 3-pendrive-hub        "Pendrive pelo hub (desplugue o pendrive da TV antes)."
etapa 4-k400-direto         "Só o receptor do K400+ direto na TV (sem hub)."
etapa 5-k400-hub            "Receptor do K400+ pelo hub (de preferência um hub com fonte própria)."
etapa 6-gamesir-direto      "Só o dongle do Gamesir G7 Pro direto na TV."
echo; echo "Pronto: $D. Avise o Claude."
