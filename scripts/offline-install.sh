#!/usr/bin/env bash
#
# Offline / air-gapped install of CodeGraph from this source folder.
#
# Assumes the client workstation has:
#   - Node.js (>=18 <25) and npm on PATH
#   - npm configured against a registry it CAN reach (e.g. a private mirror)
#   - No git, no public GitHub access required
#
# Does NOT call git, does NOT download anything from github.com. Dependencies
# are pulled from whatever registry npm is already pointed at.
#
# Usage:
#   ./scripts/offline-install.sh                    # build, link, wire Claude Code
#   ./scripts/offline-install.sh --skip-claude      # build + link only
#   ./scripts/offline-install.sh --undo             # unlink the global symlink
#
# After install:  `codegraph --version` should print the package.json version.

set -euo pipefail

cd "$(dirname "$0")/.."
REPO="$(pwd)"

PKG=$(node -p "require('./package.json').name")
VERSION=$(node -p "require('./package.json').version")

# --- undo path ---------------------------------------------------------------
if [ "${1:-}" = "--undo" ]; then
  echo "[offline-install] unlinking ${PKG}"
  npm unlink -g "${PKG}" >/dev/null 2>&1 || true
  echo "[offline-install] done"
  exit 0
fi

SKIP_CLAUDE=0
[ "${1:-}" = "--skip-claude" ] && SKIP_CLAUDE=1

# --- Node version gate (matches package.json engines) ------------------------
NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]")
if [ "$NODE_MAJOR" -lt 18 ] || [ "$NODE_MAJOR" -ge 25 ]; then
  echo "[offline-install] error: Node $NODE_MAJOR is unsupported. Requires >=18 <25." >&2
  exit 1
fi

echo "[offline-install] repo:    ${REPO}"
echo "[offline-install] package: ${PKG}@${VERSION}"
echo "[offline-install] node:    $(node --version)"
echo "[offline-install] registry: $(npm config get registry)"

# --- install deps (offline-friendly: respects whatever registry npm is on) ---
if [ -f package-lock.json ]; then
  echo "[offline-install] npm ci"
  npm ci
else
  echo "[offline-install] npm install"
  npm install
fi

# --- build -------------------------------------------------------------------
echo "[offline-install] npm run build"
npm run build

# --- link as global codegraph ------------------------------------------------
echo "[offline-install] npm link"
npm link

LINKED=$(command -v codegraph || echo "(not on PATH)")
echo "[offline-install] codegraph -> ${LINKED}"

# --- wire Claude Code (non-interactive) --------------------------------------
# Invoke the just-built binary directly instead of relying on `codegraph` being
# visible on PATH in this shell session — `npm link`'s shim may not be picked
# up until the user opens a new shell.
if [ "$SKIP_CLAUDE" -eq 0 ]; then
  echo "[offline-install] wiring Claude Code"
  node "$REPO/dist/bin/codegraph.js" install --target claude -y
fi

cat <<EOF

✓ CodeGraph ${VERSION} installed offline from source.
  binary:    ${LINKED}
  source:    ${REPO}

Next:
  codegraph --version
  cd <your-project> && codegraph init && codegraph index

To uninstall:
  ./scripts/offline-install.sh --undo
EOF
