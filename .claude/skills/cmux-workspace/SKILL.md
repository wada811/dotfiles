---
name: cmux-workspace
description: |
  cmux のワークスペース・サーフェスを管理する。
  Use when you need to create, list, rename, close, or send commands to cmux workspaces or surfaces.
  Use when you want to check what workspaces are running, open a new workspace for a task,
  send input to a specific workspace, or read a workspace's terminal output.
  Use when the user says "ワークスペースを作って", "cmux で新しいタブを開いて",
  "このワークスペースにコマンドを送って", "ターミナルの出力を確認して", or similar.
  Do NOT use for starting the full working agent system — use agents-start instead.
argument-hint: "[workspace name or task]"
---

# cmux-workspace

cmux のワークスペース・サーフェスを作成・操作するスキル。

## 前提確認

```bash
cmux ping    # PONG が返れば接続OK。失敗したら cmux アプリが起動していない
```

## 現状把握

```bash
cmux list-workspaces [--json]
# 出力例:
# * workspace:1  Main Agent  [selected]
#   workspace:2  🕐 Schedule
#   workspace:4  🔨 Dev

cmux identify [--json]    # 現在のサーフェス/ワークスペース ID を確認
cmux sidebar-state        # cwd・gitブランチ・ポート・ステータス・ログをダンプ
```

## ワークスペース操作

### 作成

```bash
cmux new-workspace
# → "OK workspace:N" を返す。"OK " プレフィックスを除いて workspace:N を取得する

# 作成後、名前を付けてコマンドを起動する
cmux rename-workspace --workspace workspace:N "🔨 Dev"
cmux send --workspace workspace:N "cd ~/path && some-command"
cmux send-key --workspace workspace:N enter
```

> **戻り値の注意**: `new-workspace` は `"OK workspace:4"` を返す。
> `workspace:4` として使うには `"OK "` を除去する。

### 既存チェック → なければ作成

重複作成を防ぐために、名前で既存ワークスペースを確認してから作成する:

```bash
# 既存確認
cmux list-workspaces | grep "Dev"

# なければ作成
cmux new-workspace
```

### 選択・削除

```bash
cmux select-workspace --workspace workspace:N    # フォーカス切り替え
cmux current-workspace                           # 現在のワークスペースを確認
cmux close-workspace --workspace workspace:N     # 削除
```

## コマンド送受信

```bash
# テキスト送信
cmux send --workspace workspace:N "npm test"
cmux send-key --workspace workspace:N enter

# 特定サーフェスへ送信
cmux send-surface --surface surface:N "text"
cmux send-key-surface --surface surface:N enter

# 出力を読み取る
cmux read-screen --workspace workspace:N --lines 100
```

> **surface: への直接 send は不可**（"Surface is not a terminal" エラー）。
> surface に送る場合は `move-surface --focus true` → `send --workspace` の順で行う:
> ```bash
> cmux move-surface --surface surface:N --focus true --workspace workspace:N
> cmux send --workspace workspace:N "command"
> cmux send-key --workspace workspace:N enter
> ```

## サーフェス（ペイン内タブ）操作

```bash
# ワークスペース内に新しいタブを作成
cmux new-surface --workspace workspace:N
# → "OK surface:N pane:N workspace:N" を返す

# タブ名変更
cmux rename-tab --workspace workspace:N --surface surface:N "タブ名"

# 全サーフェス一覧
cmux list-surfaces [--json]

# フォーカス
cmux focus-surface --surface surface:N
```

## ペイン分割

```bash
cmux new-split right    # 右に分割
cmux new-split down     # 下に分割
cmux new-split left
cmux new-split up
```

## サイドバーメタデータ（状態表示）

```bash
# ステータスピル（アイコン・色付き）
cmux set-status "key" "Dev: 稼働中" --icon "🔨" --color "#00ff00" --workspace workspace:N
cmux clear-status "key"
cmux list-status

# プログレスバー
cmux set-progress 0.5 --label "処理中..." --workspace workspace:N
cmux clear-progress

# ログ（level: info, progress, success, warning, error）
cmux log --level success --source "Main" "タスク完了"
cmux list-log [--limit 10]
cmux clear-log
```

## よくあるパターン

### 新規ワークスペースを作ってコマンドを起動

```bash
cmux new-workspace
# → OK workspace:5
cmux rename-workspace --workspace workspace:5 "📊 Analysis"
cmux send --workspace workspace:5 "cd ~/Documents/work && python3 analyze.py"
cmux send-key --workspace workspace:5 enter
```

### 起動済みワークスペースにタスクを送る

```bash
cmux list-workspaces
# → 対象の workspace:N を確認
cmux send --workspace workspace:4 "/next-action"
cmux send-key --workspace workspace:4 enter
```

### 出力を確認して次のアクションを決める

```bash
cmux read-screen --workspace workspace:4 --lines 50
# 出力を見てエラーの有無・完了状態を判断
```
