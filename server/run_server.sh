#!/usr/bin/env bash
# ==============================================================================
# run_server.sh — Inicializador do Servidor GameZero
# Uso: ./run_server.sh [--daemon]
# ==============================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" == "--daemon" ] || [ "$1" == "start" ]; then
    "$DIR/gzctl.sh" start
    exit $?
elif [ "$1" == "stop" ]; then
    "$DIR/gzctl.sh" stop
    exit $?
elif [ "$1" == "status" ]; then
    "$DIR/gzctl.sh" status
    exit $?
fi

cd "$DIR/.."
echo "=================================================="
echo "🛡️ INICIALIZANDO SERVIDOR DE CONTAS DO GAMEZERO"
echo "=================================================="
python3 server/main.py --port 8088
