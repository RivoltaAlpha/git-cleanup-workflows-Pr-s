---
name: Pull Request
about: Standard pull request template for Cybota projects
title: 'Brief description of changes'
labels: ''
assignees: ''
---

## 📝 Description
<!-- Provide a clear and concise description of what this PR does -->


## 🎯 Changes Made
<!-- Summarize the key changes in this PR -->

-
-
-

## 🎫 Related Ticket *(optional)*
<!-- If this PR relates to a Jira ticket, add the link or number here -->
- **Ticket:** <!-- e.g. JIRA-123 or https://your-org.atlassian.net/browse/JIRA-123 -->

## Technical Details
<!-- Check all that apply, then expand the relevant section(s) below to fill in details -->

- [ ] New dependencies added
- [ ] API changes
- [ ] Database changes
- [ ] Architectural changes
- [ ] Testing
- [ ] Other (please specify)

<details>
<summary>New Dependencies</summary>

| Package | Version | Purpose |
|---------|---------|---------|
| | | |

</details>

<details>
<summary>API Changes</summary>

#### Modified Endpoints
-

#### New Endpoints
-

#### Deprecated Endpoints
-

</details>

<details>
<summary>Database Changes</summary>

#### Schema Changes
-

#### Migrations Required
```bash
# Migration commands

```

</details>

<details>
<summary>Architectural Changes</summary>

<!-- Describe any new patterns, tools, or architectural decisions -->

</details>

<details>
<summary>Testing</summary>

### Test Types
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] End-to-end tests added/updated
- [ ] Manual testing completed
- [ ] Test coverage maintained/improved

### Environment / Prerequisites
<!-- Any setup needed before testing (env vars, seed data, feature flags, etc.) -->
-

### How to Test
<!-- Step-by-step instructions for QA/reviewers -->

```bash
# Steps to test locally

```

### Test Scenarios
<!-- Key scenarios and their expected outcomes -->

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | | |
| 2 | | |
| 3 | | |

</details>

<details>
<summary>Other Changes</summary>

<!-- Describe any other significant changes that don't fit the above categories -->

</details>

## Performance Considerations(Optional)

- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance implications documented below

**Details:**


## 🐛 Known Issues / Limitations

-

## ✔️ Pre-Merge Checklist

### Code Quality
- [ ] Code follows Cybota coding conventions
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] No console.logs or debug code
- [ ] No commented-out code

### Documentation
- [ ] README updated (if needed)
- [ ] API documentation updated (if needed)
- [ ] Inline code documentation added
- [ ] CHANGELOG updated (if applicable)

### Branch & Commits
- [ ] Branch follows naming convention (`feature/`, `bugfix/`, `hotfix/`)
- [ ] Commits follow conventional commit format
- [ ] Branch is up-to-date with `develop`
- [ ] No merge conflicts

### Testing & Quality
- [ ] All tests pass locally
- [ ] No new linting errors
- [ ] Code coverage maintained/improved

### Review Requirements
- [ ] PR description is clear and complete
- [ ] Reviewers assigned
- [ ] Labels added appropriately

## 👥 Reviewers
<!-- Tag team members who should review this PR -->

@reviewer1 @reviewer2

---

**Deployment Notes:**
<!-- Any special deployment considerations? -->


---
