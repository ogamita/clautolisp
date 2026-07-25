# Version and release rules

Normative rules for version numbers, release marks, and branches.
Written to be reusable by any project, not only this one; a project
adopts it by reference and adds nothing but its own program list.

## 1. What versioning is for

Three goals. They pull in different directions, which is why they need
different kinds of ref.

### 1.1 Identify a frozen feature set

A version number names one exact set of features, forever. It is a
fact about the past, not a moving target.

```
1.2.0 = f1, f2,   f3,   f4
1.2.1 = f1, f2.1, f3,   f4              a bug correction
1.2.2 = f1, f2.1, f3,   f4, f5          + a new internal module
1.3.0 = f1, f2.1, f3.1, f5, f6          some changed, some added, f4 removed
2.0.0 = f1.20, f3.45, f5, f6.6, f7, f8, f9    a lot has changed
```

Each of those is an equality, not an inclusion: `1.2.1` *equals* that
set. Anyone who has `1.2.1` has exactly those features, on any machine,
at any time in the future.

### 1.2 Identify an evolving reference for users

Users do not choose a frozen point; they choose a **series** — `1.2`
versus `1.3` versus `2.0`. Different `M.m` means a different user
interface and a different feature set, so the distinction matters to
them. Within their chosen series they always want the release with the
fewest known bugs, i.e. the highest `d`: `1.2.2`, not `1.2.0`.

So `1.2` must be a *moving* reference: it means `1.2.0` today, `1.2.1`
next month, `1.2.2` after that — always the newest frozen release of
the series.

> **The series is a contract, not a feature list.** `1.2` promises
> everything `1.2.0` promised, still there and still working. What a
> user actually *receives* is the content of the newest frozen `1.2.d`,
> which may hold fixes (`f2.1`) and internal additions (`f5`) that
> `1.2.0` did not. Saying "1.2 has f1, f2, f3, f4" and "1.2 is the
> newest 1.2.d" at the same time is the ambiguity this rule settles.

### 1.3 Track maintenance branching

Once `1.2.0` is frozen, work towards `1.3.0` starts. But before `1.3.0`
is ready, the users of `1.2` may need corrections — `1.2.1`, `1.2.2` —
which must not drag in the unreleased `1.3` work.

**Sequential development.** When nobody is waiting on the older series,
every release is cut from the trunk in a line:

```
1.1.0 → 1.2.0 → +f2.1 → +f5 → +f3.1 → +f6 = 1.3.0
```

Some of those intermediate points may be released as `1.2.1`, `1.2.2`.
There is no branching, and none is needed.

**Parallel development.** When 1.2 users need fixes while 1.3 is being
built, the two lines run side by side and the fixes are merged forward:

```
1.2.0 ──── +f2.1 = 1.2.1 ──── +f5 +f3.1 = 1.2.2         (maintenance)
   └────── +f6 ─────────────── merge ─────────── = 1.3.0 (trunk)
```

A change that belongs to both lines is written once and merged into
each — never written twice.

## 2. The three kinds of ref

| Role | Name | Git object | Moves? | Commits land on it? |
|---|---|---|---|---|
| Frozen release | `release-M.m.d` | **annotated tag** | never | — |
| Frozen pre-release | `release-M.m.d-rcN` | **annotated tag** | never | — |
| Series pointer | `version-M.m` | branch | onto release commits only | **never** |
| Major pointer | `version-M` | branch | onto release commits only | **never** |
| Trunk | `master` | branch | freely | yes |
| Maintenance line | `maint-M.m` | branch | freely | yes |
| Named development line | `dev-M.m` | branch | freely | yes |
| Work branch | `fix-<slug>`, `feat-<slug>` | branch | freely | yes |

### 2.1 Why a release is a tag

A release must be immutable. A branch moves by construction — every
commit made while it is checked out moves it — so a branch can express
"the tip of a line", never "a frozen feature set". A tag can.

The name `release-M.m.d` is chosen to match what GitLab and GitHub call
a Release: both create a Release *from a tag*, and the tag's name is the
release's identity. `glab release create release-1.6.11` needs no
translation table.

### 2.2 Why a pointer is a branch, not a moving tag

`version-M.m` must move: that is its job (§1.2). It could in principle
be a tag that gets re-pointed, but that breaks consumers — `git fetch`
does **not** update a tag that already exists locally, so a user who
fetched `1.2` last month would silently keep the old one forever.
Branches update on fetch, work with `git clone -b version-1.2`, and are
what forge UIs list as switchable refs.

What keeps a pointer honest is therefore a rule, not the ref type:

> **P1.** `version-M.m` and `version-M` are *pointers*. Nothing is ever
> committed on them. They are only ever moved onto a commit that carries
> a `release-*` tag.

Checking out a pointer must always yield a released state.

### 2.3 Why development lines are named separately

`maint-M.m` and `dev-M.m` are where work happens: they move, commits
land on them, they may be rebuilt or abandoned. Naming one `release-…`
or `version-…` would make a ref mean two things at once — which is how
a "frozen" release branch ends up 31 commits past its own release.

- `master` is the trunk, the default development line.
- `dev-M.m` names a development line for an unreleased version, used
  when more than one future is in flight (e.g. `dev-2.0` beside a trunk
  still shipping 1.7), or simply when the target is worth naming.
- `maint-M.m` is created **on demand** at the newest `release-M.m.d`,
  when a fix must ship for a frozen series. Most series never need one.

### 2.4 Work branches: `fix-*` and `feat-*`

Every change — a bug fix, a feature — is written on its own short-lived
branch and merged when it is done:

- `fix-<slug>` — corrects a defect.
- `feat-<slug>` — adds or changes a feature.

The point is not ceremony. It is that **you rarely know at the start
which line a change belongs to**, and a separate branch lets you decide
at the end, once you know what the change actually turned out to be:
this fix ships in `1.2.3`, that feature waits for `1.3.0`, and this
other one is needed by both.

> **W1. Fork from the oldest line that could need it** — normally the
> line where the defect was found. Merging *forward* (older line into
> newer) is always safe; merging *backward* (newer into older) drags
> unreleased work into a frozen series and is forbidden (§5.4). A branch
> forked from `dev-1.3` can never be merged into `maint-1.2`.

> **W2. One concern per branch.** If, while fixing a bug, you discover
> you need a feature, do not put it in the `fix-` branch: fork a
> `feat-` branch from the same base and let the `fix-` branch merge it.
> The two may have different destinations, and once they are in one
> commit series that choice is gone.

> **W3. Merge, then delete.** A work branch is deleted once merged
> everywhere it belongs. Only the lines and the tags are permanent.

Rule R2 (§3) still governs what a maintenance release may contain: a
`feat-` branch may be merged into `maint-M.m` only when a fix released
from it needs that feature.

## 3. Version numbers

`M.m.d` — major, minor, development.

| Digit | Increment when | Then |
|---|---|---|
| `M` | An **incompatible** change: the user must adapt | `m = 0`, `d = 0` |
| `m` | The **user-visible feature set** changes compatibly (feature added, changed, removed) | `d = 0` |
| `d` | Bug fixes, and changes with **no user-visible effect** | — |

- **R1.** `d` increases monotonically within a series. Contiguity is
  *not* required: `1.6.0` may be followed by `1.6.11`. A project may
  therefore couple `d` to some internal counter, or simply increment it.
- **R2.** A `release-M.m.d` may contain new code that is not
  user-visible **only when that code is needed by a fix being released**.
  A new internal module that no fix in this release needs belongs on a
  development line, heading for the next `m`.
- **R3.** The series `M.m` is a compatibility contract, not a feature
  list (§1.2).

### 3.1 Programs versus the release

A release may ship several programs, each with its own version.

- **R4.** Program versions are an independent axis. A program's own
  counter is bumped by its own rules, whenever its sources change.
- **R5.** A program shipped in `release-M.m.d` and changed within that
  series must have `A.B = M.m`. A program that has *not* changed may
  stay at an older `A.B` and still ship.
- **R6.** Programs are not tagged separately: a program version is read
  from its source, and the release tag is the only mark on the history.

### 3.2 Deprecated naming

Projects that previously marked releases `vM.m.d`, or tagged programs
`<program>-vA.B.C`, keep those tags: they are published immutable refs
and deleting them breaks whoever fetched them. **Both formats are
deprecated — create no new ones.** New releases use `release-M.m.d`,
and program versions live in the sources (R6).

## 4. Invariants

Auditable, in the order a checker should report them.

- **I1.** Every `release-*` ref is an annotated tag. No branch may be
  named `release-*` — the namespace is reserved for tags.
- **I2.** A release tag is never moved and never deleted.
- **I3.** Within a series, releases are totally ordered by ancestry:
  for `d₁ < d₂`, `release-M.m.d₁` is an ancestor of `release-M.m.d₂`.
- **I4.** **Across series, no ancestry is required.** `release-1.3.1`
  need not be an ancestor of `release-1.4.0`: a maintenance release cut
  in parallel with trunk development is precisely the case §1.3 is about.
- **I5.** `version-M.m` points *exactly at* the newest `release-M.m.d`
  — equality, not "contains". Likewise `version-M` points exactly at the
  newest release of the highest series of that major.
- **I6.** If `maint-M.m` exists, it is a descendant of the newest
  `release-M.m.*` and contains all of them.
- **I7.** Every release tag is reachable from `master` or from some
  `maint-*` / `dev-*` line. No release is orphaned.
- **I8.** No commit reachable from `master` reports a version that a
  release tag has already frozen (the post-release bump, §5.1, landed).

Pre-release tags (`-rcN`) are ignored by I3, I5 and I8.

## 5. Procedures

### 5.1 Release from a line

1. The line must be green: `master` for a trunk release, `maint-M.m`
   for a maintenance release, `dev-M.m` for a named development line.
2. Bump the shipped programs' version stamps as needed (R5).
3. Update the release notes.
4. Commit: `<project> M.m.d: <summary>`.
5. `git tag -a release-M.m.d -m "<project> M.m.d: <summary>"`.
6. Fast-forward the pointers onto the tagged commit:
   `git push origin <line> release-M.m.d <sha>:refs/heads/version-M.m <sha>:refs/heads/version-M`
   (create `version-M.m` here if this is `d = 0`; move `version-M` only
   if this is the newest series of that major).
7. **Post-release bump:** immediately bump the version stamps on the
   line to the next development value, so no untagged commit ever claims
   a released version (I8).
8. Create the forge Release from the tag `release-M.m.d`.

### 5.2 Start a new minor or major

Same as §5.1 with `d = 0`, plus: create `version-M.m` at the tag. The
previous series' pointer stays where it is — it keeps serving the users
who chose that series.

### 5.3 Open a maintenance line

When a fix must reach the users of a frozen series without shipping
unreleased work:

```
git branch maint-M.m release-M.m.d      # at the newest release of the series
```

Then work through `fix-*` / `feat-*` branches forked from it (§2.4) and
release with §5.1.

### 5.4 Merge direction

**Forward only.** A change flows from the oldest line that needs it
towards the newest:

```
fix-*/feat-*  →  maint-1.2  →  master (or dev-1.3)
```

Never the reverse: merging `master` into `maint-1.2` would pull
unreleased feature work into a frozen series and break R2. If a
maintenance line needs something that only exists on the trunk, that
something is not ready to ship in a maintenance release — or it must be
extracted onto its own `feat-` branch forked from the maintenance line.

### 5.5 Retire a series

Stop releasing it. `version-M.m` stays where it is, frozen in practice
because no new `M.m.d` will ever appear. Nothing is deleted: the pointer
remains a valid, working reference to the last good release of that
series.

## 6. Audit

`make check-versions` (`scripts/check-versions.sh`) verifies the
machine-checkable invariants — **I1, I3, I5, I6, I7** — against the
local repository and its `origin` refs, and exits non-zero if any is
violated. Run `git fetch --prune --tags` first, then run it after any
release and in CI.

The remaining three are policy, not topology, and are enforced by
review: **I2** (a tag was never moved) can only be judged against what
consumers already fetched; **I4** is a permission, not a requirement;
**I8** depends on where each project keeps its version stamps.

## 7. Worked example

1.2 is frozen and has users; 1.3 is in development. A small bug is
reported against 1.2, and fixing it turns out to need a new internal
module — which the 1.3 work will need too.

```
                    ┌── feat-needed-for-small-bug ──┐
                    │            └── fix-small-bug ─┤
maint-1.2 ──────────┴───────────────────────────────┴── merge ── release-1.2.3
                    │
dev-1.3 ────────────┴── merge feat-needed-for-small-bug ── … ── release-1.3.0
```

Step by step:

1. The bug was found in 1.2, so `maint-1.2` is the oldest line that
   needs the work: `git branch maint-1.2 release-1.2.2` if it does not
   exist yet, then `git branch fix-small-bug maint-1.2` (W1).
2. Fixing it turns out to need a feature. It does not go into the fix
   branch: `git branch feat-needed-for-small-bug maint-1.2`, and
   `fix-small-bug` merges it to build on it (W2).
3. It becomes clear that the same feature is needed for other 1.3 work.
   Nothing has to be rewritten or cherry-picked — the feature is already
   on its own branch, forked from a base both lines share.
4. Route each branch to its destination:
   - `maint-1.2` ← `feat-needed-for-small-bug`, then `fix-small-bug`.
     The feature is admissible in a maintenance release because the fix
     released with it needs it (R2).
   - `dev-1.3` ← `feat-needed-for-small-bug` only. The fix reaches 1.3
     through the later `maint-1.2` → `dev-1.3` merge, or directly if 1.3
     needs it sooner.
5. Release `release-1.2.3` from `maint-1.2` (§5.1); `version-1.2` moves
   onto it, and 1.2 users get the fix. `version-1` does not move — 1.3
   is not out yet.
6. Delete both work branches (W3).

Had the fix been forked from `dev-1.3` instead, none of this would be
possible: merging it back into `maint-1.2` would have carried every
unreleased 1.3 commit with it. That is the whole reason for W1.
