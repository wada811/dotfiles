---
name: handover
effort: medium
description: |
  現在のセッションの作業内容を次のセッションへ引き継ぐための引き継ぎドキュメントを生成する。
  Use when the user asks to summarize the session for handover, says "引き継ぎ",
  "次のセッションに渡して", "context をまとめて", or when a session is ending and
  you think it would help to create a handover document for continuity.
  Also use when you are about to run out of context and want to preserve progress.
argument-hint: "[output-path] (デフォルト: worklog/YYYY/MM/DD/handover.md、worklog/ が無いプロジェクトは tmp/handover.md)"
---

# Handover Skill

セッションの作業内容を構造化して、次のセッションが即座に作業を再開できるよう引き継ぎドキュメントを生成する。

## 出力フォーマット

以下のフォーマットで `worklog/YYYY/MM/DD/handover.md` に保存する（日付は今日の日付）。

```markdown
# セッション引き継ぎ YYYY-MM-DD HH:MM

## 主要な目的・ゴール
<!-- このセッションで何を達成しようとしていたか -->

## 完了した作業
<!-- 箇条書きで具体的に。コミット hash・PR 番号・ファイルパスを含める -->
- [ ] 完了事項1
- [x] 完了事項2

## 進行中の作業
<!-- 途中で止まっているもの。どこまで進んでいるかを明記 -->
- 作業名: 現在の状態
  - ファイル: パス
  - 次のステップ: 何をすべきか

## 次のセッションでやること（優先順）
1. 最優先タスク（理由）
2. 次のタスク
3. ...

## 重要なコンテキスト・注意事項
<!-- 次のセッションで知っておくべきこと -->
- worktree: repos/<repo>--<branch>
- 関連 PR: #番号
- 関連 issue: #番号
- 特記事項: ...

## 参考リンク・ファイル
- Notion: URL
- 議事録: worklog/...
```

## 実行手順

1. 会話履歴から作業内容を抽出する
2. 今日の日付で `worklog/YYYY/MM/DD/handover.md` に保存する
   （`worklog/` ディレクトリが無いプロジェクトでは `tmp/handover.md` に保存する）
3. 既存ファイルがある場合は `handover-HH:MM.md` で保存する
4. 保存後、ファイルパスをユーザーに伝える

## 注意

- 引き継ぎ先の Claude は会話履歴を持っていない。自己完結した内容にする
- worktree のパス・ブランチ名・PR 番号は必ず含める
- 「何をしたか」だけでなく「なぜそうしたか」の判断も記録する
- 未解決の問題・迷っている点も明記する
