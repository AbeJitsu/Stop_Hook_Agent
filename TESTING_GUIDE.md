# Testing Guide

## Test Scenarios

### 1. Break Something Test
```bash
# Delete reset button from HTML
# Tell Claude: "Fix the counter app"
# Expected: Validator catches missing button
```

### 2. Incomplete Fix Test  
```bash
# Break increment function (make it subtract)
# Tell Claude: "Fix counter increment"
# Interrupt before completion
# Expected: Validator prevents false completion
```

### 3. Todo Mismatch Test
```bash
# Give Claude 3 tasks
# Let it complete only 2
# Expected: Validator shows "todos incomplete"
```

## Example Prompts

### Good Prompt (Specific)
```
Add a decrement button with these criteria:
1. Button shows "Decrement (-1)"
2. Clicking reduces counter by 1
3. All tests must pass
```

### Bad Prompt (Vague)
```
Make the counter better
```

## What Success Looks Like

✅ **Working**: Validator blocks with specific reasons  
❌ **Not Working**: Claude says "done" when it's not

## Manual Testing

```bash
# Run validator directly
./validator.sh

# Check specific validation
./validator.sh --verbose

# Test without auto-commit
./validator.sh --no-commit
```