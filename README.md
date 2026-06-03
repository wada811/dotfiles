# [wada811's dotfiles](http://wada811.blogspot.com/2014/05/dotfiles.html)

開発者向け Mac のセットアップと dotfiles 管理。

## クイックスタート（新しい Mac）

素の Mac で、次の 1 行を実行するだけでセットアップが完結します。
`bootstrap.sh` が Homebrew（Xcode CLT / git も同時導入）を入れ、このリポジトリを
HTTPS で clone し、`setup-mac.sh` を実行します。

```sh
curl -fsSL https://raw.githubusercontent.com/wada811/dotfiles/master/bootstrap.sh | bash
```

## 構成

| ファイル | 役割 |
|----------|------|
| `bootstrap.sh` | **入口**。素の Mac で動く前提。Homebrew 導入 → HTTPS clone → `setup-mac.sh` 実行 |
| `setup-mac.sh` | **本体（冪等）**。Brewfile 適用・macOS 設定・Git 設定・dotfiles の symlink・SSH/セキュリティ確認 |
| `Brewfile` | 導入する CLI / アプリの定義（`brew bundle` で一括導入） |
| `mac-setup-requirements.md` | セットアップの要件定義書 |
| `bin/` | 自作スクリプト（`git-pull-all` など） |

## 2 回目以降 / 部分的な再実行

環境は既に整っているので、本体だけを再実行できます（冪等）。

```sh
cd ~/dotfiles
./setup-mac.sh
```

- Brewfile を更新したらアプリ/CLI の追加導入: `brew bundle --file=~/dotfiles/Brewfile`
- dotfiles の symlink は `setup-mac.sh` 内で冪等に張り直される

## オプション

- **Rosetta 2**（原則不要。amd64 専用 Docker イメージ等が必要な場合のみ）:
  `INSTALL_ROSETTA=1 ./setup-mac.sh`
- **SSH へ切り替え**（鍵を GitHub に登録後）:
  `git -C ~/dotfiles remote set-url origin git@github.com:wada811/dotfiles.git`

## 補足

- ターミナルは [cmux](https://github.com/manaflow-ai/cmux)（Ghostty ベース）を採用。
- パッケージの追加は `Brewfile` への追記で管理する（旧 `bin/brew-update` は廃止）。
- Ruby/Node/Python などの言語ランタイムは `mise` で管理する。

## 参考

- 隠しファイル表示: `defaults write com.apple.finder AppleShowAllFiles -boolean true && killall Finder`
- diff-highlight の symlink: `ln -s /opt/homebrew/opt/git/share/git-common/contrib/diff-highlight/diff-highlight /usr/local/bin`
