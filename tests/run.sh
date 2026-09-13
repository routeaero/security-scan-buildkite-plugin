#!/usr/bin/env bash
# The canary (ADR-0004): the gate must FAIL on a planted secret and PASS on a
# clean tree, every run. A gate that has never failed has never been tested.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../hooks/command"
run() { (cd "$HERE/fixtures/$1" && bash "$HOOK" >/tmp/security-scan-$1.log 2>&1); }
if run leaky; then echo "FAIL: planted secret did not fail the gate"; cat /tmp/security-scan-leaky.log; exit 1; fi
grep -q "secrets=1" /tmp/security-scan-leaky.log || { echo "FAIL: leaky run did not report secrets=1"; cat /tmp/security-scan-leaky.log; exit 1; }
echo "ok: planted secret fails the gate"
run clean || { echo "FAIL: clean tree failed the gate"; cat /tmp/security-scan-clean.log; exit 1; }
echo "ok: clean tree passes"
rm -f "$HERE"/fixtures/*/security-report.*
