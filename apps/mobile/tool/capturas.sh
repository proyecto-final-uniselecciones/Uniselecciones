#!/usr/bin/env bash
# =====================================================================
#  UniSelecciones · tool/capturas.sh
#  Toma las capturas de las cinco interfaces en escritorio y en móvil.
#
#  Requisitos previos:
#    1. flutter build web -t lib/main_vista_previa.dart --release
#    2. un servidor sirviendo build/web, por ejemplo:
#       python -m http.server 5599 --bind 127.0.0.1 --directory build/web
#
#  Uso:  bash tool/capturas.sh [carpeta_destino]
#
#  Dos detalles que costaron encontrar y que conviene no deshacer:
#
#  · --user-data-dir: sin un perfil propio, si ya hay un Chrome abierto
#    la instancia headless no escribe el archivo y deja el anterior.
#    El síntoma es que todas las capturas salen idénticas.
#
#  · Para móvil NO se puede pedir --window-size=414,...  Chrome no baja
#    de cierto ancho de ventana, así que Flutter cree que tiene más
#    espacio y la captura sale recortada a lo ancho. La vuelta es pedir
#    el doble de tamaño con --force-device-scale-factor=2: el viewport
#    en CSS queda en 414 y la imagen sale al doble de resolución.
# =====================================================================
set -euo pipefail

DESTINO="${1:-capturas}"
BASE="${BASE_URL:-http://127.0.0.1:5599}"
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
ESPERA="${ESPERA:-14000}"   # milisegundos de tiempo virtual para que arranque Flutter
PERFIL="${PERFIL:-$TEMP/uni_chrome_capturas}"

if [[ ! -f "$CHROME" ]]; then
    echo "No encuentro Chrome en: $CHROME" >&2
    exit 1
fi
if ! curl -sf -o /dev/null "$BASE/index.html"; then
    echo "No responde $BASE. ¿Está corriendo el servidor de build/web?" >&2
    exit 1
fi

mkdir -p "$DESTINO"
DESTINO_ABS="$(cd "$DESTINO" && pwd)"
DESTINO_WIN="$(cd "$DESTINO" && pwd -W | sed 's|/|\\|g')"

capturar() {  # capturar <nombre> <ancho_css> <alto_css> <escala> <url>
    local nombre="$1" ancho="$2" alto="$3" escala="$4" url="$5"
    local ventana_w=$((ancho * escala))
    local ventana_h=$((alto * escala))

    rm -f "$DESTINO_ABS/$nombre.png"
    printf '  %-36s %sx%s css  ' "$nombre" "$ancho" "$alto"
    "$CHROME" \
        --headless=new \
        --disable-gpu \
        --enable-unsafe-swiftshader \
        --hide-scrollbars \
        --user-data-dir="$PERFIL" \
        --force-device-scale-factor="$escala" \
        --window-size="$ventana_w,$ventana_h" \
        --virtual-time-budget="$ESPERA" \
        --screenshot="${DESTINO_WIN}\\${nombre}.png" \
        "$url" >/dev/null 2>&1 || true

    if [[ -f "$DESTINO_ABS/$nombre.png" ]]; then
        echo "ok ($(stat -c%s "$DESTINO_ABS/$nombre.png") bytes)"
    else
        echo "FALLO"
    fi
}

echo "==> Escritorio"
capturar "01-escritorio-acceso"             1440  900 1 "$BASE/#/login"
capturar "02-escritorio-panel-jugador"      1440 2150 1 "$BASE/?rol=jugador"
capturar "03-escritorio-panel-entrenador"   1440 2150 1 "$BASE/?rol=entrenador"
capturar "04-escritorio-panel-institucion"  1440 2150 1 "$BASE/?rol=institucion"

echo "==> Móvil (414 css, imagen al doble)"
capturar "05-movil-acceso"                   414  896 2 "$BASE/#/login"
capturar "06-movil-panel-jugador"            414 2400 2 "$BASE/?rol=jugador"
capturar "07-movil-panel-entrenador"         414 2400 2 "$BASE/?rol=entrenador"
capturar "08-movil-panel-institucion"        414 2400 2 "$BASE/?rol=institucion"

echo
echo "Capturas en: $DESTINO_ABS"
ls -1 "$DESTINO_ABS"
