---
name: pr-status
description: "PRの現在状態をダッシュボード形式で表示する。CI結果・レビュー状況・未対応コメントを一覧する。オプションでCIが完了するまで待機する。「PRどうなってる？」「CIは通った？」「レビューきた？」「何か対応が必要？」のときに使う。"
---

# pr-status — PRステータスダッシュボード

CI・レビュー・コメントを1コマンドで集約して表示する。次に何をすべきかも判断する。

## 引数

- `$ARGUMENTS` が PR番号（`#42` / `42`）→ そのPRを確認
- `--wait` が含まれる → CI が完了するまでポーリング（30秒ごと、最大20分）
- 空 → 現在のブランチのPRを自動検出

## Step 1: PR特定

```bash
# 引数にPR番号があれば使う
# なければ現在のブランチから検出
gh pr view --json number,title,url,state,headRefName 2>/dev/null
```

PRが見つからなければ「このブランチにはPRがありません。`/pr-create` でPRを作成してください。」と伝えて終了。

## Step 2: ステータス収集

```bash
# CI チェック
gh pr checks <番号> 2>/dev/null

# レビュー状況
gh pr view <番号> --json reviews,reviewRequests

# コメント・レビュースレッド
gh pr view <番号> --json reviewThreads,comments

# 総合情報
gh pr view <番号> --json title,state,mergeable,statusCheckRollup,url
```

## Step 3: ダッシュボード表示

以下の形式で表示する：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PR #<番号>: <タイトル>
  <URL>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CI
  <✅ passed / ❌ failed / 🔄 running / ⏭️ skipped>
  <失敗したジョブ名と簡潔なエラーサマリー（失敗時のみ）>

レビュー
  <✅ approved by @name / 🔄 review requested from @name / ❌ changes requested by @name>

未対応コメント
  <スレッドがあれば列挙。なければ「なし」>
  例: - @reviewer: "この変数名をもっと明確に" (src/auth/token.ts:42)

マージ可否
  <✅ マージ可能 / ❌ conflicts あり / 🔄 CI待ち>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
次のアクション: <以下から該当するものを表示>
```

次のアクション判断ロジック：
- CI失敗 → 「`/pr-respond` でCI失敗を修正してください」
- Changes requested → 「`/pr-respond` でレビューコメントに対応してください」
- 未対応コメントあり → 「`/pr-respond` でコメントに回答してください」
- CI実行中 → 「`/pr-status --wait` でCI完了を待てます」
- Approved + CI通過 → 「マージできます: `gh pr merge <番号> --squash`」
- 全クリア → 「レビュアーの承認を待っています」

## Step 4: --wait モード

`--wait` が指定された場合、CI完了までポーリングする：

```
🔄 CIの完了を待っています... (30秒ごとに確認)
   開始から X 分経過
```

CI完了（passed / failed）でポーリングを止め、ステータスを表示する。
20分経過してもCIが終わらない場合は「タイムアウトしました。`/pr-status` で再確認してください。」と伝えて終了。
