#!/usr/bin/env bash
set -euo pipefail

ORACLE_IP="${1:-}"
if [[ -z "$ORACLE_IP" ]]; then
    echo "Usage: $0 <oracle-ip>"
    exit 1
fi

REMOTE_USER="ubuntu"
REMOTE_DIR="/home/${REMOTE_USER}/fps-server"

echo "[DEPLOY] Wgrywam na ${ORACLE_IP}..."
ssh "${REMOTE_USER}@${ORACLE_IP}" "mkdir -p ${REMOTE_DIR}/logs"

rsync -avz --progress \
    exports/fps-server \
    exports/fps-server.pck \
    "${REMOTE_USER}@${ORACLE_IP}:${REMOTE_DIR}/"

scp deploy/fps-server.service "${REMOTE_USER}@${ORACLE_IP}:/tmp/"
ssh "${REMOTE_USER}@${ORACLE_IP}" "sudo mv /tmp/fps-server.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable fps-server"

ssh "${REMOTE_USER}@${ORACLE_IP}" "chmod +x ${REMOTE_DIR}/fps-server"
ssh "${REMOTE_USER}@${ORACLE_IP}" "sudo systemctl restart fps-server"

echo "[DEPLOY] Gotowe. Logi: ssh ${REMOTE_USER}@${ORACLE_IP} 'tail -f ${REMOTE_DIR}/logs/server.log'"
