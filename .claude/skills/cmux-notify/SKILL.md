---
name: cmux-notify
description: |
  cmux の通知機能を使ってユーザーにデスクトップ通知を送る。
  Use when you have just finished a long-running or significant task and want to
  let the user know it's complete — especially when they may have stepped away.
  Use when you think it would help to alert the user proactively, such as after
  completing a build, deployment, long analysis, or any task that takes more than
  a few minutes.
  Do NOT use for every task completion — reserve for tasks where the user
  is likely waiting and would benefit from a notification.
argument-hint: "[title] [body]"
---

# cmux-notify

タスク完了時などにデスクトップ通知を送るスキル。

## 基本

```bash
cmux notify --title "<title>" --body "<body>"
cmux notify --title "<title>" --subtitle "<subtitle>" --body "<body>"
```

cmux 外（通常ターミナルや CI）では失敗するため、常にフォールバックを付ける:

```bash
cmux notify --title "<title>" --body "<body>" 2>/dev/null || true
```

## 通知の抑制条件

以下の場合はデスクトップ通知が表示されない（通知パネルには残る）:
- cmux ウィンドウがフォーカスを持っている
- 送信元ワークスペースがアクティブ
- 通知パネルが開いている

## タイトル・本文の書き方

- **title**: タスク名・完了ステータスを端的に（例: "ビルド完了", "PR 作成済み"）
- **subtitle**: 省略可。補足情報（例: リポジトリ名）
- **body**: 結果の要点（例: "テスト全件パス・PR #123 を作成しました"）

## 使用例

```bash
# ビルド完了
cmux notify --title "ビルド完了" --body "全テストパス。PR #123 を作成しました。" 2>/dev/null || true

# エラー発生
cmux notify --title "エラー発生" --subtitle "CI" --body "test_login が失敗。ログを確認してください。" 2>/dev/null || true

# 長時間処理の完了
cmux notify --title "分析完了" --body "レポートを tmp/report.md に出力しました。" 2>/dev/null || true
```

## OSC シーケンス（スクリプトから送信する場合）

```bash
# OSC 777（シンプル）
printf '\033]777;notify;Title;Body\033\\'

# OSC 99（リッチ：サブタイトル・ID 付き）
printf '\033]99;title=Title;subtitle=Subtitle;id=unique-id\033\\'
```
