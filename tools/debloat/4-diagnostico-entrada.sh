#!/usr/bin/env bash
# Diagnoses USB and Bluetooth input devices (keyboards, gamepads): what the kernel, the input system and Bluetooth see
# before and after you plug or pair one. Read-only. Results in out/<ip>/diag-<time>/.
#   TV=<ip> ./tools/debloat/4-diagnostico-entrada.sh
source "$(dirname "$0")/common.sh"
D="$OUT/diag-$(date +%Y%m%d-%H%M)"; mkdir -p "$D"
snap() {   # $1: before | after
  S cat /proc/bus/input/devices > "$D/$1-kernel-input.txt" 2>&1 || true
  S dumpsys input > "$D/$1-dumpsys-input.txt" 2>&1 || true
  S dumpsys usb > "$D/$1-usb.txt" 2>&1 || true
  S ls -l /dev/input /dev/bus/usb > "$D/$1-dev.txt" 2>&1 || true
  S 'for d in /sys/bus/usb/devices/*; do [ -f $d/idVendor ] && echo "$d $(cat $d/idVendor):$(cat $d/idProduct) $(cat $d/product 2>/dev/null) driver=$(basename $(readlink $d/driver 2>/dev/null) 2>/dev/null)"; done' > "$D/$1-usb-sysfs.txt" 2>&1 || true
  S dumpsys bluetooth_manager > "$D/$1-bluetooth.txt" 2>&1 || true
}
echo "1/3 Lendo o estado atual (deixe teclado, dongle e joystick DESPLUGADOS)..."
{
  echo "modelo=$(S getprop ro.product.model) android=$(S getprop ro.build.version.release) build=$(S getprop ro.build.display.id)"
  echo "acessibilidade=$(S settings get secure enabled_accessibility_services)"
  echo "bt_on=$(S settings get global bluetooth_on)"
  echo "otg/host:"; S getprop | grep -iE 'usb|otg|hid' | head -40
  echo "desligados:"; S pm list packages -d | sed 's/^package://' | sort
} > "$D/info.txt" 2>&1
snap antes
S logcat -c || true
echo
echo "2/3 Agora, na TV:"
echo "   a) Plugue o dongle do Logitech K400+ e digite algumas teclas."
echo "   b) Plugue o dongle do joystick e aperte alguns botões."
echo "   c) Tente parear o joystick por Bluetooth (Configurações > Controles e acessórios > Adicionar)."
read -r -p "   Quando terminar os três, aperte Enter aqui (deixe tudo plugado)... " _
snap depois
S logcat -d -v time > "$D/logcat.txt" 2>&1 || true
grep -iE 'bluetooth|bt_|bond|pair|hid|hogp|usb|input(reader|dispatcher|manager)?|eventhub|keyboard|gamepad|accessib|freemytv' "$D/logcat.txt" > "$D/logcat-filtrado.txt" || true
echo
echo "3/3 Pronto: $D"
diff <(grep -E '^N: ' "$D/antes-kernel-input.txt") <(grep -E '^N: ' "$D/depois-kernel-input.txt") || true
echo "Avise o Claude: ele lê essa pasta."
