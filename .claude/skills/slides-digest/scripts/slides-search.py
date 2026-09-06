#!/usr/bin/env python3
"""Speaker Deck をタイトルで検索する。

登壇者名やセッションタイトルしか分かっていないときの入口。日本語タイトルでも通る。

    python3 slides-search.py "作り直せるコードは迅速に" "PdEConf"
"""
import html
import re
import sys
import time
import urllib.parse
import urllib.request

UA = {"User-Agent": "Mozilla/5.0"}


def search(q, limit=5):
    url = "https://speakerdeck.com/search?q=" + urllib.parse.quote(q)
    body = urllib.request.urlopen(
        urllib.request.Request(url, headers=UA), timeout=25
    ).read().decode("utf8", "ignore")
    hits = re.finditer(
        r'<a class="deck-preview-link" href="([^"]+)" title="([^"]*)"', body
    )
    return [(m.group(1), html.unescape(m.group(2))) for m in hits][:limit]


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for q in sys.argv[1:]:
        print("### " + q)
        try:
            hits = search(q)
            if not hits:
                print("    (ヒットなし)")
            for path, title in hits:
                print("    " + title)
                print("      https://speakerdeck.com" + path)
        except Exception as e:
            print("    ERR", e)
        time.sleep(1)


if __name__ == "__main__":
    main()
