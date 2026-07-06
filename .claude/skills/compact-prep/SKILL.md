---
name: compact-prep
effort: medium
description: |
  /compact の前に、圧縮の要約から抜け落ちやすい「判断構造」と「セッション状態」を
  tmp/compact-state/latest.md に固定フォーマットで保存する。
  Use when you are about to run /compact, when the user says "compact する前に",
  "compact-prep", "コンテキストを圧縮したい", or when context usage is high and
  compaction is imminent.
  Do NOT use for cross-session handover documents (use handover) — compact-prep is
  for surviving in-session compaction, not for ending a session.
argument-hint: ""
---

# compact-prep

`/compact` の要約は「何をやったか」の物語になり、「なぜその選択をしたか・どの案を却下したか」
という判断構造が抜け落ちる（実観測: 検証前デプロイ・却下済み手法の再実行・設計原則の失念）。
このスキルは圧縮前にそれらを `tmp/compact-state/latest.md` へ保存する。
圧縮後は SessionStart(compact) hook がこのファイルを読むよう指示を注入する。

## 使い分け（軽量ルートで足りるか）

- **通常セッション → 軽量ルート（1アクション）**: 本スキルを使わず
  `/compact 却下した案と却下理由・確立した制約・次の一手を必ず保持して要約して` のように
  **引数で要約器に保持指示を渡す**だけで足りることが多い
- **超長期・判断の多いセッション → 完全ルート（本スキル→/compact）**: 判断構造をファイルに
  永続化するため、自動 compact に先を越された場合や要約器の取りこぼしにも耐える
- なお PreCompact hook は存在するが shell であり、判断構造はモデルのターンでしか書き出せない。
  「/compact と打つだけで prep も走る」自動化は構造的に不可能（compact-plus も同じ制約）

## 手順

### 1. 状態ファイルを書く

`tmp/compact-state/latest.md` に**以下の見出しを全てこの順で**含めて Write する。
該当なしの節は「なし」と明記する（省略しない — 省略と書き忘れが区別できなくなる）:

```markdown
# Compact State（YYYY-MM-DD HH:MM・この作業ディレクトリのセッション）

## Active Plan
（進行中の計画・現在のフェーズ。plan ファイルがあればパス）

## TaskList Summary
（Claude Code の TaskList の要点: in_progress / pending の項目）

## Session Decisions（採用・却下と理由）
（このセッションで確立した判断。特に**却下した案と却下理由** — 要約はこれを「試みた手順」に
変えてしまい、再実行事故の原因になる）

## Constraints and Blockers
（セッション中に確立した制約・原則・ユーザーとの合意。例:「検証してから配置」「push しない」）

## Editing Files
（未コミット・未検証のファイルと注意点）

## Recovery Notes（圧縮後の自分への手紙）
（次に何をするべきか。圧縮サマリーの next steps より本ファイルを優先すること）
```

### 2. 読み返して欠落を検知する（forcing function）

書いた直後にファイルを Read し、本文6見出し（Active Plan / TaskList Summary / Session Decisions /
Constraints and Blockers / Editing Files / Recovery Notes）が揃っているか・「却下した案」が
最低1件は具体的に書かれているか（本当にゼロなら「なし」明記）を確認する。
機械検証: `grep -c '^## ' tmp/compact-state/latest.md` が 6 になること。

### 3. ユーザーに報告する

保存パスと要点（Decisions と Recovery Notes の1行サマリー）を報告し、
「/compact を実行してよい」状態であることを伝える。**/compact 自体はユーザーが打つ**
（自動 compact に先を越された場合も、SessionStart(compact) hook が本ファイルの
存在を検知して読み込みを指示するため、直前の compact-prep 実行分までは復元できる）。

## 制約（既知の限界）

- `latest.md` は cwd ごとに1つ。同一リポジトリで並行セッションが同時に compact-prep すると
  後勝ちで上書きされる（v1 の割り切り。ファイル冒頭の日時で自分のものか判断する）
- 保存されるのは compact-prep 実行時点まで。実行後〜/compact までの判断は要約頼みになるので、
  compact-prep は /compact の直前に実行する
