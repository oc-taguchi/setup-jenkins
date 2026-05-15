#!/usr/bin/env bash
set -euo pipefail

# このスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_functions"

CLOUD_INIT_YAML="${PWD}/cloud-init.yaml"

if [[ ! -f "${CLOUD_INIT_YAML}" ]]; then
  log_error "cloud-init.yaml が見つかりません: ${CLOUD_INIT_YAML}"
  exit 1
fi

log_step "cloud-init clean"
sudo cloud-init clean

log_step "cloud-init init"
sudo cloud-init init

log_step "cloud-init status"
if ! sudo cloud-init status --long; then
  log_error "cloud-init が失敗しました"
  exit 1
fi

log_step "cloud-init modules --mode=config"
sudo cloud-init modules --mode=config

log_step "cloud-init modules --mode=final"
sudo cloud-init modules --mode=final
