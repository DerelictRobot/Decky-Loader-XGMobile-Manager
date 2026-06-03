#!/bin/bash
set -e

# Builds the sideloadable release artifact: xgmobile-manager.zip
# Layout is FLAT (dist/, bin/, ... at the zip root) because bin/install.sh extracts
# the zip directly into ~/homebrew/plugins/xgmobile-manager/.

# Pick a package manager: prefer pnpm (Decky standard), fall back to npm.
if command -v pnpm >/dev/null 2>&1; then
  PM="pnpm"
elif command -v npm >/dev/null 2>&1; then
  PM="npm"
else
  echo "ERROR: neither pnpm nor npm found on PATH." >&2
  exit 1
fi
echo "Using package manager: $PM"

# 1. Cleanup old builds
echo "Cleaning up old builds..."
rm -rf dist deploy_staging
rm -f xgmobile-manager.zip

# 2. Build the frontend (React -> dist/index.js)
echo "Building React frontend..."
"$PM" install
"$PM" run build

# 3. Stage the runtime files (explicit dest paths, no nesting surprises)
echo "Staging files for release..."
mkdir -p deploy_staging/assets deploy_staging/dist
cp dist/index.js         deploy_staging/dist/index.js   # ship the bundle only, not the sourcemap
cp -r bin                deploy_staging/bin
cp -r assets/services    deploy_staging/assets/services
cp decky.pyi             deploy_staging/
cp main.py               deploy_staging/
cp plugin.json           deploy_staging/
cp package.json          deploy_staging/
cp LICENSE               deploy_staging/ 2>/dev/null || true
cp README.md             deploy_staging/ 2>/dev/null || true

# 4. Fix permissions (the bin/ scripts must stay executable on-device)
echo "Setting executable permissions for scripts..."
chmod +x deploy_staging/bin/*

# 5. Zip from inside the staging dir so paths are at the archive root
echo "Packaging into xgmobile-manager.zip..."
( cd deploy_staging && zip -rq ../xgmobile-manager.zip . )

# 6. Cleanup staging
rm -rf deploy_staging

echo "----------------------------------------"
echo "Build Complete: xgmobile-manager.zip"
echo "----------------------------------------"
