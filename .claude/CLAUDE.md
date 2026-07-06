# ユーザー共通の作業規約（全マシン・全プロジェクト）

マシン固有の環境情報は下記 import で読み込む（git 管理外・マシンごとに内容が異なる。
存在しないマシンでは setup-mac.sh が空ファイルを作る）:

@~/.claude/machine.md

## Bash コマンド規約

- **hook が自動ブロックする項目**（違反すると deny＋代替手段が返る。`~/.claude/hooks/pre-tool-use-bash.sh`）:
  `sed -i`（→ Edit ツール）・`git -C`（→ cd してから git）・`git filter-branch`（→ git-filter-repo）
- **`echo` コマンド禁止**: 出力のみが目的の `echo` は使わない。テキスト出力は Claude が直接回答する
- **`python3 -c` / インラインスクリプト禁止**: JSON 処理などは `jq` を使う（例外: スキル定義に同梱されたコマンドはスキルに従う）
- **`&&` による複数コマンド連結を避ける**: 各コマンドは個別の Bash tool call で実行する。目的は permission allowlist との一致（対話セッションでの承認プロンプト削減）であり、auto/bypass 運用の自動エージェントでは非強制
- **`gh` コマンドで `jq` にパイプしない**: `| jq` や `2>/dev/null` を含む複合コマンドは permission check が通らない。代わりに `gh ... --json ... --jq 'filter'` の形式を使う
- **`for` ループより個別 Bash call を優先**: 複数要素の並列処理は subagent（Agent tool）で行う
- **`rm` 禁止・`trash` を使う**: ファイル削除は `rm` ではなく `trash` コマンドを使う（Brewfile で全マシンに導入済み）
- **`npx` 不在時は `mise exec -- npx` にフォールバック**: mise 経由のコマンドは非インタラクティブシェルでは PATH が通らないため

## コミットメッセージ

- **タイトルは 50 文字以内**: 51 文字以上になる場合は動詞・修飾語を削って短縮する（例: 「Add support for...」→「Support...」）
- **本文は 72 文字折り返し**: 説明が必要な場合は空行を挟んで本文に書く
