# Cybota Branch Cleanup - Test Repo

This repo tests the Cybota branch retention & cleanup workflow end-to-end.
All branches have backdated commits to simulate real-world history.

## Branch Map

| Branch | Type | Last Commit | Merged? | Tagged? | Expected Outcome |
|--------|------|-------------|---------|---------|-----------------|
| `main` | Protected | - | - | - | **KEEP** |
| `develop` | Protected | - | - | - | **KEEP** |
| `test` | Protected | - | - | - | **KEEP** |
| `prod` | Protected | - | - | - | **KEEP** |
| `feature/user-authentication` | Feature | ~54d ago | YES | NO | **DELETE** (merged >30d, no tag) |
| `feature/payment-gateway` | Feature | ~41d ago | YES | YES v1.2 | **KEEP** (tagged) |
| `feature/notification-system` | Feature | ~6d ago | YES | NO | **KEEP** (merged <30d) |
| `feature/dark-mode` | Feature | ~8d ago | NO | NO | **KEEP** (unmerged, active) |
| `feature/experimental-graphql` | Feature | ~115d ago | NO | NO | **NOTIFY then DELETE** (stale >90d) |
| `hotfix/sql-injection-fix` | Hotfix | ~104d ago | YES | NO | **DELETE** (merged >90d, no tag) |
| `hotfix/xss-patch` | Hotfix | ~43d ago | YES | NO | **KEEP** (merged <90d) |
| `hotfix/api-rate-limit` | Hotfix | ~1d ago | NO | NO | **KEEP** (unmerged, active) |
| `bugfix/login-redirect` | Bugfix | ~35d ago | YES | NO | **DELETE** (merged >30d, no tag) |
| `release/v1.0` | Release | ~92d ago | YES | YES v1.0.0 | **KEEP FOREVER** |
| `release/v1.1` | Release | ~3d ago | NO | NO | **KEEP** (active release) |
| `archive/ml-recommendation-engine` | Archive | ~98d ago | NO | NO | **KEEP** (manually archived) |

## Testing the Workflow Locally

```bash
cd /c/cybota-branch-test
bash scripts/run-tests.sh /c/cybota-branch-test
```

## Testing on GitHub

1. Push this repo to GitHub
2. Go to Actions -> Branch Cleanup Automation
3. Click Run workflow to trigger manually
4. Check Issues for stale notifications and deletion summaries

## PR Template Test

Create a PR from any feature branch into develop and the template will auto-populate.

## Tags

| Tag | Points To | Purpose |
|-----|-----------|---------|
| `v1.0.0` | `release/v1.0` | Production release |
| `v1.2-payment-gateway` | `feature/payment-gateway` | Critical feature impl |
