# Testing Guide

## Test Scenarios Using Subagents

### 1. Break Something Test
```
# Delete reset button from HTML
# Ask Claude: "Use a subagent to find what's broken in the counter app"
# Expected: Subagent detects missing button and failed tests
```

### 2. Validate Fix Test  
```
# Break increment function (make it subtract)
# Fix it
# Ask: "Launch a subagent to verify the counter works correctly"
# Expected: Subagent confirms all tests pass
```

### 3. Comprehensive Validation
```
# Ask: "Have a subagent do a full validation of the counter app"
# Expected: Detailed report on all aspects
```

## Effective Prompts for Subagent Validation

### Good Prompt (Specific)
```
"Use a subagent to verify:
1. Counter increments by exactly 1
2. Reset button returns to 0
3. All tests pass
4. No console errors"
```

### Better Prompt (Comprehensive)
```
"Launch a subagent to validate the counter app is production-ready,
checking tests, functionality, code quality, and error handling"
```

## What Success Looks Like

✅ **Working**: Subagent provides detailed validation report
✅ **Issues Found**: Clear explanation of what needs fixing
✅ **All Clear**: Confirmation that everything works

## Direct Testing

You can still run tests manually:
```bash
# Run test suite
npm test

# Start the app
npm start
```

But the power is in using subagents for intelligent validation.