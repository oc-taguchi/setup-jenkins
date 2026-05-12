FROM amazonlinux:2023

ARG HOME_DIR="/root"

# nixのインストールに必要な shadow-utils をインストール
# groupadd コマンドが必要なため
RUN dnf upgrade && dnf install -y shadow-utils

# root で nix をインストール（trusted-users に一般ユーザーを追加）
RUN curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --enable-flakes \
  --init none \
  --no-confirm
