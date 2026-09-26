#!/usr/bin/env python3
"""Assert that the CAD sweep blocks only the jobs a wedged AutoCAD can affect.

cad-sweep-blocks-bricscad-jobs-over-autocad.

scripts/sweep-orphaned-cad.ps1 runs before every Windows CAD job and, when a
CAD it recorded is still RUNNING and cannot be ended, fails that job. The
justification is specific: a wedged acad.exe owns the AutoCAD.Application COM
registration, so an AutoCAD session would reach it and get RPC_E_CALL_REJECTED.
That argument covers AutoCAD jobs. It does not cover a BricsCAD job, which
neither asks for nor shares that registration -- and on 2026-09-26 the sweep
failed harvest:sysvars:bricscad:windows among 21 others.

So a Windows CAD job must sit on the gate that matches what it DRIVES:

    drives AutoCAD (or accoreconsole, which IS AutoCAD)
        -> .gate-windows-cad-{hard,soft}       (a survivor fails the job)
    drives BricsCAD only
        -> .gate-windows-bricscad-{hard,soft}  (sweeps, is not stopped)

Both still sweep: cleaning up after a killed job is right whatever the vendor.
Neither changes the `cad' tag, which remains the single global mutex serialising
every CAD job (pjb, 2026-08-14) -- this is about the sweep's verdict, not
scheduling.

The check is mechanical because the failure is invisible on the day: a new
bricscad job added on the blocking gate costs nothing until someone leaves a
wedged AutoCAD on the machine, and then reddens a lane that had no business
caring.

    python3 scripts/check-cad-sweep-gating.py
    make check-cad-sweep-gating
"""
import sys

try:
    import yaml
except ImportError:                                     # pragma: no cover
    print('check-cad-sweep-gating: PyYAML not installed; skipping')
    sys.exit(0)

PATH = '.gitlab/native.yml'
BLOCKING = ('.gate-windows-cad-hard', '.gate-windows-cad-soft')
NONBLOCKING = ('.gate-windows-bricscad-hard', '.gate-windows-bricscad-soft')

# accoreconsole is AutoCAD's console executable: an AutoCAD job by any name.
AUTOCAD_MARKERS = ('autocad', 'accoreconsole', 'epure')
BRICSCAD_MARKERS = ('bricscad',)

document = yaml.safe_load(open(PATH, encoding='utf-8'))
problems = []
checked = 0

# The templates themselves must exist and carry the sweep / the variable.
for name in BLOCKING + NONBLOCKING:
    if name not in document:
        problems.append('%s is missing' % name)
for name in NONBLOCKING:
    job = document.get(name) or {}
    if (job.get('variables') or {}).get('CAD_SWEEP_NONBLOCKING') != '1':
        problems.append('%s must set CAD_SWEEP_NONBLOCKING: "1"' % name)

for name, job in document.items():
    if not isinstance(job, dict) or name.startswith('.'):
        continue
    extends = job.get('extends')
    extends = [extends] if isinstance(extends, str) else (extends or [])
    on_blocking = any(e in BLOCKING for e in extends)
    on_nonblocking = any(e in NONBLOCKING for e in extends)
    if not (on_blocking or on_nonblocking):
        continue
    checked += 1
    lowered = name.lower()
    drives_autocad = any(m in lowered for m in AUTOCAD_MARKERS)
    drives_bricscad = any(m in lowered for m in BRICSCAD_MARKERS)
    if drives_autocad and on_nonblocking:
        problems.append(
            '%s names AutoCAD (or accoreconsole/epure) but sits on a '
            'NON-blocking gate: a wedged acad.exe would break it silently'
            % name)
    elif drives_bricscad and not drives_autocad and on_blocking:
        problems.append(
            '%s drives BricsCAD only but sits on the BLOCKING gate: a wedged '
            'acad.exe it never speaks to would fail it '
            '(use .gate-windows-bricscad-hard/-soft)' % name)
    elif not drives_autocad and not drives_bricscad:
        problems.append(
            '%s is on a CAD gate but its name says neither vendor; classify it '
            'explicitly (read its script) rather than leaving the default'
            % name)

if checked == 0:
    problems.append('no Windows CAD job found at all -- this check examined '
                    'nothing, which cannot be right')

for problem in problems:
    print('FAIL  %s' % problem)
if problems:
    print('\ncad-sweep-gating: %d problem(s); see '
          'issues/open/cad-sweep-blocks-bricscad-jobs-over-autocad.issue'
          % len(problems))
    sys.exit(1)
print('cad-sweep-gating: %d Windows CAD job(s), each on the gate its vendor '
      'calls for' % checked)
