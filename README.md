# termsystem

**The shared terminal-UI ecosystem behind [0xbenc](https://github.com/0xbenc)'s Go TUIs.**

A small family of focused Go modules — and the terminal apps that consume them —
built so every app *themes*, *renders*, *navigates*, and *opens* the same way.
Write once, share everywhere; a theme authored in one app renders identically in
the next, and a fix to a border or a fuzzy matcher lands for all of them at once.

This repo is two things:

1. **The ecosystem lander** — the map below, plus deeper docs.
2. **An agent workspace root** — clone the member repos in here (they're
   gitignored) and point your AI coding agent at this directory so it sees the
   whole ecosystem. See [`AGENTS.md`](AGENTS.md).

```sh
git clone git@github.com:0xbenc/termsystem.git
cd termsystem
./clone-all.sh        # clones the 7 member repos as gitignored subdirs
```

## The pieces

### Shared libraries

| Module | Role | Depends on | Latest |
|---|---|---|---|
| [**termtheme**](https://github.com/0xbenc/termtheme) | Semantic SGR **roles** + a portable `.theme` interchange format + render helpers (and pure env/path helpers). The must-agree core. | — (pure) | `v0.2.0` |
| [**termnav**](https://github.com/0xbenc/termnav) | File/namespace **navigation** + list-windowing engine, the fuzzy **matcher**, and match **highlighting**. | termtheme | `v0.2.0` |
| [**termchrome**](https://github.com/0xbenc/termchrome) | Opinionated **chrome widgets**: box geometry, canonical footer, key/value rows, locale-aware glyphs/spinner, countdown. | termtheme | `v0.1.0` |
| [**termintro**](https://github.com/0xbenc/termintro) | A Tron/ENCOM-style **boot animation** played once before a TUI's UI. | — (pure) | `v0.1.1` |

### TUIs

| App | What it does | Latest |
|---|---|---|
| [**passage**](https://github.com/0xbenc/passage) | GNU Pass as the source of truth, with a fast TUI for daily secret retrieval. | `v0.8.1` |
| [**ssherpa**](https://github.com/0xbenc/ssherpa) | The SSH config you already have, with a map and an escape rope. | `v1.20.1` |
| [**dangit**](https://github.com/0xbenc/dangit) | Find the git repos you forgot about — *dang it.* | `v0.2.0` |

## How it fits together

```
        termtheme ───────────────┐         termintro
        (roles + .theme,         │         (boot animation,
         pure, no bubbletea)     │          pure stdlib)
          ▲           ▲          │              │
          │           │          │              │
      termnav     termchrome     │              │
   (nav + fuzzy   (box/footer/   │              │
    + highlight)   glyphs)       │              │
          ▲           ▲          ▲              ▲
          └───────────┴────┬─────┴──────────────┘
                           │
              ┌────────────┼────────────┐
           passage      ssherpa       dangit
```

Two layers keep the apps aligned without making them identical:

- **STYLE is shared code.** Theme roles, box geometry, footers, glyphs, the
  fuzzy matcher, the intro — all live in the modules above, pinned by semver.
- **FLOW is a shared contract.** The interaction grammar (key bindings,
  selection cue, quit convention) lives in a written contract
  (`passage/docs/flow-contract.md`) that the apps translate into, not in code.

Each app keeps what is genuinely its own — its domain model, its builtin color
palettes (brand), its shell composition, and its overflow policy.

## Where to go next

- **Understand it (this page)** — the high-level map.
- **[`docs/architecture.md`](docs/architecture.md)** — the low-level reference:
  per-module API surface and scope, the dependency graph, the release lifecycle,
  the conformance invariants, and the version matrix.
- **[`AGENTS.md`](AGENTS.md)** — the operating manual for AI coding agents
  working anywhere in the ecosystem (conventions, conformance rules, workflows).
  `CLAUDE.md` defers to it.

## Install the apps

```sh
brew install --cask 0xbenc/tap/passage
brew install --cask 0xbenc/tap/ssherpa
brew install --cask 0xbenc/tap/dangit
# or: go install github.com/0xbenc/<app>/cmd/<app>@latest
```

The libraries are normal Go modules:

```sh
go get github.com/0xbenc/termtheme
go get github.com/0xbenc/termnav
go get github.com/0xbenc/termchrome
go get github.com/0xbenc/termintro
```

## License

MIT, per repo. See [`LICENSE`](LICENSE).
