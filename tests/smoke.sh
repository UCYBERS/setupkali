#!/bin/bash
# Smoke tests for setupkali.sh. Run from the repository root: sudo bash tests/smoke.sh
# Needs root only because the script under test refuses to start without it.

cd "$(dirname "$0")/.." || exit 1

fail=0
ok()  { echo "  [PASS] $1"; }
bad() { echo "  [FAIL] $1"; fail=1; }
check() { local desc="$1"; shift; if "$@" &>/dev/null; then ok "$desc"; else bad "$desc"; fi; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Fake Kali os-release so the script runs on any CI image
echo 'ID=kali' > "$tmp/os-release"
sed "s#/etc/os-release#$tmp/os-release#" setupkali.sh > "$tmp/setupkali.sh"

version=$(grep -m1 '^VERSION=' setupkali.sh | cut -d'"' -f2)

echo "== Version consistency (v${version})"
check "--version prints the version" test "$(bash setupkali.sh --version)" == "setupkali ${version}"
check "CHANGELOG top section is ${version}" test "$(grep -m1 '^## ' CHANGELOG.md)" == "## ${version}"
check "README badge is ${version}" grep -q "badge/version-${version}-" README.md
check "README current version is ${version}" grep -q "Current version: \*\*${version}\*\*" README.md

echo "== Command line behaviour"
bash "$tmp/setupkali.sh" --help &>/dev/null;  check "--help exits 0" test $? -eq 0
bash "$tmp/setupkali.sh" --bogus &>/dev/null; check "unknown option exits 1" test $? -eq 1

echo "== Integrity data"
check "pinned asset hashes are 64 hex characters" bash -c \
    "[ \$(grep -cE '^\s+\[[A-Za-z0-9.-]+\]=\"[0-9a-f]{64}\"' setupkali.sh) -ge 3 ]"
check "fixed-http-shellshock.nse matches its pinned hash" bash -c \
    "sha256sum fixed-http-shellshock.nse | grep -q \"\$(grep -oE 'shellshock_sha256=\"[0-9a-f]{64}\"' setupkali.sh | cut -d'\"' -f2)\""

echo
if (( fail )); then echo "SMOKE TESTS FAILED"; exit 1; fi
echo "SMOKE TESTS PASSED"
