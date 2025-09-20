# Validation Enforcement Project

Learn how to enforce validation in Claude Code projects through practical approaches that actually work.

## The Problem

Claude Code can declare work "complete" without validation. This project explores solutions that actually enforce validation.

## What's Included

**Working Solutions**:
- Git hooks that block commits if tests fail
- GitHub Actions for CI/CD enforcement  
- Setup scripts for easy configuration

**Educational Resources**:
- Why traditional approaches fail
- How to use subagents effectively
- Practical enforcement strategies

## Quick Setup

```bash
# Enforce validation locally
./setup-validation.sh

# Now validation runs automatically before commits
```

## How It Works

1. **Git Enforcement**: Can't commit if tests fail
2. **CI/CD**: Can't merge PRs without validation
3. **Prompt Patterns**: Include validation in requests
4. **Subagents**: For independent verification

## Key Documents

- [WHY_THIS_FAILS.md](WHY_THIS_FAILS.md) - Why validation is hard to enforce
- [SOLUTION.md](SOLUTION.md) - Practical approaches that work
- [ENFORCEMENT_APPROACHES.md](ENFORCEMENT_APPROACHES.md) - Alternative strategies explored
- [SUBAGENT_GUIDE.md](SUBAGENT_GUIDE.md) - How to use subagents properly

## The Reality

We can't force Claude to validate internally, but we can:
- Enforce at the Git level ✅
- Train better habits ✅  
- Use external tools ✅

This project shows you how.