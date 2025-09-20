# The Practical Solution

After extensive exploration, here's what actually works:

## 1. Git-Based Enforcement (Implemented)

### GitHub Actions (`.github/workflows/validate.yml`)
- Runs automatically on every push/PR
- Cannot be skipped
- Blocks merging if validation fails

### Pre-commit Hook (Local)
```bash
#!/bin/bash
# .git/hooks/pre-commit
npm test || exit 1
```

## 2. Prompt Pattern Training

### Always Include Validation
Instead of:
```
"Fix the counter app"
```

Use:
```
"Fix the counter app and use a subagent to validate all tests pass"
```

### Make It One Task
```
"Update the counter to increment by 2, then launch a subagent to verify the change works correctly"
```

## 3. Project Setup Script

Create a setup that enforces validation by default:

```bash
#!/bin/bash
# setup-validation.sh

# Install pre-commit hook
echo "npm test || exit 1" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Add validation reminder to README
echo "⚠️ All changes must pass validation: npm test" >> README.md

echo "Validation enforcement configured!"
```

## 4. The Reality Check

**What we cannot do**:
- Force Claude to automatically validate inside Claude Code
- Create hooks that access the Task tool
- Guarantee validation without external enforcement

**What we can do**:
- Use Git/CI to enforce validation externally
- Train better prompt patterns
- Make validation the easiest path

## Implementation Guide

1. **For Individual Projects**:
   - Add GitHub Actions workflow
   - Install pre-commit hooks
   - Include validation in all prompts

2. **For Teams**:
   - Require PR reviews
   - Set up CI/CD pipelines
   - Create validation checklists

3. **For Claude Code Users**:
   - Always request validation explicitly
   - Use subagents for independent verification
   - Don't mark tasks complete without validation

## The Key Insight

Validation cannot be enforced at the Claude level, but it can be enforced at the Git/workflow level. This is the practical solution that actually works.