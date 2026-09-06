# evals

- `evals.json` — 成果物の中身を評価するテストケース 3 本と、その判定項目
- `trigger-eval.json` — 発動判定用の 20 問（should_trigger 10 / should-not 10）

## skill-creator の description 最適化ループは、このスキルには使えない

`scripts/run_loop.py` / `run_eval.py` は、description だけを書いた**中身のない
コマンドファイル**を一時的に作り、それが呼ばれるかで発動を測る。中身がないので
モデルは「自分でやったほうが早い」と判断して呼ばず、発動してほしい 10 問が
全滅した（2026-09-06 実測。既定モデルでも haiku でも 0/10）。description の
問題ではなく測り方の問題。

実物のスキルを登録した状態で `claude -p ... --permission-mode plan` を流し、
`"name":"Skill"` の発火とどのスキル名が選ばれたかを見るほうが正確。同日の実測では
Speaker Deck の URL で slides-digest が発動し、Google スライドの URL では
google-slides-fetch が選ばれ、ブログ記事と「登壇者の所属だけ知りたい」では
どのスキルも呼ばれなかった（いずれも期待どおり）。

```bash
env -u CLAUDECODE timeout 60 claude -p "<クエリ>" \
  --output-format stream-json --verbose --include-partial-messages \
  --permission-mode plan 2>/dev/null \
  | grep -o 'slides-digest\|"name":"Skill"' | sort | uniq -c
```

スキル名は available_skills の一覧にも出るため、素の出現回数には下駄が乗る。
`"name":"Skill"` が出ているかと、特定の名前だけ出現数が跳ねているかで判断する。
