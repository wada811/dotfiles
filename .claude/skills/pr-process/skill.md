---
name: pr-process
description: "PRワークフロー全体（計画→実装開始→コミット→セルフレビュー→PR作成→CI・レビュー待ち→コメント対応）をオーケストレートする。git/GitHub の状態を見て今どこにいるかを判断し、そのステージを担当する skill を呼び出す。「実装したい」「PRを出したい」「どこから始めればいい」「実装終わった」「続きをやって」など、開発フローの任意の場面で使う。/pr-plan・/pr-develop・/commit・/pr-create・/pr-status・/pr-respond を個別に呼ぶ代わりにこれ一本で済む。"
---

# pr-process — PRワークフローオーケストレーター

git と GitHub の状態を読んで「今どのステージか」を判断し、そのステージを担当する skill を呼び出す。各ステージの手順は担当 skill が持つので、ここでは重ねて定義しない。この skill が持つのは、ステージの判定と、次のステージへの受け渡しだけ。

担当 skill の手順とプロジェクトの CLAUDE.md（ブランチ名・base ブランチ・worktree・マージ方法など）が食い違うときは、CLAUDE.md に従う。

## 引数

`$ARGUMENTS` の内容で挙動が変わる：
- 目標・やりたいこと → ステージA（計画）から開始
- Issue番号（`#42`）→ ステージB（実装開始）から開始
- 空（再開） → git/GitHub の状態を見て現在のステージを自動検出

---

## Step 1: 現在のステージを検出

```bash
git status --short
git branch --show-current
git log <base>...HEAD --oneline 2>/dev/null
gh issue list --assignee @me --state open --limit 5 2>/dev/null
gh pr view --json number,state,url,reviewDecision 2>/dev/null
```

base はプロジェクトの CLAUDE.md が決める base ブランチ（なければ `main`）。

| ステージ | 条件 | 呼ぶ skill |
|---------|------|-----------|
| **A: 計画** | 引数に目標テキストがある、またはfeatureブランチも未コミット変更もない | `pr-plan` |
| **B: 実装開始** | Issue番号が引数にある、またはIssueはあるがfeatureブランチがない | `pr-develop` |
| **C: コミット** | featureブランチにいて未コミット変更がある | `commit` |
| **D: セルフレビュー** | featureブランチにコミットがあり、PRがない | プロジェクトのセルフレビュー（下記） |
| **E: PR作成** | D が指摘なしで終わった | `pr-create` |
| **F: CI・レビュー待ち** | PRがある | `pr-status` |
| **G: コメント対応** | CI失敗・Changes requested・未対応のコメントがある | `pr-respond` |

---

## ステージごとの呼び出しと受け渡し

### A: 計画 → `pr-plan`

`$ARGUMENTS` の目標テキストを渡して pr-plan を実行する。Issue が作られたら、その番号を持って B へ進む。

### B: 実装開始 → `pr-develop`

Issue番号を渡して pr-develop を実行する。スコープの表示とブランチ（または worktree）の用意が終わったら処理を止める。実装は人間またはエージェントが行い、終わったら `/pr-process` で再開する。

### C: コミット → `commit`

commit を実行する。コミットが終わったら D へ進む。push は commit の手順どおり、確認してから行う。

### D: セルフレビュー

PR を出す前に、差分を自分でレビューする。PR 作成後に自分の PR へ指摘をコメント投稿しないよう、PR 作成より前に置く。

- プロジェクトの CLAUDE.md がセルフレビューの手順を決めていれば、それに従う
- 決めていなければ `/code-review high` を実行する

指摘があれば修正して C に戻る。指摘がなくなったら E へ進む。

### E: PR作成 → `pr-create`

pr-create を実行する。本文は pr-create が pr-body で作り、ユーザーに確認してから PR を作る。PR が作られたら F へ進む。

### F: CI・レビュー待ち → `pr-status`

PR 番号を渡して pr-status を実行し、結果で分岐する。

| 状態 | アクション |
|------|-----------|
| CI実行中・レビュー待ち | 「CIとレビューを待っています。完了したら `/pr-process` で再開してください。」と伝えて終了 |
| CI失敗・Changes requested・未対応のコメント・コンフリクト | G へ進む |
| Approved + CI通過 | 「マージできます」と伝えて終了。マージ方法はプロジェクトの規約に従い、マージは実行しない |

### G: コメント対応 → `pr-respond`

PR 番号を渡して pr-respond を実行する。返信の投稿は pr-respond の手順どおり、下書きを確認してから行う。対応が終わったら F に戻る。

---

## 人間が入る場面

担当 skill が確認する場面を、ステージ順に並べると次のとおり。これ以外は自動で次のステージへ進む。

1. A: スコープの確認（pr-plan）
2. B の後: 実装
3. C: push の確認（commit）
4. E: UI スクリーンショットと PR 本文の確認（pr-create）
5. G: 返信の下書きの確認（pr-respond）

---

## エラー・例外の扱い

- `gh` コマンドが使えない → 「`gh auth login` を実行してください」と伝えて終了
- base ブランチにいて未コミット変更がある → B としてブランチを用意してから C へ進む
- Issueが特定できない → Issue番号を1回だけ確認する
