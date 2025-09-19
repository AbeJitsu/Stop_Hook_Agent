# Validation Examples

Practice scenarios to learn effective subagent validation.

## Example 1: Basic Test Run

**Scenario**: You want to check if all tests pass.

**Ask Claude**:
```
"Use a subagent to run the test suite and tell me what passes or fails"
```

**What happens**: Subagent runs `npm test` and reports detailed results.

## Example 2: Breaking Changes Detection

**Scenario**: You've modified the counter app and want to ensure nothing broke.

**Setup**:
1. Change increment to add 2 instead of 1
2. Ask Claude:
```
"Launch a subagent to verify the counter still works correctly and all tests pass"
```

**Expected**: Subagent detects test failures and explains what's broken.

## Example 3: Missing Functionality

**Scenario**: Delete the reset button to practice detection.

**Steps**:
1. Remove reset button from `counter-app/index.html`
2. Ask:
```
"Have a subagent do a comprehensive validation of the counter app"
```

**Result**: Subagent finds missing button and failed tests.

## Example 4: Code Quality Review

**Ask Claude**:
```
"Use a subagent to review the counter app code for best practices and improvements"
```

**Subagent checks**:
- Code organization
- Error handling
- Performance considerations
- Accessibility

## Example 5: Requirements Validation

**Scenario**: Ensure specific requirements are met.

**Ask**:
```
"Launch a subagent to verify:
1. Counter starts at 0
2. Increment adds exactly 1
3. Reset returns to 0
4. No console errors
5. All UI elements are connected"
```

## Example 6: Fix Validation

**After fixing an issue**:
```
"Use a subagent to confirm my fix resolved all issues"
```

## Pro Tips

1. **Be specific** about what to validate
2. **Include success criteria** in your request
3. **Ask for detailed reports** when learning
4. **Try breaking things** to see how subagents detect issues

## Advanced Pattern

Combine multiple validations:
```
"Have a subagent:
1. Run all tests
2. Check for console errors
3. Verify UI functionality
4. Review code quality
Provide a comprehensive report"
```

This teaches you how granular subagent validation can be.