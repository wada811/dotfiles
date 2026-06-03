# Mac セットアップ 要件定義書（開発者向け）

| 項目 | 内容 |
|------|------|
| 作成者 | wada811 |
| 対象 | 開発者向け Mac（個人利用・1 台） |
| 作成日 | 2026-06-03 |
| バージョン | 1.1 |

> このドキュメントは Mac を開発機としてセットアップする際の要件を定義するものです。`/` で区切られた箇所や `TODO` は環境に合わせて調整してください。

---

## 1. 目的

新規／初期化済みの Mac を、開発作業をすぐに始められる状態に短時間で・再現性をもってセットアップする。具体的には次を満たす。

- 手作業を最小化し、コマンド一発で大部分を構築できること
- 構成がコード化（Brewfile / dotfiles）され、再構築や別マシンへの展開が容易であること
- セキュリティの初期設定（FileVault・ファイアウォール等）が漏れなく行われること

## 2. 対象範囲

| 区分 | 含む | 含まない |
|------|------|----------|
| 範囲 | 個人用 Mac 1 台の開発環境構築 | チーム標準化・MDM 配布 |
| OS | macOS（Apple Silicon 想定） | Intel Mac 固有手順 |
| 領域 | システム設定・CLI・言語ランタイム・GUI アプリ・dotfiles | 業務アプリの個別アカウント設定 |

## 3. 前提条件

- macOS は最新の安定版にアップデート済み（`システム設定 > 一般 > ソフトウェアアップデート`）
- Apple ID でサインイン済み
- 管理者権限を持つユーザーであること
- ネットワークに接続されていること
- Apple Silicon（M シリーズ）を前提。Intel の場合は Homebrew のパス（`/usr/local`）が変わる

## 4. 機能要件

### 4.1 システム基盤

| ID | 要件 | 備考 |
|----|------|------|
| SYS-01 | Xcode Command Line Tools の導入 | `xcode-select --install` |
| SYS-02 | Homebrew（パッケージマネージャ）の導入 | 以降のインストールの基盤 |
| SYS-03 | Rosetta 2 の導入（任意・原則不要） | 2026 年時点ではほぼ不要。amd64 専用 Docker イメージや一部 Intel バイナリを使う場合のみ導入 |

### 4.2 システム環境設定（defaults）

| ID | 要件 |
|----|------|
| PREF-01 | キーリピート速度を高速化 |
| PREF-02 | Finder で全拡張子・隠しファイルを表示 |
| PREF-03 | スクリーンショットの保存先・形式の指定 |
| PREF-04 | Dock の自動非表示・不要アプリの整理 |
| PREF-05 | トラックパッドのタップでクリックを有効化 |

### 4.3 開発ツール（CLI）

| ID | ツール | 用途 |
|----|--------|------|
| CLI-01 | git | バージョン管理 |
| CLI-02 | gh | GitHub CLI |
| CLI-03 | mise（または asdf） | 言語ランタイムのバージョン管理 |
| CLI-04 | node / npm（pnpm） | JS/TS 実行環境 |
| CLI-05 | python / uv | Python 実行環境 |
| CLI-06 | jq, ripgrep, fd, bat, fzf, tree | 日常的な CLI ユーティリティ |
| CLI-07 | docker（colima/OrbStack） | コンテナ実行環境 |
| CLI-08 | zsh + starship / oh-my-zsh | シェル環境 |

> TimeTree のような iOS/Android アプリ開発を行う場合は、Xcode（App Store）、CocoaPods、fastlane、Android Studio、JDK なども追加候補。

### 4.4 GUI アプリ（Homebrew Cask）

| 区分 | アプリ例 |
|------|----------|
| エディタ/IDE | Visual Studio Code, Cursor |
| ターミナル | cmux（Ghostty ベース・AI コーディングエージェント向け） |
| ブラウザ | Google Chrome, Firefox |
| 通信 | Slack, Zoom |
| 生産性 | Notion, Raycast, Rectangle（ウィンドウ管理） |
| 開発補助 | Docker Desktop / OrbStack, TablePlus, Postman |

### 4.5 dotfiles / シェル設定

wada811/dotfiles のように、設定ファイルを 1 つのリポジトリ（`~/dotfiles`）で管理し、`install.sh` でホームへシンボリックリンクを張る方式を採用する。

| ID | 要件 |
|----|------|
| DOT-01 | `~/dotfiles` リポジトリで設定を一元管理（`.gitconfig` / `.zshrc` / `.zprofile` / `.zshenv` / `.vimrc` / iTerm2 plist / `bin/`） |
| DOT-02 | `install.sh` でホームディレクトリへシンボリックリンクを作成 |
| DOT-03 | SSH 鍵の生成と GitHub への登録 |
| DOT-04 | Git のユーザー名・メール・デフォルトブランチ設定 |
| DOT-05 | `bin/` の自作スクリプト（例: `brew-update`、`git-pull-all`）に PATH を通す |
| DOT-06 | diff-highlight のシンボリックリンク（Git の差分を見やすく） |

## 5. 非機能要件

| 区分 | 要件 |
|------|------|
| 再現性 | Brewfile / スクリプトにより同一構成を再構築可能 |
| 冪等性 | スクリプトを再実行しても安全（重複インストールを避ける） |
| 所要時間 | ネットワーク良好時、初回 60 分以内を目標 |
| 可搬性 | 別マシンへ同手順で展開可能 |
| 保守性 | 追加ツールは Brewfile への追記のみで対応可能 |

## 6. セキュリティ要件

| ID | 要件 |
|----|------|
| SEC-01 | FileVault（ディスク暗号化）を有効化 |
| SEC-02 | ファイアウォールを有効化 |
| SEC-03 | 画面ロック（スリープ後にパスワード要求）を有効化 |
| SEC-04 | SSH 鍵はパスフレーズ付きで生成 |
| SEC-05 | 認証情報は 1Password 等のパスワードマネージャで管理 |
| SEC-06 | OS・アプリの自動アップデートを有効化 |

## 7. セットアップ手順（概要）

ブートストラップ問題（dotfiles を clone するにも前提のセットアップが要る）を避けるため、素の Mac で唯一動く `bootstrap.sh` を入口とし、本体は dotfiles リポジトリ内の `setup-mac.sh` に集約する。

1. macOS を最新版にアップデート
2. 入口スクリプトを実行（curl で取得して実行）:
   `curl -fsSL https://raw.githubusercontent.com/wada811/dotfiles/master/bootstrap.sh | bash`
   - `bootstrap.sh` が Homebrew（→ Xcode CLT / git も同時導入）を入れ、dotfiles を **HTTPS** で clone（SSH 鍵不要）し、`setup-mac.sh` を実行
3. `setup-mac.sh` が Brewfile 適用・defaults 適用・Git 設定・セキュリティ確認を実施
4. SSH 鍵を生成し GitHub に登録 → 以降 remote を SSH に張り替え
5. セキュリティ設定（FileVault・ファイアウォール）を確認
6. 各 GUI アプリにサインイン

> 詳細な自動化は同梱の `bootstrap.sh` / `setup-mac.sh` / `Brewfile` を参照。

### 7.1 ブートストラップ問題の解決方針

| 課題 | 解決 |
|------|------|
| dotfiles を clone するのに git が要る | `bootstrap.sh` を `curl` で取得（macOS 標準の curl で可能） |
| git を入れるのに CLT/Homebrew が要る | Homebrew のインストールが CLT を依存として導入 |
| 初回 clone に SSH 鍵が要る | 最初は **HTTPS** で clone し、鍵登録後に remote を SSH へ変更 |
| スクリプト本体を dotfiles で管理したい | 入口（`bootstrap.sh`）だけ外出し、本体はリポジトリ内に集約 |

## 8. 受け入れ基準（チェックリスト）

- [ ] `brew doctor` が警告なく完了する
- [ ] `git`, `gh`, `node`, `python`, `docker` が実行可能
- [ ] VS Code / ターミナル / ブラウザが起動する
- [ ] `ssh -T git@github.com` で認証成功
- [ ] FileVault・ファイアウォールが有効
- [ ] 再起動後もシェル設定・PATH が維持される

## 9. リスクと留意点

- Apple Silicon と Intel で Homebrew のインストール先が異なる
- 一部 Cask は手動でセキュリティ許可（`システム設定 > プライバシーとセキュリティ`）が必要
- 企業ポリシー（MDM・VPN）がある場合は IT 部門の指示を優先
- `defaults` の設定変更はログイン／再起動後に反映されるものがある

## 10. 参考: wada811/dotfiles

本要件は既存の [wada811/dotfiles](https://github.com/wada811/dotfiles) のセットアップ手順を参考にしている。同リポジトリから取り込んだ要点は次のとおり。

- **dotfiles の symlink 管理**: `git clone` 後に `install.sh` で `~/.gitconfig`・`~/.zshrc`・`~/.zprofile`・`~/.zshenv`・`~/.vimrc`・iTerm2 plist・`~/bin` をシンボリックリンク。
- **Homebrew 一括導入**: `bin/brew-update` でパッケージとアプリをまとめて導入（本要件では `Brewfile` 化）。
- **採用パッケージ**: zsh / zsh-completions / peco / terminal-notifier / git / hub / gh / direnv / rbenv + ruby-build / sqlite / jq / tree / rename / imagemagick / ffmpeg。
- **採用アプリ**: VS Code / CotEditor / Slack / 1Password (+CLI) / The Unarchiver / AppCleaner / ImageOptim / Cyberduck / Google 日本語入力 / Dropbox / Google Drive。（wada811 は iTerm2 を採用しているが、本要件ではターミナルを cmux に変更）
- **モバイル開発系**: dex2jar / jd-gui / adb 補助スクリプト（Android 開発者構成）。
- **その他の初期手順**: 隠しファイル表示、diff-highlight の symlink。（wada811 は Rosetta 導入も行っているが、2026 年時点では原則不要のため本要件では任意扱い）

> 上記のうち汎用的に有用なものを `Brewfile` と `setup-mac.sh` に反映済み。モバイル開発・日本語入力など個別ニーズの項目はコメントアウトで同梱しているため、必要に応じて有効化する。

---

*この要件定義に基づく自動化スクリプトは `setup-mac.sh` / `Brewfile` を参照してください。*
