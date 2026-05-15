#!/usr/bin/env bash
set -euo pipefail

# このスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_functions"

# 実行ユーザーの取得
USER="${SUDO_USER:-$(whoami)}"

# 引数のパース
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) _DEBUG=$2; shift 2;;
    *) shift ;;
  esac
done

# 受けとった引数を表示
log_debug "--debug=${_DEBUG:="false"}"

# デバッグ出力の有効化
if [[ "${_DEBUG}" = "true" ]]; then
  set -x
fi

# 変数の表示
log_debug "SCRIPT_DIR: ${SCRIPT_DIR}"
log_debug "USER: ${USER}"

# nix のインストール確認
if ! command -v nix &>/dev/null; then

  log_step "nix をインストールします..."

  # shellcheck disable=SC2086
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes --no-confirm

  # nix コマンドがインストールされた後に環境を読み込む
  if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    log_error "nix の環境設定ファイルが見つかりません: /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    exit 1
  fi

else
  log_step "nix はインストール済みです"
  nix --version
fi

