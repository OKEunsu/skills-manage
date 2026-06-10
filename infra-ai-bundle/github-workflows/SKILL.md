---
name: github-workflows
description: "Manage GitHub issues, pull requests, Actions, reviews, and branch workflows with a single operational playbook."
risk: critical
source: merged
date_added: "2026-04-16"
---

# GitHub Workflows

Unified workflow for GitHub operations: issue triage, pull request quality, CI investigation, workflow automation, and branch-based collaboration.

## Use this skill when

- Working with GitHub issues, pull requests, review comments, or Actions runs
- Preparing, improving, or validating a pull request before merge
- Investigating CI failures or workflow behavior
- Automating GitHub housekeeping, triage, labeling, or PR metadata
- Working with `gh` CLI or GitHub APIs for repository operations

## Do not use this skill when

- The task is plain local git usage with no GitHub interaction
- The user only needs a code change and no repo workflow help
- Destructive repo actions are requested without explicit approval

## Instructions

1. Confirm the repository, target branch, and task scope.
2. Prefer safe inspection first: PR metadata, changed files, checks, and comments.
3. For PR work, check reviewability, CI status, and merge blockers before proposing automation.
4. For Actions work, inspect failed runs and logs before editing workflows.
5. For destructive or irreversible actions such as merge, delete, or force-update, require explicit user approval.

## Core Workflows

### 1. Pull Request Operations

- Gather PR summary, changed files, linked issues, and current review state.
- Improve PR quality with:
  - concise title
  - clear summary of what changed and why
  - test notes
  - risk or rollout notes
  - reviewer guidance for large diffs
- Check CI and branch protection before recommending merge.
- If review comments exist, address actionable comments first and keep discussion tied to file context.

### 2. CI and Actions Investigation

- Start with failing checks, then inspect the exact run and failed job.
- Prefer a tight sequence:
  - identify failing check
  - inspect run metadata
  - inspect failed logs
  - map failure to workflow file and step
- Separate workflow bugs from application/test bugs before changing YAML.

### 3. Issue and Triage Operations

- Distinguish issues from pull requests when list endpoints combine them.
- Apply labels, assignees, and milestones only after confirming repo permissions.
- Summarize issue state clearly: problem, scope, likely owner, next action.

### 4. Branch and Review Hygiene

- Keep PRs small enough to review.
- Prefer branch names that convey intent and ticket context.
- Surface merge blockers explicitly:
  - failing checks
  - requested changes
  - merge conflicts
  - missing docs or tests

### 5. Automation Design

- Use GitHub automation when the workflow is repetitive and stable:
  - issue triage
  - PR labeling
  - review reminders
  - workflow dispatches
  - AI-assisted review comments
- Keep automation bounded, observable, and reversible.
- Avoid auto-merge or mutation-heavy automation without clear safeguards.

## `gh` CLI Quick Reference

```bash
gh pr checks 55 --repo owner/repo
gh run list --repo owner/repo --limit 10
gh run view <run-id> --repo owner/repo --log-failed
gh issue list --repo owner/repo --json number,title,state
gh api repos/owner/repo/pulls/55 --jq '.title, .state'
```

## Output Expectations

- State the current GitHub object clearly: issue, PR, run, branch, or workflow.
- List blockers before recommendations.
- Keep merge/readiness advice explicit.
- When drafting PR text, include summary, testing, risk, and follow-up notes.

## Limitations

- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
