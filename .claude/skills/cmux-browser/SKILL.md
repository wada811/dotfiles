---
name: cmux-browser
description: |
  cmux のブラウザ自動化コマンドを使って Web ページを操作する。
  Use when you need to open a browser, navigate to a URL, interact with page elements,
  take screenshots, fill forms, or inspect page content from the terminal.
  Use when the user says "ブラウザで開いて", "スクリーンショットを撮って",
  "フォームを操作して", "ページの内容を確認して", or similar browser tasks.
  Do NOT use for tasks that don't require a browser surface (use WebFetch instead
  for simple page content retrieval).
argument-hint: "[URL or task description]"
---

# cmux-browser

cmux のブラウザ自動化コマンドで Web ページを操作するスキル。

## 前提

- cmux が起動していること（`cmux ping` で確認）
- ブラウザサーフェスが存在するか、新規作成できること

## 手順

### 1. ブラウザサーフェスを確認・準備

```bash
# 現在のサーフェス一覧を確認
cmux list-surfaces --json

# ブラウザサーフェスがなければ新規作成
cmux browser open <url>          # 新規ウィンドウで開く
cmux browser open-split <url>    # ターミナル横に分割表示（推奨）

# すでにブラウザサーフェスがある場合はそのまま使う
# サーフェス ID を確認して後続コマンドで使用
cmux browser identify
```

### 2. ナビゲーション

```bash
cmux browser surface:N navigate <url> [--snapshot-after]
cmux browser surface:N reload
cmux browser surface:N url    # 現在の URL を確認
```

### 3. ページの準備完了を待つ

操作前に必ずロード完了を確認する。

```bash
# 標準的なページロード待機
cmux browser surface:N wait --load-state complete --timeout-ms 15000

# SPA など動的コンテンツの場合
cmux browser surface:N wait --selector "#main-content" --timeout-ms 10000
cmux browser surface:N wait --function "window.__appReady === true"
cmux browser surface:N wait --text "読み込み完了"
```

### 4. ページ構造の把握

操作前に snapshot でページ構造を確認する（AI が要素を特定するのに最適）。

```bash
cmux browser surface:N snapshot --interactive --compact
cmux browser surface:N snapshot --selector "main" --max-depth 5
```

### 5. 要素の操作

```bash
# クリック
cmux browser surface:N click "<selector>" [--snapshot-after]

# テキスト入力（fill はフィールドをクリアしてからセット）
cmux browser surface:N fill "<selector>" --text "<text>"
cmux browser surface:N type "<selector>" "<text>"   # 追記

# キー送信
cmux browser surface:N press Enter

# セレクトボックス
cmux browser surface:N select "<selector>" "<value>"

# チェックボックス
cmux browser surface:N check "<selector>"
cmux browser surface:N uncheck "<selector>"

# スクロール
cmux browser surface:N scroll --dy 800
cmux browser surface:N scroll-into-view "<selector>"
```

### 6. 結果の確認・検査

```bash
# スクリーンショット
cmux browser surface:N screenshot --out tmp/screenshot.png

# 要素の状態・値を取得
cmux browser surface:N get text "<selector>"
cmux browser surface:N get value "<selector>"
cmux browser surface:N get title
cmux browser surface:N is visible "<selector>"
cmux browser surface:N is enabled "<selector>"

# 要素を見つける（セレクタが不明な場合）
cmux browser surface:N find text "ログイン"
cmux browser surface:N find role button --name "送信"
cmux browser surface:N find label "メールアドレス"
```

### 7. デバッグ（問題が起きた場合）

```bash
# コンソールエラーを確認
cmux browser surface:N errors list
cmux browser surface:N console list

# ハイライトで要素を視覚確認
cmux browser surface:N highlight "<selector>"

# JS を直接実行
cmux browser surface:N eval "document.title"
```

## よくあるパターン

### フォーム送信

```bash
cmux browser surface:N fill "#email" --text "user@example.com"
cmux browser surface:N fill "#password" --text "password"
cmux browser surface:N click "button[type='submit']" --snapshot-after
cmux browser surface:N wait --text "ログイン成功"
```

### スクレイピング

```bash
cmux browser surface:N navigate https://example.com --snapshot-after
cmux browser surface:N wait --load-state complete
cmux browser surface:N get text ".article-body"
cmux browser surface:N screenshot --out tmp/page.png
```

### セッションの保存・再利用

```bash
# 認証後に状態を保存
cmux browser surface:N state save tmp/browser-state.json

# 次回以降は状態をロードして認証をスキップ
cmux browser surface:N state load tmp/browser-state.json
```

## 注意事項

- `--snapshot-after` を付けると操作後に自動でスナップショットを取得する
- iframe 内を操作する場合は `frame` コマンドで先にコンテキストを切り替える
- ダイアログが出る可能性がある操作の前後は `dialog accept/dismiss` を準備する
