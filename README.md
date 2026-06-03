# [wada811's dotfiles](http://wada811.blogspot.com/2014/05/dotfiles.html)

開発者向け Mac のセットアップと dotfiles 管理。

## クイックスタート（新しい Mac）

素の Mac で、次を実行するだけでセットアップが完結します。
`bootstrap.sh` が Homebrew（Xcode CLT / git も同時導入）を入れ、このリポジトリを
HTTPS で clone し、`setup-mac.sh` を実行します。

```sh
curl -fsSL https://raw.githubusercontent.com/wada811/dotfiles/master/bootstrap.sh -o ~/bootstrap.sh && bash ~/bootstrap.sh
```

> 注: `curl ... | bash` のようにパイプで渡すと標準入力が TTY でなくなり、
> Homebrew がパスワード入力を受け付けられない。必ず上のように
> 一度ファイルに保存してから実行する。

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
bash setup-mac.sh
```

- Brewfile を更新したらアプリ/CLI の追加導入: `brew bundle --file=~/dotfiles/Brewfile`
- dotfiles の symlink は `setup-mac.sh` 内で冪等に張り直される

## オプション

- **Rosetta 2**（原則不要。amd64 専用 Docker イメージ等が必要な場合のみ）:
  `INSTALL_ROSETTA=1 bash setup-mac.sh`
- **SSH へ切り替え**（鍵を GitHub に登録後）:
  `git -C ~/dotfiles remote set-url origin git@github.com:wada811/dotfiles.git`
