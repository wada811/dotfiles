---
name: pr-create
description: "IssueとCommit履歴からPR descriptionを生成しgh pr createする。本文は pr-body skill で、リポジトリの PR テンプレートに沿って PR が保証すること・理由・対応しないことを書く。「PRを作りたい」「プルリクエストを作成する」「変更をPRにまとめたい」時に使う。"
---

# pr-create — 意図と差分のセットでPRを生成

IssueにあるWhy（意図）とコミット履歴のWhat（差分）を紐付け、レビュアーがコードを読む前に全体像を把握できるPR bodyを生成する。

## Step 1: コンテキスト収集

```bash
# 現在のブランチ名からIssue番号を抽出
git branch --show-current

# コミット履歴（mainとの差分）
git log main...HEAD --oneline

# 変更ファイルのサマリー
git diff main...HEAD --stat
```

ブランチ名に Issue番号が含まれる場合（`feature/#42-...` 形式）は自動抽出。
含まれない場合はユーザーに Issue番号を確認する。

```bash
# Issueの内容を取得
gh issue view <番号>
```

## Step 2: PR bodyの生成

本文は `pr-body` skill の新規モードで作る。テンプレートの扱い・中身の規則・事前チェックは pr-body に従い、ここでは重ねて定義しない。

pr-body には Step 1 で集めた素材を渡す:

- Issue の課題・解決策の意図 → 背景の役割の節の素材にする。Issue へのリンク（`Closes #<番号>`）もそこに入れる
- Issue の「やらないこと」欄 → スコープ外の役割の節に必ず引用する。実装中に追加で除外したものがあれば理由付きで足す
- コミット履歴と diff → 変更内容の役割の節の素材にする。コミット単位で並べず、PR が保証することに書き直す

pr-body は Step 4 の 1（`tmp/pr-body-<branch>.md` への書き出し）まで行う。確認と反映はこの skill の Step 4・5 で一度だけ行う。

## Step 3: スクリーンショットの確認

変更にUI要素が含まれる場合（コンポーザブル・画面・ダイアログ等）:

> UI変更が含まれています。PRを作成する前にスクリーンショットを撮影してください。
> テンプレートのスクリーンショット（証跡）の節に画像を添付してから `/pr-create` を再実行するか、PR作成後に画像を追記してください。

## Step 4: レビュアーへの確認

`tmp/pr-body-<branch>.md` の本文を表示し「このPR bodyでよいですか？」と確認する。ユーザーが埋める項目（未チェックのボックス・プレースホルダ）があれば先頭に列挙する。

## Step 5: PR作成

```bash
gh pr create \
  --title "<type>(<scope>): <subject>" \
  --body-file tmp/pr-body-<branch>.md \
  --assignee "@me"
```

ドラフトとして作成したい場合は `--draft` を追加する。

## Step 6: 完了後の案内

> PR #<番号> を作成しました: <URL>
>
> 次のステップ:
> - レビュアーをアサインしてください（`gh pr edit <番号> --add-reviewer <user>`）
> - セルフレビューするなら `/pr-review #<番号>` を使ってください
> - CI が通るまで待ちましょう
