---
name: compact-prep
description: |
  /compact の前に、圧縮の要約から抜け落ちやすい「判断構造」と「セッション状態」を
  tmp/compact-state/<session-id>.md に固定フォーマットで保存する。
  Use when you are about to run /compact, when the user says "compact する前に",
  "compact-prep", "コンテキストを圧縮したい", or when context usage is high and
  compaction is imminent.
  Do NOT use for cross-session handover documents (use handover) — compact-prep is
  for surviving in-session compaction, not for ending a session.
argument-hint: ""
---

# compact-prep

`/compact` の要約は「何をやったか」の物語になり、「なぜその選択をしたか・どの案を却下したか」
という判断構造が抜け落ちる。このスキルは圧縮前にそれらをファイルへ保存する。
圧縮後は SessionStart(compact) hook がこのファイルを読むよう指示を注入する。

`/compact` の直前に実行する。実行後から `/compact` までに下した判断は要約頼みになる。

## 手順

### 1. 保存先を決める

自セッションの id を環境変数から取り、保存先を確定する。

```bash
mkdir -p tmp/compact-state && echo "tmp/compact-state/${CLAUDE_CODE_SESSION_ID}.md"
```

保存先は常にこのセッション別パスにする。同じ作業ディレクトリで並行して動くセッションが
互いの状態を上書きしないため、共有ファイルには書かない。

### 2. 状態ファイルを書く

`tmp/compact-state/<session-id>.md` に以下の見出しを全てこの順で含めて Write する。
該当なしの節は「なし」と明記する。省略すると、書き忘れと区別できなくなる。

```markdown
# Compact State — YYYY-MM-DD HH:MM・session <session-id の先頭8桁>

## Active Plan
進行中の計画と現在のフェーズ。plan ファイルがあればパス

## TaskList Summary
TaskList の in_progress / pending の項目

## Session Decisions
このセッションで確立した判断。採用したものと、却下したものとその理由。
却下理由が消えると、要約が却下案を「試みた手順」として残し、再実行事故につながる

## Constraints and Blockers
セッション中に確立した制約・原則・ユーザーとの合意。例: 検証してから配置する、push しない

## Editing Files
未コミット・未検証のファイルと注意点

## Recovery Notes
圧縮後の自分への手紙。次に何をするべきか。圧縮サマリーの next steps より本ファイルを優先する
```

### 3. 読み返して欠落を検知する

書いた直後にファイルを Read し、本文6見出しが揃っていること、Session Decisions に
却下した案が具体的に1件以上書かれていることを確認する。本当にゼロなら「なし」と明記する。

機械検証: `grep -c '^## ' "tmp/compact-state/${CLAUDE_CODE_SESSION_ID}.md"` が 6 になること。

### 4. ユーザーに報告する

保存パスと、Decisions と Recovery Notes の1行サマリーを報告し、`/compact` を実行してよい
状態であることを伝える。`/compact` 自体はユーザーが打つ。
