#!/usr/bin/env bash
set -Eeuo pipefail

SERVER_BIN="./tfs"
BUILD_BIN="build-release/tfs"
SESSION_NAME="tfs"
TAIL_SECONDS=30
PROC_TIMEOUT=30

# 1. Aguardar processo existente encerrar
PID=$(pgrep -x tfs || true)
if [ -n "$PID" ]; then
    echo "[DEPLOY] Server rodando (PID $PID). Enviando SIGTERM..."
    kill -SIGTERM "$PID"
    echo "[DEPLOY] Aguardando processo $PID encerrar (timeout=${PROC_TIMEOUT}s)..."
    _start_ts=$(date +%s)
    while kill -0 "$PID" 2>/dev/null; do
        _elapsed=$(( $(date +%s) - _start_ts ))
        if [ "$_elapsed" -ge "$PROC_TIMEOUT" ]; then
            echo "[DEPLOY] Timeout do SIGTERM. Enviando SIGKILL para $PID..."
            kill -SIGKILL "$PID" 2>/dev/null || true
            sleep 2
            if kill -0 "$PID" 2>/dev/null; then
                echo "[DEPLOY] ERRO: Processo $PID sobreviveu ao SIGKILL. Abortando."
                exit 1
            fi
            break
        fi
        sleep 2
    done
    echo "[DEPLOY] Processo $PID encerrado."
else
    echo "[DEPLOY] Nenhum processo tfs encontrado."
fi

# 2. Substituir binario
if [ ! -f "$BUILD_BIN" ]; then
    echo "[DEPLOY] ERRO: Binario de build '$BUILD_BIN' nao encontrado."
    exit 1
fi
if [ ! -x "$BUILD_BIN" ]; then
    chmod +x "$BUILD_BIN"
fi
cp -f "$BUILD_BIN" "$SERVER_BIN"
chmod +x "$SERVER_BIN"
ldd "$SERVER_BIN"
echo "[DEPLOY] Binario substituido com sucesso."

# 3. Matar sessao tmux antiga
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# 4. Iniciar servidor em sessao tmux
if [ ! -f "./start.sh" ]; then
    echo "[DEPLOY] ERRO: Script ./start.sh nao encontrado."
    exit 1
fi
if [ ! -x "./start.sh" ]; then
    chmod +x "./start.sh"
fi
tmux new-session -d -s "$SESSION_NAME" "./start.sh"

# 5. Tail do log
sleep 3
LATEST_LOG=$(find logs -maxdepth 1 -type f -name '*.log' -printf '%T@ %p\0' 2>/dev/null \
    | sort -rnz \
    | head -z -n1 \
    | cut -z -d' ' -f2- \
    | tr '\0' '\n')
if [ -n "$LATEST_LOG" ]; then
    echo "[DEPLOY] Log: $LATEST_LOG"
    echo "[DEPLOY] === Inicio do output do servidor ==="
    timeout "$TAIL_SECONDS" tail -f "$LATEST_LOG" || true
    echo "[DEPLOY] === Fim do output (servidor continua no tmux) ==="
else
    echo "[DEPLOY] Nenhum log encontrado. Servidor iniciado no tmux."
fi

echo "[DEPLOY] Acesse: tmux attach -t $SESSION_NAME"