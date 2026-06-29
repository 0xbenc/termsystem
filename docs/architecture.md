# termsystem — architecture & reference

The low-level companion to the [README](../README.md). It documents each module's
API surface and scope, the dependency graph, the release lifecycle, the
conformance invariants, and the current version matrix.

## Dependency graph

```
termtheme (leaf; no bubbletea)        termintro (leaf; pure stdlib, no deps)
   ├──► termnav   (+ bubbletea in teax/source subpkgs)
   └──► termchrome (termtheme only; no bubbletea)
                         │
   termtheme, termnav, termchrome, termintro  ──►  passage · ssherpa · dangit
```

- **termtheme** and **termintro** are independent leaves.
- **termnav** and **termchrome** depend on **termtheme** only.
- The three apps depend on all four.
- Pins are **semver, no `replace`** in released `go.mod`. Because a consumer can
  only build against a tag already on the module proxy, the tag order is enforced
  mechanically (see Release lifecycle).

## Modules

### termtheme — the interchange core (pure, no bubbletea)

The one layer that *must* agree for themes to interchange across apps.

- **Roles** — semantic SGR slots (`RoleTitle`, `RolePrimary`, `RoleBorder`,
  `RoleSelected`, `RoleSelectedBar`, `RoleSearch`, …). `Roles()` is the universal
  superset. Roles name *meaning*, not color.
- **Theme** — `{Name, NoColor, Codes map[Role]string}`; `theme.Style(role, s)`.
- **ThemeConfig** + `.theme` format — `ParseThemeConfig`, `ParseStyleSpec`,
  `Marshal`/`Unmarshal` (portable, versioned, cross-app).
- **Render helpers** — `Apply`, `VisibleWidth`, `Strip`, `Sanitize`, `PadRight`,
  `Truncate`, `TruncateWith` (cell-accurate, grapheme-safe).
- **Env/path helpers** (app-parameterized) — `EnvMap`, `ExpandPath`, `EnvTruthy`,
  `ResolveThemeFile(app, …)`, `EnvNoColor(app, …)`.
- **Stays app-local:** builtin palettes (`TerminalTheme`/`VividTheme` — brand),
  and each app's fail-open `ResolveTheme` orchestration. termtheme ships *no*
  palettes by design.

### termnav — navigation, fuzzy, highlight

- **Window engine** — `WindowContainsCursor`, `ClampWindow`, `JumpSection`,
  `Snap` (variable-height lists with groups + overflow markers). Top-level
  package is **stdlib-only**.
- **Fuzzy matcher** — `MatchFuzzy(query, candidate) (Result, bool)` (raw
  subsequence + score + positions); `Fuzzy{}` adds a per-rune relevance floor.
- **`render.HighlightMatches(display, positions, width, base, hl)`** — the shared
  match-highlight algorithm (subpackage `render`, which imports termtheme).
- **`teax` / `source`** — the Bubble Tea harness + filesystem source (these
  subpackages pull bubbletea; the core matcher/window funcs do not).

### termchrome — chrome widgets (termtheme only, no bubbletea)

Pure string rendering over a `termtheme.Theme`.

- **Box geometry** — `Edge`/`Top`/`Bottom`/`Divider`/`Line`, with a **`Truncator`
  seam**: the caller passes its own overflow policy (Sanitize for trusted chrome,
  Strip for raw transcript) so the geometry is shared but the policy stays local.
- **`Footer([]KeyHint, width)` + `FooterSep` (`" / "`)** — the canonical key-hint
  grammar with progressive `+N` overflow.
- **`KVRow`** — aligned `label   value` rows.
- **`GlyphSet` / `ResolveGlyphs(env)` / `Frame(n)`** — locale-aware spinner +
  progress-bar cells (braille on UTF-8, ASCII fallback).
- **`Bar` / `UrgencyRole`** — progress bar + countdown color ramp.
- **Stays app-local:** the shell *composition* (e.g. `renderWorkflowShell` and any
  wizard step-rail) and the `Truncator` policy.

### termintro — boot animation (pure stdlib)

- `Play(Options)` — runs the animation on the alternate screen and restores on
  exit; Ctrl-C skips. `Snapshot(...)` renders one frame (for tests/preview).
- `Options{Title, Tagline, Credits []string, Version, Speed, Hold, FPS, Output
  io.Writer, NoColor}`. Unset numeric fields default via `withDefaults` (notably
  `Hold` → the "boil" beat). **Credits** render on the second-to-last road band,
  **Version** on the bottom band. Hosts pass `Output: os.Stderr`.

## The apps (consumer shape)

All three: depend on the four libs (lockstep versions, no `replace`); keep their
domain model, builtin palettes, and shell composition local; theme via termtheme;
list/fuzzy/highlight via termnav; chrome/footer/spinner via termchrome; and play
the termintro intro once per version (TTY-gated, render to stderr) with
`--intro`/`--no-intro` + `<APP>_INTRO_ALWAYS`/`<APP>_NO_INTRO` toggles and a
per-app last-seen-version record in local state.

- **passage** — secret manager; an async-action picker over a GNU Pass store.
- **ssherpa** — SSH manager; a home picker that launches supervised PTY sessions
  (its live-overlay keeps a `Strip` transcript policy).
- **dangit** — git-repo sweeper; a scan→browse model with a resolve action.

## Release lifecycle

Tag **bottom-up**, develop with a local `replace`, then pin the tag:

```sh
# in the module: implement, then
go mod tidy                          # ONLINE, before any tag
gofmt -l . && go vet ./... && go test ./... && go test -race ./...
git commit … ; git push origin main
git tag -a vX.Y.Z -m "…" ; git push origin vX.Y.Z   # proxy-resolvable before consumers pin

# in each consumer (one commit each):
go get github.com/0xbenc/<mod>@vX.Y.Z
go mod edit -dropreplace=github.com/0xbenc/<mod>
go mod tidy && go test ./...
git commit -m "<app>: pin <mod> vX.Y.Z (drop local replace)"
```

Order: `termtheme`/`termintro` → `termnav`/`termchrome` → apps. **No `replace`
survives into a released `go.mod`** (goreleaser `go mod verify` enforces it).
**Pin lockstep:** passage, ssherpa, and dangit pin identical lib versions.

## Conformance invariants

- Footers flow through `termchrome.Footer` (no hand-built separators).
- Spinners/progress use `termchrome.ResolveGlyphs` (no inline frame literals).
- Theming via termtheme roles + the `.theme` format; env/path via termtheme's
  app-parameterized helpers; builtin palettes stay per-app.
- Fuzzy via termnav; highlight via `render.HighlightMatches`.
- Box chrome via termchrome with an injected `Truncator`; **trusted chrome
  Sanitizes**, **raw transcript Strips** — never the reverse.
- Tests use **inline string-literal expectations** + width/security invariants
  (`assertBorderIntegrity`, Sanitize-on-overflow). **No `-update`/golden harness.**
- Each app's CI runs a `tui-conformance` job enforcing the above.

## Version matrix (current)

| termtheme | termnav | termchrome | termintro | passage | ssherpa | dangit |
|---|---|---|---|---|---|---|
| v0.2.0 | v0.2.0 | v0.1.0 | v0.1.1 | v0.8.1 | v1.20.1 | v0.2.0 |

> Keep this table current when cutting releases (it's the quickest lockstep check).
