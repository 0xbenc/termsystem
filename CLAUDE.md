# CLAUDE.md

This project's agent instructions live in **[`AGENTS.md`](AGENTS.md)** — the
operating manual for the termsystem ecosystem (the shared `term*` libraries and
the `passage` / `ssherpa` / `dangit` TUIs). It is the single source of truth;
this file just points Claude Code at it so the rules don't drift between two
copies.

@AGENTS.md

Quick reminders (the full rules + playbooks are in `AGENTS.md`):

- This dir is a workspace root; the member repos are gitignored subdirs
  (`./clone-all.sh`). Edit code **inside** a member repo, never in `termsystem/`.
- **Adopt the shared modules; never re-implement them** — theme via `termtheme`,
  list/fuzzy/highlight via `termnav`, chrome/footer/spinner via `termchrome`,
  boot animation via `termintro`.
- Footers → `termchrome.Footer`; spinners → `termchrome.ResolveGlyphs`; trusted
  chrome `Sanitize`s, raw transcript `Strip`s; no `replace` in a released
  `go.mod`; goldens are inline literals (no `-update`).
- Before pushing: `gofmt -l .`, `go vet ./...`, `go test ./...`,
  `go test -race ./...` — all green. CI runs a `tui-conformance` job.
- Map + deep reference: [`README.md`](README.md), [`docs/architecture.md`](docs/architecture.md).
