# Subagent Learning Guide

Learn how to use Claude Code's Task tool to validate work through subagents.

## What Are Subagents?

Subagents are independent Claude instances launched via the Task tool to handle specific jobs. They're perfect for:
- Running tests and reporting results
- Validating that work is complete
- Reviewing code quality
- Checking that requirements are met

## Basic Subagent Usage

### Example 1: Run Tests
Ask Claude: "Use a subagent to run the test suite and report results"

Claude will use:
```python
Task(
    description="Run counter app tests",
    prompt="Execute test-suite.js and provide a detailed report of what passed/failed",
    subagent_type="general-purpose"
)
```

### Example 2: Validate Changes
Ask Claude: "Launch a subagent to verify my counter app changes are complete"

This triggers:
```python
Task(
    description="Validate counter app completion",
    prompt="""Check the following:
    1. All tests in test-suite.js pass
    2. The counter increments and resets properly
    3. UI elements are properly connected
    4. Code follows best practices
    Report any issues found.""",
    subagent_type="general-purpose"
)
```

### Example 3: Code Review
Ask Claude: "Have a subagent review my code for improvements"

## Subagent Types

- **general-purpose**: Best for most validation tasks
- **tech-simplifier-planner**: Good for creating development plans from technical work

## Practice Exercises

1. **Break Something**: 
   - Delete the reset button from counter app
   - Ask: "Use a subagent to find what's broken"
   
2. **Validate Fix**:
   - Fix the issue
   - Ask: "Launch a subagent to confirm everything works"

3. **Comprehensive Check**:
   - Ask: "Have a subagent do a full validation of the counter app"

## Key Learning Points

1. Subagents run independently - they don't have access to your conversation
2. Be specific in your prompts about what to check
3. Subagents can run commands, read files, and analyze code
4. Results come back as a detailed report

## Real-World Application

This pattern scales to any project:
- "Use a subagent to verify all API endpoints work"
- "Launch a subagent to check if my changes broke anything"
- "Have a subagent validate that all requirements are met"

The key is learning when and how to delegate validation to subagents for reliable results.