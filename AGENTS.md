# AGENTS.md — operating manual for the termsystem ecosystem

You are a development agent working in **termsystem**, the shared terminal-UI
ecosystem behind a family of Go TUIs. This file tells you how to work here so the
apps stay aligned and you don't reintroduce the duplication the ecosystem exists
to remove. It's written for the maintainer's agent, but it's the same rules for
anyone — follow it regardless of who you're working for.

If you read nothing else: **adopt the shared modules, never re-implement them.**
When in doubt, read [`README.md`](README.md) (the map) and
[`docs/architecture.md`](docs/architecture.md) (the deep reference).

## 1. The workspace

This directory is both the ecosystem lander and a workspace root. The member
repos are cloned in as **gitignored subdirectories** (run `./clone-all.sh` if
they're missing), each its own independent git repo:

```
termsystem/            ← you are here (cwd); tracks only the docs
├─ termtheme/  termnav/  termchrome/  termintro/   ← shared libraries
└─ passage/    ssherpa/  dangit/                   ← TUIs
```

Edits happen **inside a member repo's directory**. termsystem itself only holds
docs — don't put app/library code here.

## 2. The map (what each repo is, and what stays local)

**Libraries** (pin via semver, no `replace`):

- **termtheme** — semantic SGR *roles* + the portable `.theme` format + render
  helpers (`Apply`/`VisibleWidth`/`Strip`/`Sanitize`/`PadRight`/`Truncate`) +
  app-parameterized env/path helpers (`EnvMap`/`ExpandPath`/`EnvTruthy`/
  `ResolveThemeFile`/`EnvNoColor`). Pure, no Bubble Tea. *Local to each app:*
  builtin palettes (brand) + the fail-open `ResolveTheme`.
- **termnav** — list-windowing engine + the fuzzy `MatchFuzzy`/`Fuzzy{}` matcher
  + `render.HighlightMatches`. *Local to each app:* the domain model/rows.
- **termchrome** — box geometry (`Edge`/`Top`/`Bottom`/`Divider`/`Line` + a
  `Truncator` seam), `Footer`/`KeyHint`/`FooterSep`, `KVRow`, `GlyphSet`/
  `ResolveGlyphs`/`Frame`, `Bar`/`UrgencyRole`. *Local to each app:* shell
  composition + the overflow `Truncator` policy.
- **termintro** — the boot animation: `Play(Options{…})` / `Snapshot`. Pure stdlib.

**TUIs** (consume all four libs in lockstep):

- **passage** — GNU Pass secret manager (async-action picker).
- **ssherpa** — SSH manager (home picker → supervised PTY sessions; the live
  overlay keeps a `Strip` transcript policy).
- **dangit** — git-repo sweeper (scan → browse → resolve).

Dependency graph and the STYLE-vs-FLOW two-layer model: see
[`docs/architecture.md`](docs/architecture.md).

## 3. Conformance rules — ALWAYS / NEVER

These are enforced by each app's `tui-conformance` CI job and by review. Breaking
one is a regression, not a style preference.

**ALWAYS**
- Render footers via `termchrome.Footer([]termchrome.KeyHint{…})` (keyed struct
  fields — `go vet` rejects unkeyed literals of an imported type).
- Render spinners/progress via `termchrome.ResolveGlyphs(env).Frame(n)` / `Bar`.
- Theme via termtheme roles; resolve env/paths via termtheme's `…(app, …)`
  helpers; keep builtin palettes per-app.
- Fuzzy-filter via `termnav.MatchFuzzy` (or `Fuzzy{}`); highlight matches via
  `render.HighlightMatches`.
- Draw bordered chrome via termchrome, passing the app's own `Truncator`:
  **trusted chrome → `Sanitize`**, **raw remote/transcript text → `Strip`**.
- Gate the intro to an interactive TTY (check stderr), render it to `os.Stderr`,
  show it once per version (record last-seen in app state), and honor
  `--intro`/`--no-intro` + `<APP>_INTRO_ALWAYS`/`<APP>_NO_INTRO`.
- Before pushing, run `gofmt -l .`, `go vet ./...`, `go test ./...`,
  `go test -race ./...` — green, in the repo you changed.

**NEVER**
- Re-implement anything a shared module provides (theme resolution, the fuzzy
  matcher, box geometry, footer grammar, spinner frames, the intro). If you find
  a local copy, delete it and call the module.
- Hand-build a footer separator (no `  /  `, no `·`-joined strings) or inline
  spinner frames (no `[]rune{'|','/','-','\\'}`, no inline braille slice).
- Add a `-update`/`UPDATE_GOLDEN` golden harness — goldens are inline string
  literals, edited by hand. (`assertBorderIntegrity` + Sanitize-on-overflow are
  the invariants.)
- Leave a `replace` directive in a released `go.mod`.
- Swap a raw-transcript path to `Sanitize` or a trusted-chrome path to `Strip`.

## 4. Playbooks

**Change shared STYLE (a color role, footer, box, spinner, intro):** edit the
*module*, not the app. Then release it and re-pin the consumers (below). Don't
fork the behavior into one app.

**Change a shared library:** develop against local consumers, then release
bottom-up. Tag order is `termtheme`/`termintro` → `termnav`/`termchrome` → apps.

```sh
# in <module>/: implement
go mod tidy && gofmt -l . && go vet ./... && go test ./... && go test -race ./...
# wire each consumer to the local checkout while iterating:
#   (in the app)  go mod edit -replace=github.com/0xbenc/<mod>=../<mod>
# get all consumers green, THEN:
git -C <module> push origin main
git -C <module> tag -a vX.Y.Z -m "…" && git -C <module> push origin vX.Y.Z
# pin each consumer (one commit each), dropping the replace:
go get github.com/0xbenc/<mod>@vX.Y.Z
go mod edit -dropreplace=github.com/0xbenc/<mod>
go mod tidy && go test ./...   # commit: "<app>: pin <mod> vX.Y.Z (drop local replace)"
```

Keep passage, ssherpa, dangit on **identical** lib versions (lockstep). Update
the version matrix in `docs/architecture.md` when you cut releases.

**Add a feature to an app:** keep the domain logic local; reach for the shared
modules for anything UI (theme/list/chrome/intro). Match the surrounding code's
style and the conformance rules above.

**Add a NEW TUI to the family** (the rule of the ecosystem):
1. Depend on all four libs; theme via termtheme, list/fuzzy via termnav, chrome/
   footer/spinner via termchrome, and play the termintro intro.
2. Keep a thin `internal/termstyle` shim re-exporting termtheme roles/helpers +
   the app's builtin palettes (mirror an existing app).
3. Gate + persist the intro once-per-version (mirror `dangit/internal/state`).
4. Add the `tui-conformance` CI job and a CONTRIBUTING "shared TUI stack &
   drift guards" section (copy from any app).
5. Add it to this ecosystem's README + architecture doc.

## 5. Commands

```sh
# build/test a repo (run inside it)
gofmt -l . ; go vet ./... ; go test ./... ; go test -race ./...

# reproduce the conformance guard locally (run inside an app)
grep -rn '  /  ' internal                       # → empty
grep -rnE "⠋|\[\]rune\{'\|'" internal cmd        # → empty
grep -cE '^replace ' go.mod                      # → 0

# preview the intro for an app's branding
go run github.com/0xbenc/termintro/cmd/termintro \
  --snapshot 3.9 --title APP --credits 0xbenc --version v1.2.3
```

When a tag is brand-new and the public proxy/sumdb hasn't indexed it yet, fetch
direct: `GOPRIVATE=github.com/0xbenc/* GOPROXY=direct go get …@vX.Y.Z`.

## 6. Git & release conventions

- Work on a branch; open a PR into `main`; **CI must be green before merge**
  (the `tui-conformance` job included). The maintainer may grant direct-to-main
  on specific repos — otherwise default to PRs.
- Releases are git tags that trigger goreleaser. Cut them only after `main` CI is
  green; tags are immutable once pushed.
- Commit messages: imperative subject, a short body explaining *why*. End with:
  `Co-Authored-By: <your agent/model> <noreply@…>`.
- Don't commit the gitignored member checkouts to termsystem.

## 7. Gotchas

- **`go vet` after any footer edit** — unkeyed `KeyHint{…}` literals fail vet but
  not `go test`; always run vet.
- **termintro `Hold`** — leave it `0` to get the default "boil"; the apps rely on
  that default.
- **Fresh-tag CI** — the first build after a new public tag may need a beat for
  the proxy/sumdb to index it.
- **`go test` is not enough** before pushing — run gofmt + vet + `-race` too;
  that's what CI runs.
