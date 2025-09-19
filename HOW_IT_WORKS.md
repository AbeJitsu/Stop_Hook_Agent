# How Subagent Validation Works

## The Flow

```
You make changes → Ask Claude to validate → Claude launches subagent → Independent validation → Results reported back
```

## What Happens When You Request Validation

### 1. You Ask Claude
"Use a subagent to validate my counter app works correctly"

### 2. Claude Uses Task Tool
```python
Task(
    description="Validate counter app",
    prompt="Run test-suite.js and verify all functionality works",
    subagent_type="general-purpose"
)
```

### 3. Subagent Runs Independently
- Has fresh context (doesn't know your conversation)
- Can run commands like `npm test`
- Can read and analyze files
- Can test the actual functionality

### 4. Results Come Back
The subagent reports findings, which Claude shares with you.

## Why This Is Better Than Hooks

**Hooks (what we removed):**
- Run as external bash scripts
- Can't access Claude's capabilities
- Limited to basic file checks
- Can't make intelligent decisions

**Subagents (the right way):**
- Full Claude intelligence
- Can understand context and requirements
- Run actual tests and analyze results
- Provide detailed, intelligent feedback

## Validation Capabilities

Subagents can:
1. **Run test suites** - Execute and interpret test results
2. **Check functionality** - Verify features actually work
3. **Review code quality** - Analyze patterns and practices
4. **Compare changes** - Understand what was modified and why
5. **Validate requirements** - Ensure all criteria are met

## Key Principle

Validation should be intelligent, not mechanical. Subagents provide the intelligence that bash scripts can't.