---
name: pr-review
description: PRをレビューしてインラインコメントをGitHubに投稿する。PR descriptionで意図を把握してからdiffをレビューし、What+Why+How形式・重大度ラベル付きのコメントをgh APIで各行に直接投稿する。「PRをレビューする」「コードレビューしたい」「このPRの品質を確認したい」時に使う。
---

# pr-review — 意図ファースト・インラインコメント付きレビュー

「意図を掴む → コードを読む」順番を守り、指摘をGitHubのインラインコメントとして投稿する。

## 引数

`$ARGUMENTS` からPR番号を読み取る（`#42` または `42`）。
番号がなければ現在のブランチのPRを探す:

```bash
gh pr view --json number,title,url 2>/dev/null
```

---

## Step 1: PR情報の取得

```bash
# PR基本情報とdiff
gh pr view <番号> --json title,body,url,headRefOid,headRefName,baseRefName

# diffの取得
gh pr diff <番号>

# 変更ファイル一覧
gh pr view <番号> --json files --jq '.files[].path'
```

---

## Step 2: 意図を1文で掴む（コードを読む前に必須）

PR description・リンクIssue・変更ファイルサマリーから
「このPRが達成しようとしていること」を1文で述べる。

**1文で言えない場合** → コードを読む前にGitHubへコメントを投稿して終了：

```bash
gh pr review <番号> \
  --comment \
  --body "PR descriptionが不十分です。以下を追記してください：
- 何を・なぜ変えるか（課題と意図）
- やらなかったことと理由
コードを読む前に目的を把握するため、追記をお願いします。"
```

---

## Step 3: 4層レビュー（順番を変えない）

**Layer 1: テスト**
- 存在するか（なければ理由を確認）
- ふるまいを表現しているか（実装詳細でなく仕様を）
- エッジケースが含まれているか

**Layer 2: 公開API / インターフェース**
- 型・関数シグネチャが適切か
- 既存の呼び出し元を壊していないか
- 命名が既存パターンと整合しているか

**Layer 3: 実装ロジック**
- 正確性（ロジックが仕様・テストを満たすか）
- エラーハンドリング（握りつぶし・ログ忘れ）
- スレッドセーフ性・リソースリーク

**Layer 4: プロジェクト固有ルール**
- CLAUDE.md の規約に従っているか

---

## Step 4: インラインコメントの投稿

各指摘をGitHubのインラインコメントとして投稿する。

### コミットSHAの取得

```bash
gh pr view <番号> --json headRefOid --jq '.headRefOid'
```

### インラインコメントの投稿（ファイル・行ごと）

```bash
gh api repos/{owner}/{repo}/pulls/<番号>/reviews \
  --method POST \
  -f commit_id="<headRefOid>" \
  -f body="<レビュー全体のサマリー>" \
  -f event="COMMENT" \
  -F "comments[][path]=<ファイルパス>" \
  -F "comments[][line]=<行番号>" \
  -f "comments[][body]=<コメント本文>" \
  -F "comments[][path]=<別ファイルパス>" \
  -F "comments[][line]=<別行番号>" \
  -f "comments[][body]=<別コメント本文>"
```

### owner/repo の取得

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

### コメント本文の形式

各インラインコメントは以下の形式で書く：

```
<重大度> **What:** <何が問題か>

**Why:** <なぜ問題か — 根拠・原則・起きうるリスク>

**How:** <修正方向。コード例があれば>
```

重大度ラベル:
- `⛔ blocker` — マージ前必須（クラッシュ・データ破壊・セキュリティ）
- `🔴 major` — 同PR内での修正を推奨
- `🟡 minor` — 次PR可
- `💬 nit` — スタイル・好み（任意）

---

## Step 5: レビューサマリーを投稿

全インラインコメントを含むレビューを1リクエストで送信する（Step 4のAPIコールで `body` に記載）。

サマリー本文の形式：

```markdown
## レビュー: <PRタイトル>

**意図:** <1文>

### 総合判断
<✅ Approve推奨 / 🔄 Request Changes推奨 / 💬 議論推奨>

<判断理由1行>

---
<⛔ N件 / 🔴 N件 / 🟡 N件 / 💬 N件>
各指摘の詳細は上記インラインコメントを参照してください。
```

総合判断の基準：
- **Approve推奨** — ⛔ blockerゼロ・🔴 major 1件以下（次PR合意済み）
- **Request Changes推奨** — ⛔ blocker 1件以上 または 🔴 major 複数
- **議論推奨** — 設計レベルの問題、「15分 sync しましょう」を提案

---

## 教えるコメント（最低1件）

「このコメントを読んだ人が次に似たコードを書くとき良くなる」コメントを
必ず1件以上インラインに含める。設計原則・言語仕様・チームルールの説明を添える。
