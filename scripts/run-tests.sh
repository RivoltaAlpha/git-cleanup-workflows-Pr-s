#!/usr/bin/env bash
# =============================================================================
# run-tests.sh
# Automated test runner that verifies cleanup-logic.sh produces the correct
# decision for every scenario defined in the retention strategy.
#
# Usage: ./run-tests.sh [repo_path]
#        repo_path defaults to /tmp/cybota-branch-test
# =============================================================================
set -euo pipefail

REPO_DIR="${1:-/tmp/cybota-branch-test}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; RESET='\033[0m'

PASS=0; FAIL=0; TOTAL=0

# ==========================================================================
# Step 1 – Setup (always fresh)
# ==========================================================================
echo -e "${BOLD}======================================================"
echo " Cybota Branch Retention – Full Test Suite"
echo -e "======================================================${RESET}"
echo ""
echo "[1/3] Setting up test repository..."
bash "$SCRIPT_DIR/setup-test-repo.sh" "$REPO_DIR" 2>&1 | grep '^\[setup\]'
echo "      Done."
echo ""

# ==========================================================================
# Step 2 – Capture cleanup-logic output for all branches
# ==========================================================================
echo "[2/3] Running cleanup logic (dry-run)..."
LOGIC_OUTPUT=$(bash "$SCRIPT_DIR/cleanup-logic.sh" "$REPO_DIR" --dry-run 2>&1)
echo "      Done."
echo ""

# ==========================================================================
# Step 3 – Assert expected decisions
# ==========================================================================
echo "[3/3] Asserting expected decisions..."
echo ""

# helper: assert_decision <branch> <expected_decision_substring>
assert_decision() {
  local branch="$1"
  local expected="$2"
  local description="$3"
  TOTAL=$((TOTAL + 1))

  # Grab the line for this branch from the table output (strip ANSI colour codes first)
  local actual
  actual=$(echo "$LOGIC_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^${branch}[[:space:]]" | head -1 || true)

  if echo "$actual" | grep -qi "$expected"; then
    echo -e "  ${GREEN}PASS${RESET}  [$branch] → expected='$expected'  | $description"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${RESET}  [$branch] → expected='$expected' but got: '$actual'"
    echo -e "        Description: $description"
    FAIL=$((FAIL + 1))
  fi
}

# --- Protected branches ---------------------------------------------------
assert_decision "develop"    "PROTECTED" "develop is a protected branch"
assert_decision "test"       "PROTECTED" "test is a protected branch"
assert_decision "production" "PROTECTED" "production is a protected branch"

# --- Scenario 1: feature merged >30d, not tagged → DELETE -----------------
assert_decision "feature/user-authentication" "DELETE" \
  "Merged feature >30 days ago, no tag → auto-delete"

# --- Scenario 2: feature merged, IS tagged → KEEP -------------------------
assert_decision "feature/payment-gateway" "KEEP" \
  "Merged feature with tag → keep (tag-first strategy)"

# --- Scenario 3: hotfix merged >90d, not tagged → DELETE ------------------
assert_decision "hotfix/sql-injection-fix" "DELETE" \
  "Merged hotfix >90 days, no tag → auto-delete"

# --- Scenario 4: hotfix merged <90d → KEEP --------------------------------
assert_decision "hotfix/xss-patch" "KEEP" \
  "Merged hotfix within 90d window → keep (audit trail)"

# --- Scenario 5: bugfix merged >30d → DELETE ------------------------------
assert_decision "bugfix/login-redirect" "DELETE" \
  "Merged bugfix >30 days → auto-delete"

# --- Scenario 6: release/* merged → KEEP forever -------------------------
assert_decision "release/v1.0" "KEEP" \
  "Release branch → keep forever regardless of age"

# --- Scenario 7: unmerged, active <90d → KEEP ----------------------------
assert_decision "feature/dark-mode" "KEEP" \
  "Unmerged but active feature → keep"

# --- Scenario 8: unmerged, stale >90d → NOTIFY→DELETE -------------------
assert_decision "feature/experimental-graphql" "NOTIFY" \
  "Unmerged stale >90 days → notify team, then delete"

# --- Scenario 9: archive/* → KEEP (never auto-delete) --------------------
assert_decision "archive/ml-recommendation-engine" "KEEP" \
  "Archive branch → keep (contains valuable unmerged work)"

# --- Scenario 10: feature merged <30d → KEEP -----------------------------
assert_decision "feature/notification-system" "KEEP" \
  "Recently merged feature (<30d) → keep"

# ==========================================================================
# Result summary
# ==========================================================================
echo ""
printf '%0.s-' {1..60}; echo ""
echo -e "${BOLD}Results: $PASS/$TOTAL passed, $FAIL failed${RESET}"
printf '%0.s-' {1..60}; echo ""
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All tests passed! The cleanup workflow behaves correctly.${RESET}"
  echo ""
  echo "You can also inspect the full decision table by running:"
  echo "  bash cleanup-logic.sh $REPO_DIR --dry-run"
  echo ""
  echo "To simulate actual branch deletion (local repo only, safe to re-run):"
  echo "  bash cleanup-logic.sh $REPO_DIR --execute"
else
  echo -e "${RED}${BOLD}$FAIL test(s) FAILED. Review the output above.${RESET}"
fi

echo ""
read -n 1 -s -r -p "Press any key to exit..."
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1