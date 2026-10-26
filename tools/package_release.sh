#!/bin/sh
# Lumen-OS Release Packager
# Produces a clean, hermetic distribution archive free of macOS AppleDouble metadata

set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT"

VERSION="v1.0.0"
OUTPUT_DIR="$REPO_ROOT/dist"
ARCHIVE_NAME="Lumen-OS-${VERSION}.zip"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"

echo "=== Packaging Lumen-OS $VERSION ==="

# 1. Enforce macOS metadata suppression
export COPYFILE_DISABLE=1

# 2. Prune local OS metadata & junk
echo "[1/5] Cleansing filesystem metadata..."
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "._*" -delete 2>/dev/null || true
find . -name "__MACOSX" -exec rm -rf {} + 2>/dev/null || true
rm -f .lumen_initialized* 2>/dev/null || true

# 3. Syntax verification pass across all shell scripts
echo "[2/5] Running POSIX ash syntax verification..."
FAILURES=0
while IFS= read -r script; do
    [ -z "$script" ] && continue
    if ! sh -n "$script" 2>/dev/null; then
        echo "Syntax Error in: $script"
        FAILURES=$((FAILURES + 1))
    fi
done <<EOF
$(find Apps Emus System tools -name "*.sh" 2>/dev/null)
EOF

if [ "$FAILURES" -gt 0 ]; then
    echo "ERROR: $FAILURES shell scripts failed syntax validation. Aborting build."
    exit 1
fi

# 4. Prepare output directory
mkdir -p "$OUTPUT_DIR"
rm -f "$ARCHIVE_PATH" "${ARCHIVE_PATH}.sha256"

# 5. Assemble distribution archive
echo "[3/5] Compressing distribution archive..."
# Zip distribution payload
zip -r -q "$ARCHIVE_PATH" \
    Apps \
    BIOS \
    Emus \
    Roms \
    RetroArch \
    System \
    Themes \
    Backgrounds \
    Icons \
    trimui \
    -x "*.git*" \
    -x "*tests*" \
    -x "*tools*" \
    -x "*.DS_Store*" \
    -x "*._*" \
    -x "*Thumbs.db*" \
    -x "*.lumen_initialized*"

# 6. Generate SHA256 checksum
echo "[4/5] Computing SHA256 checksum..."
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}' > "${ARCHIVE_PATH}.sha256"
elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ARCHIVE_PATH" | awk '{print $1}' > "${ARCHIVE_PATH}.sha256"
fi

# 7. Verification of archive hygiene
echo "[5/5] Verifying archive hygiene..."
CORRUPT_FILES=$(unzip -l "$ARCHIVE_PATH" | grep -E "(\._|\.DS_Store|__MACOSX)" || true)
if [ -n "$CORRUPT_FILES" ]; then
    echo "ERROR: Archive contains forbidden metadata:"
    echo "$CORRUPT_FILES"
    exit 1
fi

ARCHIVE_SIZE=$(wc -c < "$ARCHIVE_PATH" | tr -d ' ')
CHECKSUM=$(cat "${ARCHIVE_PATH}.sha256")

echo "=================================================="
echo " BUILD SUCCESSFUL"
echo " Archive:  $ARCHIVE_PATH"
echo " Size:     $ARCHIVE_SIZE bytes"
echo " SHA256:   $CHECKSUM"
echo "=================================================="
