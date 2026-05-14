#!/usr/bin/env bash
set -euo pipefail

# このスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_functions"

# コンテナで動いているかどうか
if [ -f /.dockerenv ] || grep -q 'docker\|container' /proc/1/cgroup 2>/dev/null; then
  log_step "Jenkins・Caddy を直接起動します"
else
  log_error "このスクリプトはコンテナ内で実行する必要があります"
  exit 1
fi

# Java と caddy のパスを取得
JAVA_BIN="$(command -v java)"
CADDY_BIN="$(command -v caddy)"

# jenkins.war のパスを取得
# shellcheck disable=SC2016
JENKINS_WAR="$(nix eval --raw "nixpkgs#jenkins" --apply 'p: "${p}/webapps/jenkins.war"' 2>/dev/null)"

# Caddy の設定ファイルのパス
CADDY_CONF="${HOME}/.config/caddy/Caddyfile"

# 事前チェック
log_debug "JAVA_BIN:    ${JAVA_BIN}"
log_debug "CADDY_BIN:   ${CADDY_BIN}"
log_debug "JENKINS_WAR: ${JENKINS_WAR}"
log_debug "CADDY_CONF:  ${CADDY_CONF}"

if [[ ! -f "${CADDY_CONF}" ]]; then
  log_error "Caddyfile が見つかりません: ${CADDY_CONF}"
  log_error "  home-manager switch が完了しているか確認してください"
  exit 1
fi

# 終了時に停止する
function finally_cleanup {
  log_step "caddy を停止します..."
  pkill -f "${JAVA_BIN}.*${JENKINS_WAR}" || true
  pkill -f "${CADDY_BIN}.*-config ${CADDY_CONF}" || true
}
trap finally_cleanup EXIT

log_step "Jenkins を起動します..."
"${JAVA_BIN}" -jar "${JENKINS_WAR}" --httpPort=8080 2>&1 | sed 's/^/[JENKINS] /' &

log_step "Caddy を起動します..."
"${CADDY_BIN}" run --config "${CADDY_CONF}" 2>&1 | sed 's/^/[CADDY] /' &

log_step "Jenkins: http://localhost:8080"
log_step "Caddy:   http://localhost:80"

wait
