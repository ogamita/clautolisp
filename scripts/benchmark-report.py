#!/usr/bin/env python3
"""Aggregate per-target AutoLISP benchmark outputs into one comparison table.

Each input file is the stdout of `make -C autolisp-benchmark run-<target>`
(the harness prints a `class benchmark iters iters/sec us/iter` table plus an
`implementation:` / `platform:` / `overall iters/s` header/footer). The target
label is the file's basename without extension.

    scripts/benchmark-report.py <bench-dir> <out-dir>

Writes <out-dir>/index.html (throughput iters/sec, per benchmark x target;
higher = faster) for GitLab Pages, and <out-dir>/benchmarks.csv.
"""
import sys, os, glob, html, csv

def read_text(path):
    """Read PATH as text, honouring a UTF-8/UTF-16 byte-order mark. The
    Windows CI jobs redirect with PowerShell (`*>` / Out-File), which
    defaults to UTF-16LE; decoding those as UTF-8 turns the whole table
    into `c\\x00l\\x00a\\x00s\\x00s` garbage and every row is lost. Sniff
    the BOM so linux/macos (UTF-8) and windows (UTF-16) all parse."""
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        enc = "utf-16"            # the BOM carries the endianness
    elif raw[:3] == b"\xef\xbb\xbf":
        enc = "utf-8-sig"
    else:
        enc = "utf-8"
    return raw.decode(enc, errors="replace")

def parse(path):
    impl = platform = overall = None
    rows = {}
    in_table = False
    for line in read_text(path).splitlines():
        s = line.strip()
        low = s.lower()
        if low.startswith("implementation") and ":" in s:
            impl = s.split(":", 1)[1].strip()
        elif low.startswith("platform") and ":" in s:
            platform = s.split(":", 1)[1].strip()
        elif low.startswith("overall iters/s") and ":" in s:
            overall = s.split(":", 1)[1].strip()
        elif low.startswith("class") and "iters/sec" in low:
            in_table = True
        elif s.startswith("---") or s.startswith("==="):
            in_table = False
        elif in_table and s:
            p = s.split()
            # class benchmark iters iters/sec us/iter
            if len(p) >= 5:
                try:
                    rows[p[1]] = float(p[3])
                except ValueError:
                    pass
    return {"impl": impl, "platform": platform, "overall": overall, "rows": rows}

def main():
    if len(sys.argv) != 3:
        sys.exit("usage: benchmark-report.py <bench-dir> <out-dir>")
    bench_dir, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    files = sorted(glob.glob(os.path.join(bench_dir, "*.txt")))
    targets = [(os.path.splitext(os.path.basename(p))[0], parse(p)) for p in files]

    benches = []
    for _, d in targets:
        for b in d["rows"]:
            if b not in benches:
                benches.append(b)

    # CSV
    with open(os.path.join(out_dir, "benchmarks.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["benchmark"] + [t for t, _ in targets])
        for b in benches:
            w.writerow([b] + [("%.1f" % d["rows"][b]) if b in d["rows"] else "" for _, d in targets])
        w.writerow(["overall iters/s"] + [(d["overall"] or "") for _, d in targets])

    # HTML: per row, bold the fastest target
    def cell(d, b):
        return d["rows"].get(b)
    rows_html = []
    for b in benches:
        vals = [cell(d, b) for _, d in targets]
        best = max([v for v in vals if v is not None], default=None)
        tds = []
        for v in vals:
            if v is None:
                tds.append('<td class="na">-</td>')
            else:
                bold = ' class="best"' if best is not None and v == best else ""
                tds.append(f"<td{bold}>{v:,.1f}</td>")
        rows_html.append(f"<tr><th>{html.escape(b)}</th>{''.join(tds)}</tr>")

    head = "".join(
        f'<th>{html.escape(t)}<br><small>{html.escape((d["impl"] or "")+" / "+(d["platform"] or ""))}</small></th>'
        for t, d in targets)
    overall_row = "<tr class=\"overall\"><th>overall iters/s</th>" + "".join(
        f"<td>{html.escape(d['overall'] or '-')}</td>" for _, d in targets) + "</tr>"

    doc = f"""<!doctype html><meta charset="utf-8">
<title>clautolisp AutoLISP benchmarks</title>
<style>
 body{{font-family:system-ui,sans-serif;margin:2rem;color:#222}}
 h1{{font-size:1.4rem}} table{{border-collapse:collapse;margin-top:1rem}}
 th,td{{border:1px solid #ccc;padding:.35rem .6rem;text-align:right}}
 th:first-child,td:first-child{{text-align:left}}
 thead th{{background:#f4f4f4;vertical-align:bottom}} small{{color:#777;font-weight:normal}}
 .best{{font-weight:bold;background:#eaffea}} .na{{color:#bbb}} .overall td,.overall th{{background:#f9f9f9;font-weight:bold}}
 caption{{caption-side:bottom;color:#777;font-size:.85rem;margin-top:.5rem}}
</style>
<h1>AutoLISP benchmark suite — throughput (iters/sec, higher is faster)</h1>
<table>
 <caption>Bold = fastest per benchmark. Columns are the CI targets that ran; missing targets show &ldquo;-&rdquo;.</caption>
 <thead><tr><th>benchmark</th>{head}</tr></thead>
 <tbody>{''.join(rows_html)}{overall_row}</tbody>
</table>
"""
    with open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(doc)
    print(f"benchmark-report: {len(targets)} target(s), {len(benches)} benchmark(s) -> {out_dir}/index.html")

if __name__ == "__main__":
    main()
