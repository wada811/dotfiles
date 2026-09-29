#!/usr/bin/env python3
"""PR 本文の機械的に確かめられる規則を検査する。

usage: check.py <本文.md> [--template <テンプレート.md>] [--width 80]
"""
import argparse
import re
import unicodedata


def display_width(text):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def headings(text):
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    return [line.strip() for line in text.splitlines() if re.match(r"#{1,6} ", line)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("body")
    parser.add_argument("--template")
    parser.add_argument("--width", type=int, default=80)
    args = parser.parse_args()

    body = open(args.body, encoding="utf-8").read()
    bullet = re.compile(r"^\s*(?:[-*]|\d+\.)\s+(?!\[[ xX]\])")
    long_lines, identifier_lines = [], []
    for no, line in enumerate(body.splitlines(), 1):
        if not bullet.match(line):
            continue
        # リンクの URL は表示されないので幅に数えない
        shown = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", line.strip())
        if display_width(shown) > args.width:
            long_lines.append((no, display_width(shown), line.strip()))
        if re.search(r"`[^`]+`", line):
            identifier_lines.append((no, line.strip()))

    missing = []
    if args.template:
        template = open(args.template, encoding="utf-8").read()
        present = set(headings(body))
        missing = [h for h in headings(template) if h not in present]

    print(f"## 表示幅 {args.width} 桁の目安を超える項目（分けても文が崩れないなら分ける）: {len(long_lines)} 件")
    for no, width, line in long_lines:
        print(f"L{no} ({width}桁): {line}")
    print(f"\n## 識別子を含む項目（実装名が主語・目的語でないか判定する）: {len(identifier_lines)} 件")
    for no, line in identifier_lines:
        print(f"L{no}: {line}")
    if args.template:
        print(f"\n## テンプレートにあって本文にない見出し（削除指示のある節か判定する）: {len(missing)} 件")
        for h in missing:
            print(h)


if __name__ == "__main__":
    main()
