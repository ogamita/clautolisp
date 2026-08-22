#!/usr/bin/env python3
"""Generate index.html pages for the clautolisp releases web area.
Usage: gen-index.py <releases-root>
Scans <root>/<version>/ dirs, writes <version>/index.html (archive listing) and
<root>/index.html (release listing). Idempotent; safe to re-run after each mirror."""
import sys, os, html
ROOT = sys.argv[1]
CSS = ("body{font:16px/1.5 system-ui,sans-serif;max-width:48rem;margin:3rem auto;padding:0 1rem;color:#222}"
       "h1{font-size:1.6rem}a{color:#0645ad;text-decoration:none}a:hover{text-decoration:underline}"
       "nav{color:#888;font-size:.9rem;margin-bottom:1.2rem}ul{list-style:none;padding:0}"
       "li{margin:.6rem 0}table{border-collapse:collapse;width:100%}"
       "td{padding:.45rem .6rem;border-bottom:1px solid #eee}td.s{text-align:right;color:#555;white-space:nowrap}"
       "code{background:#f4f4f4;padding:.1rem .3rem;border-radius:4px}footer{margin-top:2rem;color:#888;font-size:.85rem}")
def human(n):
    n=float(n)
    for u in ("B","KB","MB","GB"):
        if n<1024: return (f"{n:.0f} {u}" if u=="B" else f"{n:.1f} {u}")
        n/=1024
    return f"{n:.1f} TB"
def vkey(v):
    try: return tuple(int(x) for x in v.split("."))
    except Exception: return (0,)
versions=[]
for name in os.listdir(ROOT):
    d=os.path.join(ROOT,name)
    if not os.path.isdir(d): continue
    versions.append(name)
    files=sorted(f for f in os.listdir(d) if os.path.isfile(os.path.join(d,f)) and f!="index.html")
    rows="".join('<tr><td><a href="%s">%s</a></td><td class="s">%s</td></tr>'%(
        html.escape(f),html.escape(f),human(os.path.getsize(os.path.join(d,f)))) for f in files) or "<tr><td>(empty)</td></tr>"
    open(os.path.join(d,"index.html"),"w").write(
"""<!doctype html><html lang=en><head><meta charset=utf-8><meta name=viewport content="width=device-width, initial-scale=1">
<title>clautolisp %s</title><style>%s</style></head><body>
<nav><a href="../">&larr; releases</a> &middot; <a href="../../">clautolisp</a> &middot; <a href="../../../">ogamita</a></nav>
<h1>clautolisp %s</h1>
<p>Release archives. Each unpacks into a <code>$PREFIX</code> (e.g. <code>/opt/local</code>). The <code>-all</code> archive is the union of the individual ones (same content as unpacking them all).</p>
<table>%s</table>
<footer><a href="https://ogamita.com/clautolisp">ogamita.com/clautolisp</a> &middot; <a href="https://gitlab.com/ogamita/clautolisp">source</a></footer>
</body></html>"""%(html.escape(name),CSS,html.escape(name),rows))
versions.sort(key=vkey,reverse=True)
items="".join('<li><a href="%s/">clautolisp %s</a></li>'%(html.escape(v),html.escape(v)) for v in versions) or "<li>(no releases yet)</li>"
open(os.path.join(ROOT,"index.html"),"w").write(
"""<!doctype html><html lang=en><head><meta charset=utf-8><meta name=viewport content="width=device-width, initial-scale=1">
<title>clautolisp releases</title><style>%s</style></head><body>
<nav><a href="../">&larr; clautolisp</a> &middot; <a href="../../">ogamita</a></nav>
<h1>clautolisp &mdash; releases</h1><ul>%s</ul>
<footer><a href="https://ogamita.com/clautolisp">ogamita.com/clautolisp</a> &middot; <a href="https://gitlab.com/ogamita/clautolisp">source</a></footer>
</body></html>"""%(CSS,items))
print("generated %d release page(s) + releases index"%len(versions))
