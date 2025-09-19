# AI Review Design - Proper Task Tool Usage

## Current Problem

The current implementation (`lib/ai_reviewer.sh`) attempts to simulate a subagent using shell scripts. This is fundamentally wrong because:

1. Shell scripts cannot invoke Claude Code's Task tool
2. The Task tool is a Python/JavaScript API, not a bash command
3. We're trying to bridge two incompatible systems

## Desired Behavior

### What Should Happen

When the validator reaches the AI Review step:

1. **Validator prepares review data** (todos, completed items, git changes)
2. **Claude Code intercepts this need** and launches a subagent using:
   ```python
   Task(
       description="Review if todos match git changes",
       prompt=f"""Analyze if completed todos genuinely match git changes:
       
       {review_data}
       
       Check:
       - Each completed todo has corresponding code changes
       - Changes are meaningful (not just whitespace)
       - Todos are actually resolved by the changes
       
       Return only YES or NO.""",
       subagent_type="general-purpose"
   )
   ```
3. **Subagent analyzes deeply** using full Claude capabilities
4. **Result flows back** to validator for final decision

### Why Shell Scripts Don't Work

- `lib/ai_reviewer.sh` pretends to call Claude but actually just runs heuristics
- No actual subagent is launched
- The Task tool exists in Claude Code's runtime, not in bash

### Correct Architecture

```
Validator (bash) → Signals need for review → Claude Code (Python/JS) → Task() → Subagent
                                                ↑                           ↓
                                            Result ← ← ← ← ← ← ← ← ← ← Response
```

## Implementation Options

### Option 1: Direct Integration
- Validator writes review request to `.claude/review_request.json`
- Claude Code watches this file and launches Task
- Subagent writes result to `.claude/review_result.json`
- Validator reads result and continues

### Option 2: Hook System
- Validator exits with special code when review needed
- Claude Code catches this and launches subagent
- After review, Claude Code re-runs validator

### Option 3: Remove AI Review from Bash
- Move entire validation logic to Claude Code
- Bash validator becomes a simple wrapper
- All intelligent validation happens via Task tool

## Recommendation

**Option 3** is the correct approach. Trying to call Task from bash is like trying to fly a plane from a bicycle - wrong vehicle for the job.

## Current State to Remove

Files that implement the wrong approach:
- `lib/ai_reviewer.sh` - Shell script pretending to be a subagent launcher
- Modified `lib/validators.sh` - Calls the shell script instead of using Task

These should be removed and replaced with proper Task tool integration.