# setup-jenkins

Amazon Linux 2023 上に Nix + Home Manager を使って Jenkins 環境を構築するためのセットアップリポジトリです。

ローカルでの動作確認は Docker コンテナで行い、本番環境は EC2 へデプロイします。

## 構成

```
.
├── Dockerfile              # ローカル確認用コンテナイメージ
├── docker-compose.yaml     # ローカル確認用コンテナ定義
├── cloud-init.yaml         # EC2 デプロイ用 cloud-init 設定
├── nix/
│   ├── flake.nix           # Nix Flake 定義（ec2-user / root）
│   ├── dotfiles/           # 設定ファイル（nginx.conf 等）
│   └── home-manager/
│       └── main.nix        # Home Manager 設定
└── scripts/
    ├── _functions          # 共通関数
    ├── install-nix.sh      # Nix インストールスクリプト
    ├── run-home-manager.sh # Home Manager 実行スクリプト
    └── jenkins.sh          # Jenkins・nginx 起動スクリプト（コンテナ用）
```

## インストールされるパッケージ

Home Manager によって以下がインストールされます。

| パッケージ | 用途 |
|---|---|
| Jenkins | CI サーバー |
| Amazon Corretto 25 | Jenkins 実行用 JDK |
| nginx | Jenkins へのリバースプロキシ |
| git / git-lfs / gh | バージョン管理 |
| curl / wget / jq | ユーティリティ |

## ローカルでの動作確認

Docker が必要です。

```sh
# イメージをビルドしてコンテナを起動
docker compose up -d

# コンテナに入る
docker compose exec jenkins-al2023 bash -l

# Home Manager を適用する
./scripts/run-home-manager.sh

# Jenkins・nginx を起動する
./scripts/jenkins.sh
```

Jenkins には http://localhost:8080 でアクセスできます。

## EC2 へのデプロイ

### 事前準備

- EBS ボリューム（`/dev/xvdb`）を EC2 インスタンスにアタッチする
- User Data に `cloud-init.yaml` を渡す

### cloud-init でセットアップされる内容

| 設定 | 内容 |
|---|---|
| ディスク | `/dev/xvdb` に GPT パーティションを作成 |
| ファイルシステム | XFS でフォーマット |
| マウント | `/mnt/jenkins` にマウント（再起動後も維持） |
| カーネルパラメータ | `net.ipv4.ip_unprivileged_port_start = 80`（80番ポートを非rootで使用可能に） |
| タイムゾーン | Asia/Tokyo |
| ロケール | ja_JP.utf8 |

### AWS CLI でのインスタンス起動例

```sh
aws ec2 run-instances \
  --image-id ami-xxxxxxxx \
  --instance-type t3.medium \
  --user-data file://cloud-init.yaml \
  --block-device-mappings '[{"DeviceName":"/dev/xvdb","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]'
```

### EC2 上でのセットアップ

```sh
# Nix のインストール
./scripts/install-nix.sh

# Home Manager の適用
./scripts/run-home-manager.sh
```

## スクリプトのオプション

### `run-home-manager.sh`

| オプション | 値 | 説明 |
|---|---|---|
| `--debug` | `true` / `false` | デバッグ出力と `--show-trace` を有効化 |
| `--dry-run` | `true` / `false` | home-manager switch を実行せずに確認のみ |

```sh
./scripts/run-home-manager.sh --debug true --dry-run true
```

### `install-nix.sh`

| オプション | 値 | 説明 |
|---|---|---|
| `--debug` | `true` / `false` | デバッグ出力を有効化 |

## Nix Flake の設定

`nix/flake.nix` には以下のホーム設定が定義されています。

| 設定名 | 対象ユーザー | 用途 |
|---|---|---|
| `ec2-user` | ec2-user | EC2 本番環境 |
| `root` | root | ローカルコンテナ確認用 |
