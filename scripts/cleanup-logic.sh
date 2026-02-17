#!/usr/bin/env bash
# =============================================================================
# cleanup-logic.sh
# Local simulation of the branch-cleanup.yml GitHub Actions workflow.
# Runs against a local repo (no GitHub API calls) and outputs what it WOULD
# do: DELETE, NOTIFY, KEEP, ARCHIVE, PROTECTED.
#
# Usage: ./cleanup-logic.sh <repo_path> [--dry-run]
#        --dry-run  (default) Print decisions only, make no changes
#        --execute  Actually delete/tag branches in the local repo
# =============================================================================
set -euo pipefail

REPO_DIR="${1:-/tmp/cybota-branch-test}"
MODE="${2:---dry-run}"   # --dry-run | --execute

# Thresholds (days) – mirror the retention strategy document
FEATURE_DELETE_DAYS=30
BUGFIX_DELETE_DAYS=30
HOTFIX_DELETE_DAYS=90
STALE_UNMERGED_DAYS=90

# Protected branches – never touch these
PROTECTED=("main" "develop" "test" "production")

# ---- Colour helpers -------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

is_protected() {
  local branch="$1"
  for p in "${PROTECTED[@]}"; do
    [[ "$branch" == "$p" ]] && return 0
  done
  return 1
}

days_since() {
  # Returns integer days since ISO date string $1
  local iso_date="$1"
  local ts now
  ts=$(date -d "$iso_date" +%s 2>/dev/null \
    || python3 -c "import datetime,sys; print(int(datetime.datetime.fromisoformat('${iso_date}').timestamp()))")
  now=$(date +%s)
  echo $(( (now - ts) / 86400 ))
}

branch_is_tagged() {
  local branch="$1"
  # Only check the tip commit of this branch, not its full ancestry.
  # git tag --contains walks ancestors too, causing false positives when a
  # sibling branch's tag exists on a shared ancestor commit.
  local tip
  tip=$(git rev-parse "$branch" 2>/dev/null) || return 1
  git tag --points-at "$tip" 2>/dev/null | grep -q . && return 0 || return 1
}

branch_is_merged_to() {
  local branch="$1" base="$2"
  git branch --merged "$base" 2>/dev/null | grep -q "^\s*${branch}$" && return 0 || return 1
}

# ==========================================================================
cd "$REPO_DIR"

echo ""
echo -e "${BOLD}======================================================"
echo " Cybota Branch Cleanup Logic – Simulation"
echo -e "======================================================${RESET}"
echo " Repo : $REPO_DIR"
echo " Mode : $MODE"
echo " Date : $(date '+%Y-%m-%d %H:%M')"
echo ""

# Track results for summary
declare -A DECISIONS   # branch → decision string
declare -A REASONS

# Column widths for pretty table
COL_BRANCH=42; COL_AGE=6; COL_MERGED=8; COL_TAGGED=7; COL_DECISION=20

printf "${BOLD}%-${COL_BRANCH}s %-${COL_AGE}s %-${COL_MERGED}s %-${COL_TAGGED}s %s${RESET}\n" \
  "BRANCH" "AGE(d)" "MERGED?" "TAGGED?" "DECISION"
printf '%0.s-' {1..100}; echo ""

for branch in $(git branch --format='%(refname:short)'); do
  # ---- Basic facts ---------------------------------------------------------
  last_commit_date=$(git log -1 --format='%ci' "$branch" 2>/dev/null || echo "")
  [[ -z "$last_commit_date" ]] && continue

  age=$(days_since "$last_commit_date")
  merged=false; branch_is_merged_to "$branch" develop && merged=true
  tagged=false; branch_is_tagged "$branch" && tagged=true

  # ---- Decision logic (mirrors retention matrix) ---------------------------
  decision=""
  reason=""
  colour="$RESET"

  if is_protected "$branch"; then
    decision="PROTECTED"; reason="never delete"; colour="$CYAN"

  elif [[ "$branch" == archive/* ]]; then
    decision="KEEP (archive)"; reason="archive branch – manual review only"; colour="$GREEN"

  elif $merged; then
    # ---------- MERGED branches ----------
    if [[ "$branch" == release/* ]]; then
      decision="KEEP forever"; reason="release branch"; colour="$GREEN"

    elif [[ "$branch" == hotfix/* ]]; then
      if [[ $age -gt $HOTFIX_DELETE_DAYS ]] && ! $tagged; then
        decision="DELETE"; reason="hotfix merged >90d ago, not tagged"; colour="$RED"
      else
        decision="KEEP"; reason="hotfix within 90d window or tagged"; colour="$GREEN"
      fi

    elif [[ "$branch" == feature/* ]] || [[ "$branch" == bugfix/* ]]; then
      if $tagged; then
        decision="KEEP (tagged)"; reason="tagged – preserve for audit"; colour="$GREEN"
      elif [[ $age -gt $FEATURE_DELETE_DAYS ]]; then
        decision="DELETE"; reason="${branch%%/*} merged >30d ago, not tagged"; colour="$RED"
      else
        decision="KEEP"; reason="merged <30d ago"; colour="$GREEN"
      fi

    else
      # Generic merged branch not matching a known prefix
      if [[ $age -gt $FEATURE_DELETE_DAYS ]] && ! $tagged; then
        decision="DELETE"; reason="merged >30d, unknown prefix"; colour="$RED"
      else
        decision="KEEP"; reason="merged recently or tagged"; colour="$GREEN"
      fi
    fi

  else
    # ---------- UNMERGED branches ----------
    if [[ $age -gt $STALE_UNMERGED_DAYS ]]; then
      decision="NOTIFY→DELETE"; reason="unmerged, stale >90d"; colour="$YELLOW"
    else
      decision="KEEP"; reason="unmerged but still active"; colour="$GREEN"
    fi
  fi

  DECISIONS["$branch"]="$decision"
  REASONS["$branch"]="$reason"

  merged_str=$(  $merged && echo "yes" || echo "no")
  tagged_str=$(  $tagged && echo "yes" || echo "no")

  printf "${colour}%-${COL_BRANCH}s %-${COL_AGE}s %-${COL_MERGED}s %-${COL_TAGGED}s %s${RESET}\n" \
    "$branch" "$age" "$merged_str" "$tagged_str" "$decision"
done

echo ""
printf '%0.s-' {1..100}; echo ""

# ==========================================================================
# EXECUTE mode – actually perform deletions (local only)
# ==========================================================================
if [[ "$MODE" == "--execute" ]]; then
  echo ""
  echo -e "${BOLD}[EXECUTE] Applying decisions to local repo...${RESET}"
  echo ""
  for branch in "${!DECISIONS[@]}"; do
    decision="${DECISIONS[$branch]}"

    case "$decision" in
      DELETE)
        # Tag for audit trail before deleting
        tag_name="deleted/$(echo "$branch" | tr '/' '-')-$(date +%Y%m%d)"
        git tag -a "$tag_name" "$branch" \
          -m "Branch deleted by cleanup simulation. Reason: ${REASONS[$branch]}" 2>/dev/null \
          || true
        git branch -D "$branch" 2>/dev/null && \
          echo -e "  ${RED}DELETED${RESET} $branch  → tagged as $tag_name" || \
          echo -e "  ${RED}FAILED${RESET}  to delete $branch"
        ;;
      NOTIFY*)
        echo -e "  ${YELLOW}NOTIFY${RESET}  $branch  – team notified (simulated)"
        ;;
      *)
        # KEEP / PROTECTED / archive – no action
        ;;
    esac
  done
fi

# ==========================================================================
# Summary counts
# ==========================================================================
echo ""
echo -e "${BOLD}Summary${RESET}"
echo "-------"
declare -A counts
for branch in "${!DECISIONS[@]}"; do
  key="${DECISIONS[$branch]}"
  counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
done
for key in "${!counts[@]}"; do
  echo "  ${counts[$key]}x  $key"
done
echo ""
echo -e "Legend: ${GREEN}KEEP${RESET}  ${RED}DELETE${RESET}  ${YELLOW}NOTIFY→DELETE${RESET}  ${CYAN}PROTECTED${RESET}"
echo ""
