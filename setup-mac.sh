#!/usr/bin/env bash
#
# setup-mac.sh - 開発者向け Mac セットアップ自動化スクリプト
#
# 使い方:
#   chmod +x setup-mac.sh
#   ./setup-mac.sh
#
# 特徴:
#   - 冪等性: 再実行しても安全（導入済みはスキップ）
#   - Apple Silicon / Intel 両対応
#   - 同じディレクトリの Brewfile を読み込んでアプリを一括導入
#
set -euo pipefail

# ---- ログ用ヘルパー ----
info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ OK ]\033[0m  %s\n" "$1"; }
warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="${SCRIPT_DIR}/Brewfile"

# ---- 0. 前提チェック ----
if [[ "$(uname)" != "Darwin" ]]; then
  warn "macOS 以外で実行されています。中止します。"
  exit 1
fi

# ---- 1. Xcode Command Line Tools ----
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode Command Line Tools: 導入済み"
else
  info "Xcode Command Line Tools をインストールします..."
  xcode-select --install || true
  warn "インストールダイアログが表示されたら完了後に本スクリプトを再実行してください。"
  exit 0
fi

# ---- 1.5 Rosetta 2 (任意 / amd64 Docker イメージ等が必要な場合のみ) ----
# 2026 年時点ではほぼ不要。amd64 専用の Docker イメージや一部の Intel バイナリを
# 使う場合のみ導入。INSTALL_ROSETTA=1 を指定したときだけ実行する。
if [[ "${INSTALL_ROSETTA:-0}" == "1" && "$(uname -m)" == "arm64" ]]; then
  if /usr/bin/pgrep -q oahd 2>/dev/null; then
    ok "Rosetta 2: 導入済み"
  else
    info "Rosetta 2 をインストールします..."
    sudo softwareupdate --install-rosetta --agree-to-license || warn "Rosetta の導入をスキップ"
  fi
else
  ok "Rosetta 2: スキップ (必要なら INSTALL_ROSETTA=1 ./setup-mac.sh)"
fi

# ---- 2. Homebrew ----
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew: 導入済み"
else
  info "Homebrew をインストールします..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Homebrew の PATH を現在のシェルとプロファイルに反映
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX="/opt/homebrew"     # Apple Silicon
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX="/usr/local"        # Intel
fi

if [[ -n "${BREW_PREFIX:-}" ]]; then
  eval "$(${BREW_PREFIX}/bin/brew shellenv)"
  ZPROFILE="${HOME}/.zprofile"
  SHELLENV_LINE="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
  if ! grep -qsF "${SHELLENV_LINE}" "${ZPROFILE}" 2>/dev/null; then
    echo "${SHELLENV_LINE}" >> "${ZPROFILE}"
    ok ".zprofile に Homebrew の PATH を追記"
  fi
fi

info "Homebrew を更新中..."
brew update

# ---- 3. Brewfile を適用 ----
if [[ -f "${BREWFILE}" ]]; then
  info "Brewfile を適用します: ${BREWFILE}"
  brew bundle --file="${BREWFILE}"
  ok "Brewfile の適用が完了"
else
  warn "Brewfile が見つかりません (${BREWFILE})。アプリ導入をスキップします。"
fi

# ---- 4. macOS システム環境設定 (defaults) ----
info "macOS のシステム設定を適用します..."

# キーリピートを高速化
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Finder: 全拡張子を表示 / 隠しファイルを表示 / パスバー表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true

# スクリーンショット: 保存先と形式
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"

# Dock: 自動的に隠す
defaults write com.apple.dock autohide -bool true

# トラックパッド: タップでクリック
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

killall Finder >/dev/null 2>&1 || true
killall Dock   >/dev/null 2>&1 || true
ok "システム設定を適用（一部は再ログイン後に反映）"

# ---- 5. Git の基本設定 ----
if command -v git >/dev/null 2>&1; then
  # 未設定の場合のみ案内（自動上書きはしない）
  if [[ -z "$(git config --global user.name || true)" ]]; then
    warn "Git の user.name が未設定です。次を実行してください:"
    echo '    git config --global user.name  "Your Name"'
    echo '    git config --global user.email "you@example.com"'
  fi
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  ok "Git のデフォルト設定を適用"
fi

# ---- 5.5 dotfiles の symlink (install.sh) ----
# 本スクリプトが dotfiles リポジトリ内にある場合（bootstrap 経由の通常ケース）は、
# 同梱の install.sh を実行して設定ファイルをホームへ symlink する。
# リポジトリ外から単体実行された場合のみ DOTFILES_REPO を clone する。
if [[ -x "${SCRIPT_DIR}/install.sh" ]]; then
  info "install.sh で dotfiles を symlink します..."
  ( cd "${SCRIPT_DIR}" && ./install.sh ) || warn "install.sh で一部失敗（既存 symlink の可能性。問題なければ無視可）"
else
  DOTFILES_REPO="${DOTFILES_REPO:-}"   # 例: export DOTFILES_REPO=git@github.com:wada811/dotfiles.git
  DOTFILES_DIR="${HOME}/dotfiles"
  if [[ -n "${DOTFILES_REPO}" && ! -d "${DOTFILES_DIR}/.git" ]]; then
    info "dotfiles を clone します: ${DOTFILES_REPO}"
    git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
    [[ -x "${DOTFILES_DIR}/install.sh" ]] && ( cd "${DOTFILES_DIR}" && ./install.sh ) || true
  else
    warn "install.sh が見つかりません。dotfiles の symlink をスキップ"
  fi
fi

# ---- 6. SSH 鍵 (GitHub 用) ----
SSH_KEY="${HOME}/.ssh/id_ed25519"
if [[ -f "${SSH_KEY}" ]]; then
  ok "SSH 鍵: 既存 (${SSH_KEY})"
else
  warn "SSH 鍵が未作成です。次で作成し、公開鍵を GitHub に登録してください:"
  echo "    ssh-keygen -t ed25519 -C \"${USER}@$(hostname)\""
  echo "    pbcopy < ${SSH_KEY}.pub   # 公開鍵をクリップボードへ"
fi

# ---- 7. セキュリティ設定の確認 ----
info "セキュリティ設定を確認します..."

if fdesetup status 2>/dev/null | grep -q "On"; then
  ok "FileVault: 有効"
else
  warn "FileVault が無効です。'システム設定 > プライバシーとセキュリティ > FileVault' で有効化を推奨"
fi

# ファイアウォール (要管理者権限のため確認のみ)
FW_STATE="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true)"
if echo "${FW_STATE}" | grep -qi "enabled"; then
  ok "ファイアウォール: 有効"
else
  warn "ファイアウォールが無効の可能性。'システム設定 > ネットワーク > ファイアウォール' を確認"
fi

# ---- 完了 ----
echo
ok "セットアップが完了しました 🎉"
echo "次のステップ:"
echo "  1. 新しいターミナルを開き直す（PATH 反映のため）"
echo "  2. Git の user.name / user.email を設定"
echo "  3. SSH 鍵を作成し GitHub に登録 → ssh -T git@github.com で確認"
echo "  4. FileVault / ファイアウォールを有効化"
echo "  5. 各 GUI アプリにサインイン"
