#!/usr/bin/env bash
set -euo pipefail

# このスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_functions"

# コンテナで動いているかどうか
if [ -f /.dockerenv ] || grep -q 'docker\|container' /proc/1/cgroup 2>/dev/null; then
  log_step "Jenkins・nginx を直接起動します"
else
  log_error "このスクリプトはコンテナ内で実行する必要があります"
  exit 1
fi

# Java と nginx のパスを取得
JAVA_BIN="$(command -v java)"
NGINX_BIN="$(command -v nginx)"

# jenkins.war のパスを取得
# shellcheck disable=SC2016
JENKINS_WAR="$(nix eval --raw "nixpkgs#jenkins" --apply 'p: "${p}/webapps/jenkins.war"' 2>/dev/null)"

# nginx の設定ファイルのパス
NGINX_CONF="${HOME}/.config/nginx/nginx.conf"

# 事前チェック
log_debug "JAVA_BIN:    ${JAVA_BIN}"
log_debug "NGINX_BIN:   ${NGINX_BIN}"
log_debug "JENKINS_WAR: ${JENKINS_WAR}"
log_debug "NGINX_CONF:  ${NGINX_CONF}"

if [[ ! -f "${NGINX_CONF}" ]]; then
  log_error "nginx.conf が見つかりません: ${NGINX_CONF}"
  log_error "  home-manager switch が完了しているか確認してください"
  exit 1
fi

# nginx 設定テスト
log_step "nginx 設定を検証します..."
"${NGINX_BIN}" -c "${NGINX_CONF}" -t

# 終了時に停止する
function finally_cleanup {
  log_step "Jenkins・nginx を停止します..."
  pkill -f "${JAVA_BIN}.*${JENKINS_WAR}" || true
  pkill -f "${NGINX_BIN}.*-c ${NGINX_CONF}" || true
}
trap finally_cleanup EXIT

log_step "Jenkins を起動します..."
"${JAVA_BIN}" -jar "${JENKINS_WAR}" --httpPort=8080 2>&1 | sed 's/^/[JENKINS] /' &

log_step "nginx を起動します..."
"${NGINX_BIN}" -c "${NGINX_CONF}" -g 'daemon off;' 2>&1 | sed 's/^/[NGINX] /' &

log_step "Jenkins: http://localhost:8080"
log_step "nginx:   http://localhost:80"

wait
