---
name: pr-status
description: "PR の状況を読み取り専用で確認し、次に何をすべきか・もう何もしなくてよいかを伝える。CI の完了待ち（--wait）もできる。「PRどうなってる？」「CIは通った？」「レビューきた？」「PR #XXXX の状態」「何か対応が必要？」のときに使う。コメントへの対応・CI 失敗の原因調査は pr-respond、他者の PR のレビューは pr-review。"
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
- `--wait` → CI が完了するまで待つ（Step 5）
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

リポジトリの既定をプロジェクトの CLAUDE.md で定めている場合はそれに従う。

## Step 2: 状態の取得

次の2つを**並列で**取得する（owner / repo / PR番号 は対象に置き換える）。

**(1) 本体の状態:**

```bash
gh pr view <PR番号> --repo <owner>/<repo> --json number,title,url,state,isDraft,mergedAt,mergedBy,closedAt,baseRefName,headRefName,labels,reviewDecision,reviewRequests,latestReviews,mergeable,mergeStateStatus,statusCheckRollup,comments
```

**(2) inline コメント（bot のものを含む）:**

```bash
gh api --paginate repos/<owner>/<repo>/pulls/<PR番号>/comments --jq '.[] | {id, user: .user.login, path, line, in_reply_to: .in_reply_to_id, body}'
```

| # | 確認項目 | ソース |
|---|----------|--------|
| 1 | **マージ状態**（OPEN / MERGED / CLOSED・Draft か） | (1) の `state` / `isDraft` / `mergedAt` / `closedAt` |
| 2 | **コンフリクト状態**（MERGEABLE / CONFLICTING / UNKNOWN と詳細） | (1) の `mergeable` / `mergeStateStatus` |
| 3 | **ラベル** | (1) の `labels` |
| 4 | CI ステータス（PASS / FAIL / PENDING / SKIPPED） | (1) の `statusCheckRollup` |
| 5 | レビュー決定（APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED） | (1) の `reviewDecision` / `reviewRequests` / `latestReviews` |
| 6 | inline コメント（bot のものを含む） | (2) |
| 7 | 本体コメント（PR 全体へのコメント） | (1) の `comments` |

### 終了判定を最初に行う

**`state` が `MERGED` または `CLOSED` なら、それ以上の確認と作業はしない。** マージ済み・クローズ済みの PR に対するコメント対応・コンフリクト解消・CI 確認はすべて空振りになる。この場合は「#42 は 2026-09-16 にマージ済み（by @user）。対応は不要」とだけ報告して終了する。セッションが複数日にまたがると、着手前に状態が変わっていることがあるため、この判定は毎回行う。

`isDraft` が true の場合はレビュー依頼の前段階であり、レビュー待ちとは扱わない。

### mergeStateStatus の読み方

`mergeable` は「コンフリクトの有無」しか示さない。**何がマージを止めているか**は `mergeStateStatus` で判断する。

| 値 | 意味 | 伝えること |
|---|---|---|
| `CLEAN` | マージ可能 | マージ可能であること |
| `DIRTY` | コンフリクトあり | base ブランチとのコンフリクト解消が必要（pr-respond） |
| `BLOCKED` | 必須レビュー未承認・必須チェック未完了などでブロック | 何が止めているか（レビュー・チェック） |
| `BEHIND` | base に遅れており更新が必須の設定 | base ブランチの取り込みが必要 |
| `UNSTABLE` | CI が失敗または実行中（マージ自体は可能な設定） | CI の状態（Step 4 の CI の行） |
| `DRAFT` | Draft のため | Draft であり、レビュー依頼の前段階であること |
| `UNKNOWN` | GitHub が判定中 | 判定中のため、少し待って取り直す |

**注意**:
- `reviewDecision` は inline コメントを反映しない。CI が green でも未対応の inline コメントが残っていることがあるため、必ず (2) を確認する。`reviewDecision` が空文字のこともある（レビュー未決定）。
- `checks` は `gh pr view --json` に存在しないフィールド（`Unknown JSON field` エラーになる）。CI は `statusCheckRollup` で取得する。
- 未対応の inline コメントは、スレッドの**最終発言者**で判定する。未解決スレッド数は過大にカウントされるため、`in_reply_to_id` で親子を辿り、最後に発言したのが自分以外のスレッドを未対応とみなす。
- ラベルは運用状態を表していることが多い（作者の対応待ち・レビュー待ち・自動付与の停滞通知など）。プロジェクトのラベル運用があれば、次アクションの判断に使う。ただしラベルは自動付与で実態とずれることがあるため、コメントや CI の実データと食い違う場合は実データを優先し、ずれていることを明示する。
- inline コメントの REST API は既定で 30 件ずつしか返さず、古い順に並ぶため、`--paginate` がないと新しいコメントほど落ちる。
- `reviewRequests` はレビューが提出されると空になるため、空であることだけでは「依頼が未送信」と言えない。`latestReviews` も空（レビューが一件もない）のときだけ未依頼とみなす。
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

マージ済み・クローズ済みの場合はこの表を出さず、1〜2 行で終了を報告する。inline / 本体コメントが 0 件の場合はその旨を1行で記載する。CI が失敗している場合は、失敗したチェック名と、`statusCheckRollup` の details URL（`detailsUrl` / `targetUrl`）を添える。ログの取得と原因調査は pr-respond の役割で、この skill では行わない。

## Step 4: 次アクションの提示

**最初に「作業が必要か」を一文で述べる。** そのうえで、必要なら次にすべきことを 1〜2 件、担当する skill とともに伝える。この skill は読み取り専用なので、伝えた作業をここで実行したり、実行するかを持ちかけたりはしない。

- **MERGED / CLOSED** → 作業不要。それ以上の調査もしない
- **DIRTY（コンフリクト）** → base ブランチとのコンフリクト解消が最優先で必要（`/pr-respond <PR番号>`）
- **CHANGES_REQUESTED / 未対応 inline コメントあり** → コメント対応が必要（`/pr-respond <PR番号>`）
- **CI 失敗** → 失敗したチェックの原因調査と修正が必要（`/pr-respond <PR番号>`）
- **CI 実行中** → 完了待ち。`/pr-status --wait` で完了を待てる
- **BEHIND** → base ブランチの取り込みが必要（`/pr-respond <PR番号>`）
- **CLEAN かつ APPROVED** → マージ可能。マージとその方法はプロジェクトの規約に従い、この skill では実行しない
- **BLOCKED / レビュー依頼が未送信**（`latestReviews` も `reviewRequests` も空） → レビュアーへの依頼が必要
- **Draft** → Draft のまま。レビューを受けるには Ready for review への変更が必要
- **上記のいずれでもない** → レビュー待ち。アクション不要（待機）

bot のレビュー workflow がトリガーされたのに SKIPPED で終わっている場合、bot の返信は来ない。待機ではなく自分で対応する必要があるため、その旨を明示する。

## Step 5: --wait モード

`--wait` が指定された場合、`gh pr checks <PR番号> --repo <owner>/<repo> --watch --interval 30` で CI の完了を待つ（最大 20 分が目安）。前景での `sleep` によるポーリングは使えないため、`--watch` に待機を任せる。Bash のタイムアウトを付けて前景で実行するか、上限を超えて待つならバックグラウンドで実行して終了の通知を待つ。

CI が完了（passed / failed）したら Step 2 から取り直し、Step 3 のステータスを表示する。20 分経過しても終わらない場合は「タイムアウトしました。`/pr-status` で再確認してください。」と伝えて終了する。マージ済み・クローズ済みの PR には `--wait` を使わず、即座に終了を報告する。

## やらないこと

- ❌ ファイル編集・コミット・返信などの書き込み操作（読み取り専用）
- ❌ コメントへの返信投稿（`pr-respond` の役割）
- ❌ マージ済み・クローズ済み PR に対する追加調査
- ❌ `gh ... | jq` のパイプ（`gh --jq` を使う）
- ❌ ASCII 罫線による表・ダッシュボードの描画（Markdown テーブルを使う）
