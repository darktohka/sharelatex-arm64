#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OVERLEAF_DIR="$REPO_DIR/overleaf"
PATCHES_DIR="$REPO_DIR/patches"
OVERLEAF_REPO="https://github.com/overleaf/overleaf.git"
BRANCH="patched"

cd "$REPO_DIR"

if [ ! -d "$OVERLEAF_DIR/.git" ]; then
    echo "Cloning overleaf/overleaf..."
    git clone "$OVERLEAF_REPO" "$OVERLEAF_DIR"
fi

cd "$OVERLEAF_DIR"

echo "Fetching latest from origin..."
git fetch origin

echo "Switching to main branch..."
git checkout main
git reset --hard origin/main

echo "Removing existing '$BRANCH' branch if present..."
git branch -D "$BRANCH" 2>/dev/null || true

echo "Creating new branch '$BRANCH'..."
git checkout -b "$BRANCH"

git config user.email "patches@local"
git config user.name "Patches"

echo "Applying patches..."
shopt -s nullglob
patches=("$PATCHES_DIR"/*.patch)
if [ ${#patches[@]} -eq 0 ]; then
    echo "No patches found in $PATCHES_DIR"
    exit 0
fi

for patch in "${patches[@]}"; do
    echo "  Applying $(basename "$patch")..."
    if ! git am --3way < "$patch"; then
        echo "ERROR: Failed to apply patch: $patch"
        echo "Run 'git am --abort' to clean up, then fix the patch and try again."
        exit 1
    fi
done

echo ""
echo "All patches applied successfully on branch '$BRANCH'."
echo "The overleaf directory at $OVERLEAF_DIR is ready."
