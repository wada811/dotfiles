#!/usr/bin/env bash
#
# bootstrap.sh - 素の Mac から dotfiles を立ち上げるための入口スクリプト
#
# このファイルだけが「何も入っていない Mac」で動くことを前提に書かれています。
# dotfiles リポジトリのルートに置き、README の先頭で次のように案内します:
#
#   curl -fsSL https://raw.githubusercontent.com/wada811/dotfiles/master/bootstrap.sh | bash
#
# やること (ブートストラップ問題の解決):
#   1. Homebrew を導入 (Xcode CLT / git は依存として一緒に入る)
#   2. dotfiles を HTTPS で clone (SSH 鍵がまだ無くても clone できる)
#   3. リポジトリ内の setup-mac.sh を実行 (本体のセットアップはここに集約)
#   4. (任意) clone 後に remote を SSH へ張り替え
#
set -euo pipefail

# ---- 設定 (自分のリポジトリに合わせて変更) ----
DOTFILES_HTTPS="https://github.com/wada811/dotfiles.git"
DOTFILES_SSH="git@github.com:wada811/dotfiles.git"
DOTFILES_DIR="${HOME}/dotfiles"

info() { printf "\033[1;34m[bootstrap]\033[0m %s\n" "$1"; }

# ---- 0. macOS チェック ----
[[ "$(uname)" == "Darwin" ]] || { echo "macOS 専用です"; exit 1; }

# ---- 1. Homebrew (CLT / git をまとめて導入) ----
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew をインストールします (Xcode CLT / git も同時に導入されます)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 現在のシェルに PATH を反映
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"       # Intel
fi

# 念のため git を確認 (CLT 未導入なら誘導)
if ! command -v git >/dev/null 2>&1; then
  info "git が見つかりません。Xcode Command Line Tools を導入します..."
  xcode-select --install || true
  echo "CLT のインストール完了後、もう一度このスクリプトを実行してください。"
  exit 0
fi

# ---- 2. dotfiles を HTTPS で clone (SSH 鍵不要) ----
if [[ -d "${DOTFILES_DIR}/.git" ]]; then
  info "dotfiles は既に存在します: ${DOTFILES_DIR}"
else
  info "dotfiles を HTTPS で clone します..."
  git clone "${DOTFILES_HTTPS}" "${DOTFILES_DIR}"
fi

# ---- 3. 本体セットアップを実行 ----
# 実行ビットに依存しないよう bash で起動する（GitHub 上のファイルは 644 のことがある）。
if [[ -f "${DOTFILES_DIR}/setup-mac.sh" ]]; then
  info "setup-mac.sh を実行します..."
  ( cd "${DOTFILES_DIR}" && bash setup-mac.sh )
else
  info "setup-mac.sh が見つかりません。手動で確認してください: ${DOTFILES_DIR}"
fi

# ---- 4. (任意) SSH 鍵を登録済みなら remote を SSH へ張り替え ----
# GitHub に SSH 鍵を登録した後、次を実行すると以降は SSH で push/pull できます:
#   git -C "${DOTFILES_DIR}" remote set-url origin "${DOTFILES_SSH}"

info "完了。新しいターミナルを開き直してください。"
