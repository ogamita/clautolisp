# Version and release rules

Normative rules for version numbers, release marks, and branches.
Written to be reusable by any project, not only this one; a project
adopts it by reference and adds nothing but its own program list.

## 1. What versioning is for

1. **Identify a frozen feature set.** `1.2.0` names one exact set of
   features, forever. It is a fact about the past, not a moving target.
2. **Identify an evolving reference for users.** A user chooses the
   *series* `1.2` — a compatibility contract — and expects to receive
   the best release of that series available today, i.e. the one with
   the fewest known bugs: `1.2.2`, not `1.2.0`.
3. **Track maintenance branching.** Once `1.2.0` is frozen, work
   towards `1.3.0` continues, and *at the same time* `1.2.1`, `1.2.2`
   may have to be released to the users of `1.2` without dragging in
   the unreleased `1.3` work.

Goals 1 and 2 want *different kinds of ref*: one that can never move
and one whose whole purpose is to move. Goal 3 wants a third: a line
where commits actually land. Conflating any two of them is the mistake
this document exists to prevent.

## 2. The three kinds of ref

| Role | Name | Git object | Moves? | Commits land on it? |
|---|---|---|---|---|
| Frozen release | `release-M.m.d` | **annotated tag** | never | — |
| Frozen pre-release | `release-M.m.d-rcN` | **annotated tag** | never | — |
| Series pointer | `version-M.m` | branch | onto release commits only | **never** |
| Major pointer | `version-M` | branch | onto release commits only | **never** |
| Trunk | `master` | branch | freely | yes |
| Maintenance line | `maint-M.m` | branch | freely | yes |
| Parallel future line | `devel-M.m` | branch | freely | yes |
| Work branch | any other name | branch | freely | yes |

### 2.1 Why a release is a tag

A release must be immutable. A branch moves by construction — every
commit made while it is checked out moves it — so a branch can express
"the tip of a line", never "a frozen feature set". A tag can.

The name `release-M.m.d` is chosen to match what GitLab and GitHub
call a Release: both create a Release *from a tag*, and the tag's name
is the release's identity. `glab release create release-1.6.11` needs
no translation table.

### 2.2 Why a pointer is a branch, not a moving tag

`version-M.m` must move: that is its job (goal 2). It could in
principle be a tag that gets re-pointed, but that breaks consumers —
`git fetch` does **not** update a tag that already exists locally, so
a user who fetched `1.2` last month would silently keep the old one
forever. Branches update on fetch, work with `git clone -b version-1.2`,
and are what forge UIs list as switchable refs.

What keeps a pointer honest is therefore a rule, not the ref type:

> **P1.** `version-M.m` and `version-M` are *pointers*. Nothing is ever
> committed on them. They are only ever moved onto a commit that
> carries a `release-*` tag.

Checking out a pointer must always yield a released state.

### 2.3 Why maintenance is a third name

`maint-M.m` is where fixes for a frozen series are written. It is a
development line: it moves, commits land on it, it may be rebuilt or
abandoned. Naming it `release-…` or `version-…` would make the ref
mean two things at once — which is exactly how a "frozen" release
branch ends up 31 commits past its own release.

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
  user-visible **only when that code is needed by the fix being
  released**. A new internal module that no fix in this release needs
  belongs on the trunk, heading for the next `m`.
- **R3.** The series `M.m` is a compatibility contract, not a feature
  list: everything promised by `M.m.0` is still there in `M.m.d`. What
  a user *gets* from `version-M.m` is the content of the newest frozen
  `M.m.d`.

### 3.1 Programs versus the release

A release may ship several programs, each with its own version.

- **R4.** Program versions are an independent axis. A program's own
  counter is bumped by its own rules, whenever its sources change.
- **R5.** A program shipped in `release-M.m.d` and changed within that
  series must have `A.B = M.m`. A program that has *not* changed may
  stay at an older `A.B` and still ship.
- **R6.** Programs are not tagged separately. There are no
  `<program>-vA.B.C` tags: a program version is read from its source,
  and the release tag is the only mark on the history.

## 4. Invariants

Auditable, in the order a checker should report them.

- **I1.** Every `release-*` ref is an annotated tag. No branch may be
  named `release-*` — the namespace is reserved for tags.
- **I2.** A release tag is never moved and never deleted.
- **I3.** Within a series, releases are totally ordered by ancestry:
  for `d₁ < d₂`, `release-M.m.d₁` is an ancestor of `release-M.m.d₂`.
- **I4.** **Across series, no ancestry is required.** `release-1.3.1`
  need not be an ancestor of `release-1.4.0`: a maintenance release cut
  in parallel with trunk development is precisely the case goal 3 is
  about.
- **I5.** `version-M.m` points *exactly at* the newest `release-M.m.d`
  — equality, not "contains". Likewise `version-M` points exactly at
  the newest release of the highest series of that major.
- **I6.** If `maint-M.m` exists, it is a descendant of the newest
  `release-M.m.*` and contains all of them.
- **I7.** Every release tag is reachable from `master` or from some
  `maint-*` branch. No release is orphaned.
- **I8.** No commit reachable from `master` reports a version that a
  release tag has already frozen (the post-release bump, §5.1, landed).

Pre-release tags (`-rcN`) are ignored by I3, I5 and I8.

## 5. Procedures

### 5.1 Release from the trunk (sequential development)

The common case: no users are waiting on an older series.

1. `git checkout master` — the trunk must be green.
2. Bump the shipped programs' version stamps as needed (R5).
3. Update the release notes.
4. Commit: `<project> M.m.d: <summary>`.
5. `git tag -a release-M.m.d -m "<project> M.m.d: <summary>"`.
6. Fast-forward the pointers onto the tagged commit:
   `git push origin master release-M.m.d <sha>:refs/heads/version-M.m <sha>:refs/heads/version-M`
   (create `version-M.m` here if this is `d = 0`).
7. **Post-release bump:** immediately bump the trunk's version stamps
   to the next development value, so no untagged commit ever claims a
   released version (I8).
8. Create the forge Release from the tag `release-M.m.d`.

### 5.2 Start a new minor or major

Same as §5.1 with `d = 0`, plus: create `version-M.m` at the tag. The
previous series' pointer stays where it is — it keeps serving the users
who chose that series.

### 5.3 Open a maintenance line (parallel development)

When a fix must reach the users of a frozen series without shipping
unreleased trunk work:

1. `git branch maint-M.m release-M.m.d` at the newest release of the
   series (create it only when the need arises — most series never
   need one).
2. Write the fix there, respecting R2.
3. Release from `maint-M.m` following §5.1 steps 2–8, with `d`
   incremented within that series.

### 5.4 Propagate a maintenance fix to the trunk

**Merge, do not cherry-pick:**

```
git checkout master && git merge maint-M.m
```

This keeps I3/I7 intact and records that the fix is in both lines. The
reverse merge (master into `maint-M.m`) is forbidden: it would pull
unreleased feature work into a maintenance series and break R2.

### 5.5 Retire a series

Stop releasing it. `version-M.m` stays where it is, frozen in practice
because no new `M.m.d` will ever appear. Nothing is deleted: the
pointer remains a valid, working reference to the last good release of
that series.

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

The situation from which these rules were derived: 1.2 is frozen, 1.3
is in development, and 1.2 users need two fixes, the second of which
needs a new internal module `f5`.

```
master:   release-1.2.0 ─── +f6 ─────────── merge maint-1.2 ─── release-1.3.0
                  └── maint-1.2: +f2.1 ─── +f5 +f3.1
                                    │            │
                            release-1.2.1   release-1.2.2
```

- `release-1.2.0`, `release-1.2.1`, `release-1.2.2` — three frozen tags.
- `version-1.2` — walks 1.2.0 → 1.2.1 → 1.2.2 along `maint-1.2`. A user
  tracking `version-1.2` always has the best 1.2.
- `version-1` — walks to `release-1.3.0` when it is cut.
- `maint-1.2` — the only branch anyone commits to for that series.
- `f5` ships in 1.2.2 because the `f3.1` fix needs it (R2), and reaches
  the trunk through the merge (§5.4), not by being written twice.

In the sequential case the same releases exist, with no `maint-1.2`
and no merge: every release is cut from `master`.
