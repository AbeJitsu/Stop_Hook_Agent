# How It Works

## Validation Flow

```
Claude completes task → validator.sh runs → 6 checks performed → Pass/Fail decision
```

## The 6 Validation Criteria

### 1. File Structure
Verifies required files exist:
- counter-app/index.html
- counter-app/style.css  
- counter-app/script.js

### 2. Syntax Validation
- JavaScript: `node -c` syntax check
- JSON: `jq` validation

### 3. Test Execution
Runs `npm test` (test-suite.js)

### 4. Todo Validation
- Reads todos from .claude/state.json
- Checks completed todos have corresponding git changes
- Prevents marking todos complete without code changes

### 5. Git State
- Checks for uncommitted changes
- Validates changes are meaningful (not just whitespace)

### 6. AI Review (Subagent)
- Calls `lib/ai_reviewer.sh` to analyze todo/git alignment
- Passes JSON with todos, completed items, and git changes
- Subagent returns YES/NO based on deep analysis
- Falls back to simple heuristic if subagent unavailable

## Auto-Commit

When ALL 6 criteria pass:
1. Stages all changes
2. Creates commit with validation summary
3. Exits with success code

When ANY criteria fail:
1. Shows specific failure reasons
2. Provides actionable next steps
3. Exits with error code (blocks completion)