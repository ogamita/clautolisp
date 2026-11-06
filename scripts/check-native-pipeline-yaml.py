#!/usr/bin/env python3
"""Would GitLab refuse to CREATE the native child pipeline?

.gitlab/native.yml is not .gitlab-ci.yml: the parent's native:pipeline
bridge triggers it as a CHILD pipeline, so `glab ci lint' never sees it.
When GitLab rejects it, the bridge fails with
downstream_pipeline_creation_failed -- a reason that names no line -- and
EVERY macOS / Windows job of the pipeline is skipped, not only the broken
one. MR !462 shipped  if: '$$MACOS_RUNNER == "online" && ...'  (a doubled
`$') past every repo check that way (native-pipeline-yaml-not-linted).

This is an OFFLINE check (no token, no network) for the shapes GitLab
rejects:

  - the file does not parse as YAML, or is not a mapping;
  - a `rules:' (job or workflow) that is not a list, an entry that is not a
    mapping, an unknown rule key, a `when:' GitLab does not know;
  - an `if:' that is not a string;
  - an `if:' expression GitLab's lexer/parser would refuse: `$$NAME' (or any
    `$' not followed by a name), an unterminated '...' / "..." string, an
    unterminated or malformed  /regex/flags  literal, a  =~ / !~  whose
    right side is not a regex or a variable, unbalanced parentheses, a
    dangling && / ||, two operands with no operator between them;
  - `extends:' naming a job that is not in the file, or an extends cycle;
  - a visible job (name not starting with `.') that has no `script:',
    `trigger:' or `run:' once its `extends:' chain is merged in;
  - a `needs:' naming a job that is not in the file (and not optional).

With GITLAB_TOKEN set it ALSO posts the file to the project's ci/lint API
(the check that found the !462 failure); a network failure there is a
warning, the offline verdict stands.

    check-native-pipeline-yaml.py [FILE]     (default .gitlab/native.yml)

Exit 0 when clean, 1 with one line per problem otherwise.
"""
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

try:
    import yaml
except ImportError:                       # pragma: no cover
    sys.exit("check-native-pipeline-yaml: needs PyYAML"
             " (apt-get install python3-yaml)")

ROOT = pathlib.Path(__file__).resolve().parent.parent
NATIVE_YML = ROOT / ".gitlab" / "native.yml"

# Top-level keys that are not jobs.
GLOBAL_KEYWORDS = {
    "stages", "default", "workflow", "include", "variables", "image",
    "services", "cache", "before_script", "after_script", "types",
}
RULE_KEYS = {"if", "changes", "exists", "when", "allow_failure", "variables",
             "needs", "start_in", "interruptible"}
WHEN_VALUES = {"on_success", "on_failure", "always", "never", "manual",
               "delayed"}
WORKFLOW_RULE_KEYS = {"if", "changes", "exists", "when", "variables",
                      "auto_cancel"}


# --- YAML loading -----------------------------------------------------------

class _Loader(yaml.SafeLoader):
    """SafeLoader that accepts GitLab's !reference tag (as a plain list)."""


def _reference(loader, node):
    return {"!reference": loader.construct_sequence(node)}


_Loader.add_constructor("!reference", _reference)


def load(text):
    return yaml.load(text, Loader=_Loader)


# --- rules: if: expressions --------------------------------------------------
#
# GitLab's lexer (lib/gitlab/ci/pipeline/expression/lexeme/*) knows exactly:
#   $NAME   "string"   'string'   /regex/flags   null
#   ==  !=  =~  !~  &&  ||  (  )
# and nothing else; strings have no escapes, a regex may contain \/ .

TOKEN_SPEC = [
    ("ws", r"\s+"),
    ("var", r"\$[A-Za-z_][A-Za-z0-9_]*"),
    ("dstring", r'"[^"]*"'),
    ("sstring", r"'[^']*'"),
    ("null", r"null\b"),
    ("op", r"==|!=|=~|!~"),
    ("logic", r"&&|\|\|"),
    ("lparen", r"\("),
    ("rparen", r"\)"),
]
_TOKEN_RE = [(name, re.compile(rx)) for name, rx in TOKEN_SPEC]
_REGEX_RE = re.compile(r"/((?:\\.|[^/\\])*)/([ismU]*)")


def tokenize(expr):
    """Return a list of (kind, text), or raise ValueError naming the defect."""
    tokens = []
    i = 0
    prev = None
    while i < len(expr):
        c = expr[i]
        # A `/' starts a regex only where an operand is expected after =~ / !~.
        if c == "/":
            if prev is None or prev[0] != "op" or prev[1] not in ("=~", "!~"):
                raise ValueError(f"unexpected `/' at column {i + 1}")
            m = _REGEX_RE.match(expr, i)
            if not m:
                raise ValueError(f"unterminated /regex/ at column {i + 1}")
            end = m.end()
            if end < len(expr) and (expr[end].isalnum() or expr[end] == "_"):
                raise ValueError(
                    f"bad regex flag `{expr[end]}' at column {end + 1}"
                    " (GitLab knows i, s, m, U)")
            try:
                re.compile(m.group(1))
            except re.error as e:
                raise ValueError(f"malformed regex /{m.group(1)}/: {e}")
            tok = ("regex", m.group(0))
            tokens.append(tok)
            prev = tok
            i = end
            continue
        if c == "$":
            if not re.match(r"\$[A-Za-z_]", expr[i:]):
                nxt = expr[i + 1] if i + 1 < len(expr) else "end of expression"
                raise ValueError(
                    f"`$' not followed by a variable name at column {i + 1}"
                    f" (next: {nxt!r}; `$$' is a script escape, not an"
                    " expression one)")
        if c in "\"'":
            if expr.find(c, i + 1) < 0:
                raise ValueError(f"unterminated {c}string{c} at column {i + 1}")
        for name, rx in _TOKEN_RE:
            m = rx.match(expr, i)
            if m:
                if name != "ws":
                    tok = (name, m.group(0))
                    tokens.append(tok)
                    prev = tok
                i = m.end()
                break
        else:
            raise ValueError(f"unexpected {c!r} at column {i + 1}")
    return tokens


class _Parser:
    def __init__(self, tokens):
        self.toks = tokens
        self.pos = 0

    def peek(self):
        return self.toks[self.pos] if self.pos < len(self.toks) else None

    def take(self):
        tok = self.peek()
        self.pos += 1
        return tok

    def parse(self):
        if not self.toks:
            raise ValueError("empty expression")
        self.disjunction()
        tok = self.peek()
        if tok is not None:
            raise ValueError(f"unexpected {tok[1]!r} after a complete"
                             " expression (missing && / ||?)")

    def disjunction(self):
        self.conjunction()
        while self.peek() == ("logic", "||"):
            self.take()
            self.conjunction()

    def conjunction(self):
        self.comparison()
        while self.peek() == ("logic", "&&"):
            self.take()
            self.comparison()

    def comparison(self):
        tok = self.peek()
        if tok is not None and tok[0] == "lparen":
            self.take()
            self.disjunction()
            if self.take() is None or self.toks[self.pos - 1][0] != "rparen":
                raise ValueError("unbalanced `(' (no matching `)')")
            return
        self.operand()
        tok = self.peek()
        if tok is not None and tok[0] == "op":
            self.take()
            rhs = self.take()
            if rhs is None:
                raise ValueError(f"`{tok[1]}' has no right-hand side")
            if tok[1] in ("=~", "!~"):
                if rhs[0] not in ("regex", "var"):
                    raise ValueError(f"`{tok[1]}' needs a /regex/ or a"
                                     f" variable, not {rhs[1]!r}")
            elif rhs[0] not in ("var", "dstring", "sstring", "null"):
                raise ValueError(f"`{tok[1]}' needs an operand, not {rhs[1]!r}")

    def operand(self):
        tok = self.take()
        if tok is None:
            raise ValueError("expression ends where an operand is expected")
        if tok[0] not in ("var", "dstring", "sstring", "null"):
            raise ValueError(f"expected a variable, string or null,"
                             f" not {tok[1]!r}")


def expression_problem(expr):
    """None when GitLab would accept EXPR as a rules: if:, else the reason."""
    try:
        tokens = tokenize(expr)
        _Parser(tokens).parse()
    except ValueError as e:
        return str(e)
    return None


# --- structure ---------------------------------------------------------------

def check_rules(where, rules, keys):
    out = []
    if rules is None:
        return out
    if not isinstance(rules, list):
        return [f"{where}: rules: is not a list"]
    for n, rule in enumerate(rules):
        here = f"{where}: rules[{n}]"
        if isinstance(rule, dict) and "!reference" in rule:
            continue
        if isinstance(rule, list):        # a !reference expanded in place
            continue
        if not isinstance(rule, dict):
            out.append(f"{here}: is not a mapping ({rule!r})")
            continue
        for key in rule:
            if key not in keys:
                out.append(f"{here}: unknown rule key `{key}'")
        if "if" in rule:
            cond = rule["if"]
            if not isinstance(cond, str):
                out.append(f"{here}: if: is not a string ({cond!r})")
            else:
                why = expression_problem(cond)
                if why:
                    out.append(f"{here}: if: {cond!r}: {why}")
        if "when" in rule and rule["when"] not in WHEN_VALUES:
            out.append(f"{here}: when: {rule['when']!r} is not one of"
                       f" {', '.join(sorted(WHEN_VALUES))}")
    return out


def deep_merge(base, over):
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def resolve(name, jobs, stack=()):
    """JOB with its extends: chain merged in; raises ValueError on a defect."""
    if name in stack:
        raise ValueError("extends cycle: " + " -> ".join(stack + (name,)))
    job = jobs[name]
    parents = job.get("extends", [])
    if isinstance(parents, str):
        parents = [parents]
    merged = {}
    for parent in parents:
        if parent not in jobs:
            raise ValueError(f"extends unknown job `{parent}'")
        merged = deep_merge(merged, resolve(parent, jobs, stack + (name,)))
    own = {k: v for k, v in job.items() if k != "extends"}
    return deep_merge(merged, own)


def problems(text):
    try:
        doc = load(text)
    except yaml.YAMLError as e:
        return [f"not valid YAML: {e}"]
    if not isinstance(doc, dict):
        return ["the file is not a YAML mapping"]
    out = []
    workflow = doc.get("workflow")
    if isinstance(workflow, dict):
        out += check_rules("workflow", workflow.get("rules"),
                           WORKFLOW_RULE_KEYS)
    jobs = {k: v for k, v in doc.items() if k not in GLOBAL_KEYWORDS}
    for name, job in jobs.items():
        if not isinstance(job, dict):
            if not name.startswith("."):
                out.append(f"{name}: is not a mapping")
            continue
        out += check_rules(name, job.get("rules"), RULE_KEYS)
    dict_jobs = {k: v for k, v in jobs.items() if isinstance(v, dict)}
    for name in dict_jobs:
        try:
            full = resolve(name, dict_jobs)
        except ValueError as e:
            out.append(f"{name}: {e}")
            continue
        if name.startswith("."):
            continue
        if not any(k in full for k in ("script", "trigger", "run")):
            out.append(f"{name}: no script:, trigger: or run: (after"
                       " extends:)")
        needs = full.get("needs") or []
        if isinstance(needs, list):
            for need in needs:
                if isinstance(need, dict):
                    if "pipeline" in need or "project" in need \
                       or need.get("optional"):
                        continue
                    need = need.get("job")
                if isinstance(need, str) and need not in dict_jobs:
                    out.append(f"{name}: needs unknown job `{need}'")
    return out


# --- optional online lint ----------------------------------------------------

def online_lint(text):
    """Post TEXT to ci/lint when GITLAB_TOKEN is set; problems or []."""
    token = os.environ.get("GITLAB_TOKEN")
    if not token:
        return []
    api = os.environ.get("CI_API_V4_URL", "https://gitlab.com/api/v4")
    project = os.environ.get("CI_PROJECT_ID", "ogamita/clautolisp")
    url = f"{api}/projects/{urllib.parse.quote(project, safe='')}/ci/lint"
    req = urllib.request.Request(
        url, data=json.dumps({"content": text}).encode("utf-8"),
        headers={"PRIVATE-TOKEN": token, "Content-Type": "application/json"},
        method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            answer = json.load(resp)
    except (urllib.error.URLError, OSError, ValueError) as e:
        print(f"check-native-pipeline-yaml: WARNING: ci/lint unreachable"
              f" ({e}); the offline verdict stands", file=sys.stderr)
        return []
    if answer.get("valid"):
        return []
    return [f"ci/lint: {err}" for err in answer.get("errors") or ["invalid"]]


def main(argv):
    path = pathlib.Path(argv[1]) if len(argv) > 1 else NATIVE_YML
    text = path.read_text(encoding="utf-8")
    found = problems(text)
    if not found:
        found = online_lint(text)
    if found:
        for p in found:
            print(f"{path}: {p}", file=sys.stderr)
        print(f"check-native-pipeline-yaml: {len(found)} problem(s) -- GitLab"
              " would refuse to create the native child pipeline, skipping"
              " every macOS/Windows job (native-pipeline-yaml-not-linted)",
              file=sys.stderr)
        return 1
    print(f"check-native-pipeline-yaml: {path} OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
