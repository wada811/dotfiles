---
name: pr-setup
description: "現在のリポジトリにPRワークフローの雛形を設置する。PULL_REQUEST_TEMPLATE・Issueテンプレート・CLAUDE.mdのワークフローセクションを生成する。「このリポジトリでpr-planなどのワークフローを使いたい」「リポジトリのPR設定をしたい」「pr-workflowをセットアップしたい」時に使う。"
---

# pr-setup — リポジトリへのPRワークフロー設置

`/pr-plan`・`/pr-develop`・`/commit`・`/pr-create`・`/pr-process` などの PR 系 skill が機能するための、リポジトリ側の雛形（テンプレート・CLAUDE.md）を一括セットアップする。

PR 系 skill は、base ブランチ・ブランチ名・PR タイトル・PR 作成前の手順を「プロジェクトの CLAUDE.md に従う」として参照する。この skill の役目は、その参照先をリポジトリに用意すること。値は決め打ちせず、リポジトリの実態から推測してユーザーに確かめる。

## Step 1: 既存のものを確かめる

git リポジトリのルートで実行する（そうでなければ伝えて終了）。次の既存ファイルがあれば中身を読み、上書き・追記してよいかを確認してから進む。既存のテンプレートや規約を黙って置き換えると、チームの合意を壊すため。

- `.github/pull_request_template.md`（`.github/PULL_REQUEST_TEMPLATE.md`・`.github/PULL_REQUEST_TEMPLATE/` も）
- `.github/ISSUE_TEMPLATE/plan.md`
- `CLAUDE.md`

## Step 2: PR テンプレートを置く

PR テンプレートがなければ `.github/pull_request_template.md` を作る。見出しは pr-body の 4 つの役割（背景・変更内容・スコープ外・見てほしい点）に合わせる。pr-body がこのテンプレートを読んで本文を書くため。

```markdown
## 背景
<!-- この PR が要る理由。Issue があればリンク（Closes #NNN） -->

## 変更内容
<!-- この PR が保証すること。関数名などの実装の説明は diff に任せる -->

## スコープ外
<!-- やらないことと、その理由 -->

## 見てほしい点
<!-- 自信のない点。なければ「特になし」 -->

## スクリーンショット
<!-- UI 変更があれば添付。なければこの節を削除 -->
```

## Step 3: Issue テンプレートを置く

`.github/ISSUE_TEMPLATE/plan.md` を以下の内容で作成する。pr-plan が作る Issue と、pr-develop が読むスコープの形式に合わせてある:

```markdown
---
name: 実装計画
about: コードを書く前に意図とスコープを記録する（/pr-plan で自動生成）
labels: ''
assignees: ''
---

## 課題
<!-- なぜやるか。背景と動機。 -->

## 解決策・意図
<!-- どのアプローチを選ぶか。代替案と選ばなかった理由も記載すると後で参照しやすい。 -->

## やること
- [ ]

## やらないこと（スコープ外）
<!-- 今回除外する内容と除外理由。「次回以降」「別 Issue」など明示する。 -->
-

## 完了条件
<!-- 何ができたら完了とみなすか。テスト・観察で確認可能な形で書く。 -->
- [ ]
```

## Step 4: CLAUDE.md に規約を書く

PR 系 skill が参照する項目を、`CLAUDE.md` の「開発ワークフロー」節に書く（なければ新規作成、あれば末尾に追記）。各値はリポジトリの実態から推測し、ユーザーに確かめてから書く。推測の材料と一緒に見せると、ユーザーは直すだけで済む。

| 項目 | 推測の材料 |
|---|---|
| base ブランチ | リポジトリの既定ブランチ、直近の PR の base（`gh pr list --state merged --limit 20 --json baseRefName`） |
| ブランチ名の形式 | `git branch -r` の既存ブランチ名 |
| PR タイトルの形式 | 直近の PR タイトル |
| PR 作成前の手順 | lint・テスト・セルフレビューのコマンド（ユーザーに聞く） |

書く内容の形:

```markdown
## 開発ワークフロー

`/pr-process` で計画から PR 作成・コメント対応までを進める。個別には `/pr-plan` → `/pr-develop` → `/commit` → （作成前の手順）→ `/pr-create` の順。

- base ブランチ: <値>
- ブランチ名: <形式>
- PR タイトル: <形式>
- PR 作成前の手順: <コマンドや skill>。PR を出してから自分の PR に指摘を投稿する形にはしない
- スコープ外の作業が必要になったら実装を止め、新しい Issue を `/pr-plan` で作成する
```

コミットメッセージの様式は commit skill が既存のログから決めるので、ここには書かない。

## Step 5: .claude/settings.json にプロジェクト固有 hook を提案

lint・型チェックのコマンドをユーザーに確認し、`.claude/settings.json` を生成する。

ユーザーへの確認:

> プロジェクトの lint/型チェックコマンドを教えてください。
> 例: `./gradlew lint`（Android）、`npm run lint`（Node）、`python -m ruff check .`（Python）
> 不要な場合はスキップします。

入力があれば `.claude/settings.json` を生成:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "<lint-command> 2>&1 | head -20 || true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Step 6: 報告する

作成・追記したファイルと、CLAUDE.md に書いた値を一覧で報告する。作成したファイルを git に追加するかはユーザーに確認する。
