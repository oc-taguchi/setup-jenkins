#!/usr/bin/env bash
set -euo pipefail

# このスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_functions"

# 実行ユーザーの取得
USER="${SUDO_USER:-$(whoami)}"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
NIX_DIR="$(cd "${SCRIPT_DIR}/../nix" && pwd)"

# 引数のパース
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) _DEBUG=$2; shift 2;;
    --dry-run) _DRY_RUN=$2; shift 2;;
    *) shift ;;
  esac
done

# 受けとった引数を表示
log_debug "--debug=${_DEBUG:="false"}"
log_debug "--dry-run=${_DRY_RUN:="false"}"

args=()

# デバッグ出力の有効化
if [ "${_DEBUG}" = "true" ]; then
  set -x
  args+=("--show-trace")
fi

# DRY_RUN モード用のコマンドプレフィックス
if [[ $_DRY_RUN == "true" ]]; then
  echo "[DRY-RUN] home-manager switch コマンドは実行されません"
  args+=("--dry-run")
fi

# 変数の表示
log_debug "SCRIPT_DIR: ${SCRIPT_DIR}"
log_debug "DOTFILES_DIR: ${DOTFILES_DIR}"
log_debug "NIX_DIR: ${NIX_DIR}"
log_debug "USER: ${USER}"

log_step ""
log_step "==> home-manager の実行"

if command -v home-manager &>/dev/null; then
  log_debug nix flake update --flake "${NIX_DIR}"
  nix flake update --flake "${NIX_DIR}"

  log_debug home-manager switch --flake "${NIX_DIR}#${USER}" "${args[@]}"
  home-manager switch --flake "${NIX_DIR}#${USER}" "${args[@]}"

  log_step "古い世代をすべて削除してガベージコレクションを実行します..."
  nix-collect-garbage -d
else
  log_step "nix run home-manager switch を実行します..."
  nix run home-manager/master -- switch --flake "${NIX_DIR}#${USER}" -b backup
fi
