#!/usr/bin/env python3
"""書き上がった記事を機械検証する。

目で見て気づきにくく、読者には確実に見える壊れ方を潰すためのもの。
画像番号のずれは「別のスライドが表示される」形で出るし、図の描写は
量が増えると人力では見落とす。

    python3 digest-verify.py tmp/digest/x.md --pages 34 --slides-id <32hex>
    python3 digest-verify.py new.md --compare old.md   # 作り直しで落ちた節を検出

終了コードは問題があれば 1。
"""
import argparse
import re
import sys
from pathlib import Path

# 画像を貼った上でさらに絵を言葉で描写している、の目印
# 「合図ではない」のような別語に当たらないよう、図・軸は修飾語ごと拾う
FIGURE_WORDS = [
    "左に", "右に", "上段", "下段", "左側", "右側",
    "並べた図", "示した図", "という図", "この図", "図の左", "図の右",
    "ベン図", "円環", "マトリクス", "フローチャート",
    "スライドには", "スライドでは", "スライドの図",
]


def headings(text):
    return re.findall(r"^#{1,6} +(.+?)\s*$", text, re.M)


def load(path):
    """YAML front-matter は記事本文ではないので落とす。"""
    text = Path(path).read_text()
    return re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)


def check(path, pages, slides_id):
    text = load(path)
    problems = []

    imgs = re.findall(
        r"https://files\.speakerdeck\.com/presentations/([0-9a-f]{32})/slide_(\d+)\.jpg",
        text,
    )
    if not imgs:
        problems.append("スライド画像が1枚も貼られていない")
    for did, n in imgs:
        n = int(n)
        if pages is not None and n >= pages:
            problems.append(
                f"slide_{n}.jpg は範囲外（全 {pages} ページなので最大 slide_{pages - 1}）"
            )
        if slides_id and did != slides_id:
            problems.append(f"slides_id が違う画像がある: {did}")

    for w in FIGURE_WORDS:
        for line in text.splitlines():
            if w in line:
                problems.append(f"画像の描写らしい記述（「{w}」）: {line.strip()[:60]}")
                break

    # 見出し・画像・箇条書き・引用・コード以外の行 = 散文の段落。
    # 最初の ## より前（タイトル・登壇者・資料リンク）は本文ではないので見ない。
    first = re.search(r"^## ", text, re.M)
    body = text[first.start():] if first else text
    prose = [
        ln for ln in body.splitlines()
        if ln.strip()
        and not re.match(r"^(#{1,6} |[-*] |> |!\[|\||`|\[|\d+\. )", ln.strip())
        and not ln.strip().startswith("---")
    ]
    if prose:
        problems.append(f"散文の段落が {len(prose)} 行ある: {prose[0][:60]}")

    msgs = [h for h in headings(text) if h not in ("この発表の主張", "持ち帰れること")]
    h2 = len(re.findall(r"^## ", text, re.M)) - 2
    if not (4 <= h2 <= 9):
        problems.append(f"メッセージの節が {h2} 個（5〜8 が目安）")

    print(f"画像 {len(imgs)} 枚 / メッセージ節 {h2} 個 / 見出し {len(msgs)} 本")
    return problems


def compare(new_path, old_path):
    """作り直しは再生成なので、指示に書かなかった節は静かに消える。それを検出する。"""
    old = set(headings(load(old_path)))
    new = set(headings(load(new_path)))
    dropped = sorted(old - new)
    if dropped:
        print("旧版にあって新版にない見出し:")
        for d in dropped:
            print("  - " + d)
    else:
        print("旧版の見出しはすべて新版にある")
    return dropped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("markdown")
    ap.add_argument("--pages", type=int)
    ap.add_argument("--slides-id")
    ap.add_argument("--compare", help="比較する旧版の markdown")
    args = ap.parse_args()

    problems = check(args.markdown, args.pages, args.slides_id)
    if args.compare:
        problems += ["落ちた見出し: " + d for d in compare(args.markdown, args.compare)]

    if problems:
        print("\n--- 要修正 ---")
        for p in problems:
            print("  ✗ " + p)
        sys.exit(1)
    print("問題なし")


if __name__ == "__main__":
    main()
