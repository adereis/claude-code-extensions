---
description: Review commits for code quality issues
allowed-args: "[commit-range]"
---

Use the commit-reviewer subagent to analyze commits.

## Commit Range

- No argument: reviews last commit (`HEAD~1..HEAD`)
- `HEAD~3`: reviews last 3 commits
- `origin/main..HEAD`: reviews all unpushed commits
- Any valid git revision range

Provide a comprehensive review covering:
- Commit hygiene (message quality, atomic commits, git story)
- Security vulnerabilities and risks
- Performance concerns and optimization opportunities
- Documentation completeness and accuracy
- Linting and code style issues
- Test coverage gaps and quality
- Similar code elsewhere that needs the same changes

If commits are unpushed, recommend specific fixes (amend, split, squash).

Summarize findings grouped by severity (Critical → Warnings → Suggestions).

If there are no significant issues, say so briefly—don't manufacture problems.
