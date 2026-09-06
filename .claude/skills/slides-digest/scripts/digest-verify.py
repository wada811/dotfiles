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


# 主張の数に数えない、決まった節
FIXED_HEADINGS = {"この発表の主張", "早見表", "持ち帰れること", "会場の反応", "用語ミニ辞典"}

MAX_PROSE_RUN = 2  # 続けてよい地の文の行数
MAX_PROSE_LEN = 120  # 1行の地の文の長さ（文字）


def long_prose(body):
    """長すぎる地の文だけを拾う。

    見出し・箇条書き・表・図・引用・画像は表現手段として認める。読みづらさは
    「段落で説明していること」から来るので、続く行数と1行の長さで判定する。
    """
    problems = []
    run = []
    fence = False
    for ln in body.splitlines() + [""]:
        s = ln.strip()
        if s.startswith("```"):
            fence = not fence
            continue
        structural = (
            not s
            or fence
            or re.match(r"^(#{1,6} |[-*+] |> |!\[|\||\d+\. |---)", s)
        )
        if structural:
            if len(run) > MAX_PROSE_RUN:
                problems.append(
                    f"地の文が {len(run)} 行続いている: {run[0][:50]}"
                )
            run = []
        else:
            run.append(s)
            if len(s) > MAX_PROSE_LEN:
                problems.append(f"1行が長い地の文（{len(s)} 字）: {s[:50]}")
    return problems


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

    # 問題なのは長い散文であって、箇条書き以外ではない。表・図・コードは通す。
    # 最初の ## より前（タイトル・登壇者・資料リンク）は本文ではないので見ない。
    first = re.search(r"^## ", text, re.M)
    problems += long_prose(text[first.start():] if first else text)

    # 決まった節は主張の数に数えない。早見表は参照用なので上限の外に置く
    msgs = [
        h for h in re.findall(r"^## +(.+?)\s*$", text, re.M)
        if h.strip() not in FIXED_HEADINGS
    ]
    # 目安の 5〜8 をそのまま見る。ここを緩めると「7個を超えたら統合する」という
    # 指示が空文になり、節が増えて主張がぼやけるのを検知できない
    if not (5 <= len(msgs) <= 8):
        problems.append(f"メッセージの節が {len(msgs)} 個（5〜8 に収める）")

    print(f"画像 {len(imgs)} 枚 / メッセージ節 {len(msgs)} 個 / 表 {len(re.findall(r'^\|', text, re.M))} 行")
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
