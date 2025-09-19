# Subagent Validation Learning Project

Learn how to use Claude Code's Task tool to validate work completion through subagents.

## What This Is

A hands-on project to learn proper subagent usage for:
- Running tests independently
- Validating work completion
- Reviewing code quality
- Ensuring requirements are met

## Project Structure

```
├── counter-app/       # Simple app to practice validation
├── test-suite.js      # Tests that subagents can run
├── SUBAGENT_GUIDE.md  # Learn how to use subagents
└── validation_examples.md # Practice scenarios
```

## Quick Start

1. **Run tests manually**:
   ```bash
   npm test
   ```

2. **Use a subagent** (ask Claude):
   ```
   "Use a subagent to run tests and validate the counter app"
   ```

3. **Practice validation**:
   ```
   "Launch a subagent to check if all requirements are met"
   ```

## Learning Path

1. Read [SUBAGENT_GUIDE.md](SUBAGENT_GUIDE.md) to understand subagents
2. Try the practice exercises with the counter app
3. Learn to write effective validation prompts
4. Apply these patterns to your real projects

## Why This Matters

Instead of relying on hooks or external scripts, learn to use Claude's native Task tool for reliable validation. Subagents provide real, independent verification of your work.

## Key Insight

Subagents are Claude's proper way to validate work - not shell scripts or hooks. This project teaches you how to use them effectively.