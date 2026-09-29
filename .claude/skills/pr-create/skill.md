---
name: pr-create
description: "今のブランチから PR を作る。push・正しい base の指定・タイトル・gh pr create を行い、本文は pr-body skill に任せる。「PRを作りたい」「プルリクエストを作成する」「変更をPRにまとめたい」「PR を出して」時に使う。本文だけを書く・更新するときは pr-body、開発フロー全体を進めるときは pr-process。"
---

# pr-create — 正しい base に PR を出す

今のブランチの変更を、レビュアーがすぐ読める状態で、正しい base に向けた PR にする。本文の中身は pr-body が決めるので、この skill は PR を出すまでの前提（push・base・タイトル・作成前の手順）と、ユーザーの確認に責任を持つ。

プロジェクトの CLAUDE.md が base ブランチ・PR タイトル・作成前の手順を決めていれば、それに従う。

## Step 1: 前提を揃える

- **base:** プロジェクトの CLAUDE.md が決める base ブランチを使う。決めていなければリポジトリの既定ブランチ。`gh pr create` は `--base` を省くと既定ブランチに向けるので、必ず明示する
- **作成前の手順:** CLAUDE.md が PR 作成前のセルフレビュー等を決めていれば、このセッションで済んでいるか確かめる。済んでいなければ、先に実行するかユーザーに聞く。作成後に自分の PR へ指摘を投稿する形にはしない
- **Issue:** ブランチ名・コミット・会話に Issue があれば読む。なくても止まらない（背景の素材は pr-body が集める）

## Step 2: 本文を作る

`pr-body` skill の新規モードで本文を作る。本文の規則は pr-body に従い、ここでは重ねて定義しない。Issue があれば素材として渡す:

- 課題・解決策の意図とリンク（`Closes #<番号>`）→ 背景の役割の節
- 「やらないこと」欄 → スコープ外の役割の節に引用する

pr-body は本文を `tmp/pr-body-<branch>.md` に書き出したところで止まる。

## Step 3: タイトルを決める

CLAUDE.md に規則がなければ、`gh pr list --state all --limit 20` で既存の PR タイトルを見て、言語と形式（Conventional Commits の prefix の有無など）を合わせる。形式を決め打ちすると、リポジトリの慣習とずれる。

## Step 4: 確認する（1 回だけ）

次をまとめて一度に見せ、承認を得る。PR の作成は外部への公開なので、承認なしに進めない。

- base・タイトル・本文
- ユーザーが埋める項目（未チェックのボックス・プレースホルダ）
- UI の変更が含まれるなら、スクリーンショットが要ること（作成前に添付するか、作成後に追記するか）
- ブランチが未 push なら、push すること

## Step 5: push して PR を作る

未 push なら push してから作成する。push は取り消せないので、Step 4 の承認に含めた場合だけ行い、force push はしない。

```bash
gh pr create --base <base> --title "<タイトル>" --body-file tmp/pr-body-<branch>.md --assignee "@me"
```

ドラフトを求められたら `--draft` を足す。

## Step 6: 読み戻して報告する

`gh pr view <番号> --json baseRefName,title,body,url` で読み戻し、base・タイトル・本文が Step 4 で承認したものと一致することを確かめてから、PR の URL を報告する。レビュアーのアサインなど、ユーザーが次にすることがあれば添える。
