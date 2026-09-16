---
name: pr-status
description: "PRの状況を読み取り専用で確認する。マージ状態（未/済・クローズ済み）・コンフリクト・CI・レビュー決定・ラベル・inlineコメント・本体コメントを取得し、Markdownテーブルで整形して「次に何をすべきか」「もう何もしなくてよいか」を判断できる形で提示する。--wait でCI完了まで待機できる。「PRどうなってる？」「CIは通った？」「レビューきた？」「PR #XXXX の状態」「何か対応が必要？」のときに使う。コメントへの対応・返信は行わない（pr-respond の役割）。"
argument-hint: "[PR番号 or URL] [--repo owner/name] [--wait] (省略時: 会話コンテキストのPR → 現在のブランチ → open PR 一覧)"
---

# pr-status — PR 状況ダッシュボード

PR の状態を集約して表示し、**次に何をすべきか / もう何もしなくてよいか**を判断できる形で返す。**読み取り専用**で、編集・コミット・返信はしない。

`pr-respond` との違い:
- **`pr-status`**: 状況確認のみ（読み取り専用）
- **`pr-respond`**: コメントへの判断・修正・コミット・返信まで一気通貫

## 引数

- PR番号（`#42` / `42`）または PR の URL → その PR を対象にする
- `--repo owner/name` → 対象リポジトリを指定する
- `--wait` → CI が完了するまでポーリングする（Step 5）
- 省略 → Step 1 の順で対象を決める

URL（`https://github.com/<owner>/<repo>/pull/<番号>`）が渡された場合は owner / repo / 番号をそこから抽出する。

## Step 1: PR 特定

次の順で対象を決める。

1. **引数**: PR番号または URL が指定されていればそれを使う
2. **会話コンテキスト**: 引数がなければ、このセッションで直前に扱っていた PR の番号を対象にする（直前に確認・対応していた PR、ユーザーが会話中に挙げた番号など）。対象を決めたら「コンテキストから #42 を対象にした」と一行で明示し、取り違えていればユーザーがすぐ指摘できるようにする
3. **現在のブランチ**: 引数もコンテキストもなければブランチから検出する

```bash
gh pr view --json number,title,url,state,headRefName 2>/dev/null
```

4. **一覧から確認**: それでも特定できなければ、自分の open PR を一覧してユーザーに確認する

```bash
gh pr list --author @me --state open --limit 30
```

stack PR のように open PR が多いリポジトリでは `--limit 10` だと目的の PR が漏れるため、`--limit 30` を使う。複数あればユーザーに確認し、1件なら自動でそれを対象にする。一覧も空なら「このブランチには PR がありません。`/pr-create` で PR を作成してください。」と伝えて終了する。

リポジトリの既定をプロジェクト側の CLAUDE.md で定めている場合はそれに従う。

## Step 2: 状態の取得

次の2つを**並列で**取得する（owner / repo / PR番号 は対象に置き換える）。

**(1) 本体の状態:**

```bash
gh pr view <PR番号> --repo <owner>/<repo> --json number,title,url,state,isDraft,mergedAt,mergedBy,closedAt,baseRefName,headRefName,labels,reviewDecision,reviewRequests,mergeable,mergeStateStatus,statusCheckRollup,comments
```

**(2) inline コメント（bot のものを含む）:**

```bash
gh api repos/<owner>/<repo>/pulls/<PR番号>/comments --jq '[.[] | {id, user: .user.login, path, line, in_reply_to: .in_reply_to_id, body}]'
```

| # | 確認項目 | ソース |
|---|----------|--------|
| 1 | **マージ状態**（OPEN / MERGED / CLOSED・Draft か） | (1) の `state` / `isDraft` / `mergedAt` / `closedAt` |
| 2 | **コンフリクト状態**（MERGEABLE / CONFLICTING / UNKNOWN と詳細） | (1) の `mergeable` / `mergeStateStatus` |
| 3 | **ラベル** | (1) の `labels` |
| 4 | CI ステータス（PASS / FAIL / PENDING / SKIPPED） | (1) の `statusCheckRollup` |
| 5 | レビュー決定（APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED） | (1) の `reviewDecision` / `reviewRequests` |
| 6 | inline コメント（bot のものを含む） | (2) |
| 7 | 本体コメント（PR 全体へのコメント） | (1) の `comments` |

### 終了判定を最初に行う

**`state` が `MERGED` または `CLOSED` なら、それ以上の確認と作業はしない。** マージ済み・クローズ済みの PR に対するコメント対応・コンフリクト解消・CI 確認はすべて空振りになる。この場合は「#42 は 2026-09-16 にマージ済み（by @user）。対応は不要」とだけ報告して終了する。セッションが複数日にまたがると、着手前に状態が変わっていることがあるため、この判定は毎回行う。

`isDraft` が true の場合はレビュー依頼の前段階であり、レビュー待ちとは扱わない。

### mergeStateStatus の読み方

`mergeable` は「コンフリクトの有無」しか示さない。**何がマージを止めているか**は `mergeStateStatus` で判断する。

| 値 | 意味 | 次にやること |
|---|---|---|
| `CLEAN` | マージ可能 | マージする |
| `DIRTY` | コンフリクトあり | base ブランチをマージして解消する |
| `BLOCKED` | 必須レビュー未承認・必須チェック未完了などでブロック | レビュー依頼・承認待ち |
| `BEHIND` | base に遅れており更新が必須の設定 | base ブランチを取り込む |
| `UNSTABLE` | CI が失敗または実行中（マージ自体は可能な設定） | CI の結果を確認する |
| `DRAFT` | Draft のため | Ready for review にする |
| `UNKNOWN` | GitHub が判定中 | 少し待って取り直す |

**注意**:
- `reviewDecision` は inline コメントを反映しない。CI が green でも未対応の inline コメントが残っていることがあるため、必ず (2) を確認する。`reviewDecision` が空文字のこともある（レビュー未決定）。
- `checks` は `gh pr view --json` に存在しないフィールド（`Unknown JSON field` エラーになる）。CI は `statusCheckRollup` で取得する。
- 未対応の inline コメントは、スレッドの**最終発言者**で判定する。未解決スレッド数は過大にカウントされるため、`in_reply_to_id` で親子を辿り、最後に発言したのが自分以外のスレッドを未対応とみなす。
- ラベルは運用状態を表していることが多い（作者の対応待ち・レビュー待ち・自動付与の停滞通知など）。プロジェクトのラベル運用があれば、次アクションの判断に使う。ただしラベルは自動付与で実態とずれることがあるため、コメントや CI の実データと食い違う場合は実データを優先し、ずれていることを明示する。
- `gh ... | jq` のパイプは使わず、`gh --jq` フラグを使う。

## Step 3: 報告の整形

Markdown テーブルで出力する。ASCII 罫線の表（`━━━` や `+----+`）は環境によって崩れるため使わない。

```
## PR #<番号> <タイトル>
<owner>/<repo> ・ base `<baseRefName>`

| 項目 | 状態 |
|------|------|
| マージ | ✅ マージ済み（YYYY-MM-DD by @user）/ 🚫 クローズ済み / ⬜ 未マージ（OPEN）/ 📝 Draft |
| コンフリクト | ✅ なし（CLEAN）/ ⚠️ あり（DIRTY・base のマージが必要）/ 🔒 BLOCKED / ⏪ BEHIND / ❔ UNKNOWN |
| CI | ✅ 通過 / ❌ <失敗チェック名> / ⏳ 実行中 / ⏭️ SKIPPED |
| レビュー | ✅ APPROVED / 🔴 CHANGES_REQUESTED / ⏳ REVIEW_REQUIRED / — 未決定・未依頼 |
| ラベル | <ラベル名をカンマ区切りで。なければ「なし」> |
| inline コメント | <未対応件数> 件（bot N / 人 N） |
| 本体コメント | <件数> 件 |

### 未対応の inline コメント
- [@user] path:line — <要約>（コメントへのリンク）
```

マージ済み・クローズ済みの場合はこの表を出さず、1〜2 行で終了を報告する。inline / 本体コメントが 0 件の場合はその旨を1行で記載する。CI が失敗している場合は、失敗したジョブ名と簡潔なエラーサマリーを添える。

## Step 4: 次アクションの提示

**最初に「作業が必要か」を一文で述べる。** そのうえで、必要なら次に取るべきアクションを 1〜2 件提示する。

- **MERGED / CLOSED** → 作業不要。それ以上の調査もしない
- **DIRTY（コンフリクト）** → base ブランチとのコンフリクト解消を最優先で提案する
- **CHANGES_REQUESTED / 未対応 inline コメントあり** → `/pr-respond <PR番号>` を提案する
- **CI 失敗** → 失敗チェックの詳細確認を提案する
- **CI 実行中** → `/pr-status --wait` で完了を待てることを伝える
- **BEHIND** → base ブランチの取り込みを提案する
- **CLEAN かつ APPROVED** → マージ可能。マージするか確認する
- **BLOCKED / レビュー依頼が未送信**（`reviewRequests` が空） → レビュアーへの依頼を提案する
- **Draft** → Ready for review にするかを確認する
- **上記のいずれでもない** → レビュー待ち。アクション不要（待機）

bot のレビュー workflow がトリガーされたのに SKIPPED で終わっている場合、bot の返信は来ない。待機ではなく自分で対応する必要があるため、その旨を明示する。

## Step 5: --wait モード

`--wait` が指定された場合、CI 完了まで 30 秒ごとにポーリングする（最大 20 分）。

```
🔄 CI の完了を待っています...（30秒ごとに確認）
   開始から X 分経過
```

CI が完了（passed / failed）したらポーリングを止め、Step 3 のステータスを表示する。20 分経過しても終わらない場合は「タイムアウトしました。`/pr-status` で再確認してください。」と伝えて終了する。マージ済み・クローズ済みの PR には `--wait` を使わず、即座に終了を報告する。

## やらないこと

- ❌ ファイル編集・コミット・返信などの書き込み操作（読み取り専用）
- ❌ コメントへの返信投稿（`pr-respond` の役割）
- ❌ マージ済み・クローズ済み PR に対する追加調査
- ❌ `gh ... | jq` のパイプ（`gh --jq` を使う）
- ❌ ASCII 罫線による表・ダッシュボードの描画（Markdown テーブルを使う）
