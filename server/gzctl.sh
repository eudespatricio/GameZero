#!/usr/bin/env bash
# ==============================================================================
# gzctl.sh — Controlador de Daemon do Servidor de Contas GameZero (WSL)
# Uso: gzctl.sh {start|stop|restart|status}
# ==============================================================================

D="$(cd "$(dirname "$0")" && pwd)"
PID="$D/gz.pid"
LOG="$D/server.log"
PY="python3"

alive() {
    if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then
        return 0
    fi
    if ss -ltn 2>/dev/null | grep -q ":8088 "; then
        return 0
    fi
    return 1
}

case "$1" in
    start)
        if alive; then
            echo "GameZero Server já ativo (PID $(cat "$PID" 2>/dev/null || fuser 8088/tcp 2>/dev/null))"
            exit 0
        fi
        cd "$D/.." && setsid nohup "$PY" server/main.py --port 8088 >>"$LOG" 2>&1 </dev/null &
        echo $! >"$PID"
        sleep 1.5
        WSL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
        if alive; then
            echo "✅ GameZero Server ativo (PID $(cat "$PID" 2>/dev/null || fuser 8088/tcp 2>/dev/null))"
            echo "   🌐 Local / Windows: http://localhost:8088"
            [ -n "$WSL_IP" ] && echo "   🌐 Rede WSL2:       http://${WSL_IP}:8088"
        else
            echo "❌ Falha ao iniciar GameZero Server, verifique $LOG"
            exit 1
        fi
        ;;

    stop)
        if [ -f "$PID" ]; then
            kill "$(cat "$PID")" 2>/dev/null && echo "GameZero Server parado (PID $(cat "$PID"))"
            rm -f "$PID"
        fi
        fuser -k 8088/tcp 2>/dev/null || true
        pkill -f "server/main\.py --port 8088" 2>/dev/null || true
        rm -f "$PID"
        ;;

    restart)
        "$0" stop
        sleep 1
        "$0" start
        ;;

    status)
        WSL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
        if alive; then
            echo "🟢 GameZero Server ativo PID $(cat "$PID" 2>/dev/null || fuser 8088/tcp 2>/dev/null) · http://localhost:8088 (${WSL_IP:+http://${WSL_IP}:8088})"
            curl -s http://127.0.0.1:8088/health
            echo ""
        else
            echo "🔴 GameZero Server parado"
            exit 1
        fi
        ;;

    *)
        echo "Uso: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
