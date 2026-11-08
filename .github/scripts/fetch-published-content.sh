#!/usr/bin/env bash
# fetch-published-content.sh <out-dir> — download the content currently
# published on GitHub Pages (docs/07 §7: manifest.json + content.json.gz) into
# <out-dir> as dist/ would hold it: manifest.json, content.json.gz,
# content.json, VERSION. Used by CI when the checkout has no dist/ (it is
# gitignored until content.yml commits it), so that
#   - content.yml builds on top of the published version (tools/build bumps
#     dist/VERSION; without it content_version would restart at 1), and
#   - app.yml bundles and redeploys the published content with the app.
# Exit 0 = fetched, 3 = nothing published yet, other = error.
set -euo pipefail

OUT="${1:?usage: fetch-published-content.sh <out-dir>}"
BASE="${CONTENT_BASE_URL:-https://duyan11110.github.io/lo-trinh-architect/content/}"
BASE="${BASE%/}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

code="$(curl -sS -o "$TMP/manifest.json" -w '%{http_code}' "$BASE/manifest.json" || true)"
if [ "$code" = "404" ]; then
  echo "fetch-published-content: nothing published at $BASE yet" >&2
  exit 3
fi
if [ "$code" != "200" ]; then
  echo "fetch-published-content: manifest.json HTTP $code" >&2
  exit 1
fi
curl -fsSL -o "$TMP/content.json.gz" "$BASE/content.json.gz"
gunzip -c "$TMP/content.json.gz" > "$TMP/content.json"

want="$(jq -r '.sha256' "$TMP/manifest.json" | tr 'A-F' 'a-f')"
gz_sha="$(sha256sum "$TMP/content.json.gz" | cut -d' ' -f1)"
json_sha="$(sha256sum "$TMP/content.json" | cut -d' ' -f1)"
# docs/07 §7 says the sha256 is of the .gz; tools/build currently hashes
# content.json — accept either, reject anything else.
if [ "$want" != "$gz_sha" ] && [ "$want" != "$json_sha" ]; then
  echo "fetch-published-content: sha256 mismatch (manifest $want)" >&2
  exit 1
fi

version="$(jq -r '.content_version' "$TMP/manifest.json")"
cp "$TMP/manifest.json" "$TMP/content.json.gz" "$TMP/content.json" "$OUT/"
echo "$version" > "$OUT/VERSION"
echo "fetch-published-content: v$version from $BASE -> $OUT"
