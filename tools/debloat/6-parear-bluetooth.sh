#!/usr/bin/env bash
# Pairs a new Bluetooth device (gamepad, keyboard) without leaving Free My TV. On a TCL C06 (Android TV 11) the
# pairing dialog ignores OK while the stock home screen (tvlauncher) is off, and the pairing times out. This turns it
# on for the pairing only, keeps Free My TV as the home screen, and turns it off again afterwards.
#   TV=<ip> ./tools/debloat/6-parear-bluetooth.sh
source "$(dirname "$0")/common.sh"
LAUNCHER=com.google.android.tvlauncher
OURS=io.freemytv/.HomeActivity
off_again() {
  S pm disable-user --user 0 "$LAUNCHER" >/dev/null
  S cmd package set-home-activity "$OURS" >/dev/null
  echo "Tela de fábrica desligada de novo. Tela inicial: $(home)"
}
S pm list packages -d | grep -qxF "package:$LAUNCHER" || { echo "A tela de fábrica já está ligada: nada a fazer (modo Original?)."; exit 0; }
S pm enable "$LAUNCHER" >/dev/null
S cmd package set-home-activity "$OURS" >/dev/null
trap off_again EXIT    # also on Ctrl+C
echo "Tela de fábrica ligada só para o pareamento (a tela inicial continua: $(home))."
echo "Na TV: Configurações > Controles remotos e acessórios > Adicionar acessório, e confirme com OK."
read -r -p "Quando terminar de parear, aperte Enter aqui... " _
S dumpsys bluetooth_manager | sed -n '/Bonded devices:/,/^$/p' | head -12
