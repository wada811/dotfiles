#!/usr/bin/env python3
"""Speaker Deck のページから資料のメタ情報を取り、PDF を落とす。

記事を書くのに必要なものが3つある。PDF 本体（中身を読むため）、slides_id
（スライド画像 URL の組み立てに使う）、総ページ数（画像番号が範囲内かの検証に使う）。
このスクリプトはその3つを一度に返す。

    python3 slides-fetch.py <slides_url> --out-dir tmp/slides --key kinosuke

出力は JSON 1行。--no-download を付けるとメタ情報だけ返す。
"""
import argparse
import html
import json
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0"}


def fetch_html(url):
    return urllib.request.urlopen(
        urllib.request.Request(url, headers=UA), timeout=30
    ).read().decode("utf8", "ignore")


def meta_tag(body, prop):
    m = re.search(
        r'<meta[^>]+(?:property|name)="' + prop + r'"[^>]+content="([^"]*)"', body
    ) or re.search(
        r'<meta[^>]+content="([^"]*)"[^>]+(?:property|name)="' + prop + r'"', body
    )
    return html.unescape(m.group(1)) if m else ""


def parse(url):
    body = fetch_html(url)
    slides_id = re.search(r'data-id="([0-9a-f]{32})"', body)
    pdf = re.search(r'title="Download PDF"[^>]*href="([^"]+)"', body)
    desc = re.search(r'<div class="deck-description[^"]*"[^>]*>(.*?)</div>', body, re.S)
    return {
        "url": url,
        "slides_id": slides_id.group(1) if slides_id else None,
        "title": meta_tag(body, "og:title"),
        "pdf_url": html.unescape(pdf.group(1)) if pdf else None,
        "description": (
            html.unescape(re.sub(r"<[^>]+>", "", desc.group(1))).strip()[:1500]
            if desc
            else meta_tag(body, "og:description")
        ),
    }


def page_count(pdf_path):
    """総ページ数。スライド画像の番号が範囲内かを検証するのに使う。"""
    try:
        out = subprocess.run(
            ["pdfinfo", str(pdf_path)], capture_output=True, text=True, timeout=30
        ).stdout
        m = re.search(r"^Pages:\s+(\d+)", out, re.M)
        if m:
            return int(m.group(1))
    except FileNotFoundError:
        pass
    # poppler がない環境向けのフォールバック
    data = Path(pdf_path).read_bytes()
    return len(re.findall(rb"/Type\s*/Page[^s]", data)) or None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("slides_url")
    ap.add_argument("--out-dir", default="tmp/slides")
    ap.add_argument("--key", help="保存ファイル名（省略時は URL の末尾）")
    ap.add_argument("--no-download", action="store_true")
    args = ap.parse_args()

    info = parse(args.slides_url)
    if not info["slides_id"]:
        sys.exit("slides_id が取れなかった: " + args.slides_url)

    if not args.no_download:
        if not info["pdf_url"]:
            sys.exit("PDF ダウンロードリンクがない（登壇者が DL を無効にしている）")
        out_dir = Path(args.out_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        key = args.key or args.slides_url.rstrip("/").rsplit("/", 1)[-1][:60]
        dest = out_dir / (key + ".pdf")
        # PDF URL のパスは日本語ファイル名が %エンコード済みのことがある
        safe = urllib.parse.quote(info["pdf_url"], safe=":/%?=&")
        with urllib.request.urlopen(
            urllib.request.Request(safe, headers=UA), timeout=120
        ) as r:
            dest.write_bytes(r.read())
        info["pdf"] = str(dest)
        info["pages"] = page_count(dest)

    print(json.dumps(info, ensure_ascii=False))


if __name__ == "__main__":
    main()
