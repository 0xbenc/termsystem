#!/usr/bin/env bash
# Clone (or update) every termsystem member repo into this directory, so
# termsystem can be used as a single workspace root / cwd for an AI agent.
# The checkouts are gitignored — each stays its own independent repo.
set -euo pipefail

repos=(termtheme termnav termchrome termintro passage ssherpa dangit)
base="${TERMSYSTEM_GIT_BASE:-git@github.com:0xbenc}"

cd "$(dirname "$0")"
for r in "${repos[@]}"; do
  if [ -d "$r/.git" ]; then
    echo "==> $r: updating"
    git -C "$r" pull --ff-only
  else
    echo "==> $r: cloning"
    git clone "$base/$r.git" "$r"
  fi
done
echo "done — $(printf '%s ' "${repos[@]}")"
