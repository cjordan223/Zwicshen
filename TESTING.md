# Zwischen End-to-End Testing Framework

## Context

Zwischen is a lightweight Ruby CLI gem for AI-augmented security scanning. It will be publicly available via RubyGems. This testing framework verifies the complete workflow as an **installed gem** (not from source), ensuring it works for end users.

**Codebase Location:** `~/Zwischen`  
**Test Directory:** Use any temporary directory outside the Zwischen repository (e.g., `/tmp/zwischen-test` or `~/test-zwischen`)

## Setup: Install as Gem

```bash
# 1. Build and install the gem
cd ~/Zwischen
./scripts/test_as_gem.sh

# 2. Add to PATH (script will show exact path)
export PATH="$HOME/.local/share/gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"

# 3. Verify installation
which zwischen
zwischen --help
```

## Test Framework

Execute these tests in order. For each test, record: **PASS**, **FAIL**, or **SKIP** (with reason).

### Test Suite 1: Installation & Setup

**Test 1.1: Gem Installation**
- [ ] `gem list zwischen` shows installed gem
- [ ] `which zwischen` points to gem bin (not `~/Zwischen/bin`)
- [ ] `zwischen --help` shows commands: init, scan, uninstall, doctor

**Test 1.2: Interactive Setup**
```bash
# Create a temporary test directory (outside Zwischen repo)
TEST_DIR=$(mktemp -d -t zwischen-test-XXXXXX)
cd "$TEST_DIR"
mkdir test-repo && cd test-repo
git init
echo "# Test" > README.md && git add . && git commit -m "Initial"
zwischen init
# Answer: y (AI), [test-key], y (hook), y (config)
```
- [ ] `.zwischen.yml` created
- [ ] `~/.zwischen/credentials` created with 0600 permissions
- [ ] `.git/hooks/pre-push` created, executable, contains marker comment

**Test 1.3: Config Structure**
- [ ] `.zwischen.yml` contains: `ai.enabled`, `blocking.severity`, `scanners`
- [ ] Config loads without errors

### Test Suite 2: Pre-Push Hook

**Test 2.1: Clean Push (No Issues)**
```bash
echo "def hello(): pass" > test.py
git add . && git commit -m "Add test"
.git/hooks/pre-push
```
- [ ] Hook executes silently (no output)
- [ ] Exit code: 0

**Test 2.2: Blocking Push (With Issues)**
```bash
echo "password = 'secret123'" > config.py
git add . && git commit -m "Add secret"
.git/hooks/pre-push
```
- [ ] Compact output shows: `🛡️ Zwischen: X issues found`
- [ ] Shows severity, file:line, message
- [ ] Shows "Push blocked" message
- [ ] Exit code: 1

**Test 2.3: Bypass Mechanisms**
- [ ] `git push --no-verify` bypasses hook
- [ ] `ZWISCHEN_SKIP=1 git push` bypasses hook

### Test Suite 3: Manual Scan Commands

**Test 3.1: Standard Scan**
```bash
zwischen scan
```
- [ ] Shows "Scanning..." message
- [ ] Full report with summary and findings
- [ ] Exit code reflects findings

**Test 3.2: Pre-Push Mode**
```bash
zwischen scan --pre-push
```
- [ ] Silent when clean (no "Scanning..." message)
- [ ] Compact output when issues found
- [ ] Only shows blocking findings (based on config)

**Test 3.3: Changed Files Filtering**
```bash
# Create file with issue, commit
echo "api_key = 'test'" > changed.py
git add . && git commit -m "Add changed"

# Create another file with issue, don't commit
echo "password = 'test'" > unchanged.py

zwischen scan --pre-push
```
- [ ] Only reports findings from `changed.py`
- [ ] Filters out `unchanged.py` findings

### Test Suite 4: Configuration Options

**Test 4.1: Blocking Severity - High (Default)**
- [ ] High/Critical findings block push
- [ ] Medium/Low/Info do NOT block

**Test 4.2: Blocking Severity - Critical Only**
```yaml
# .zwischen.yml
blocking:
  severity: critical
```
- [ ] Only Critical blocks push
- [ ] High does NOT block

**Test 4.3: Blocking Severity - None**
```yaml
blocking:
  severity: none
```
- [ ] No findings block push
- [ ] Findings reported but push proceeds

### Test Suite 5: Uninstall

**Test 5.1: Uninstall Hook**
```bash
zwischen uninstall
# Answer: y (hook), n (config), n (credentials)
```
- [ ] Hook removed (`.git/hooks/pre-push` deleted)
- [ ] Config preserved (if answered 'n')
- [ ] Credentials preserved (if answered 'n')

**Test 5.2: Preserve Custom Hooks**
```bash
# Create custom hook
echo "#!/bin/bash\necho 'custom'" > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
zwischen uninstall
```
- [ ] Custom hook NOT removed
- [ ] Uninstall detects it's not a Zwischen hook

### Test Suite 6: Edge Cases

**Test 6.1: No Git Repository**
```bash
cd /tmp && mkdir no-git && cd no-git
zwischen init
```
- [ ] Warning about no `.git` directory
- [ ] Hook installation skipped
- [ ] Config/credentials still work

**Test 6.2: Existing Pre-Push Hook**
```bash
# Create existing hook, then run init
echo "#!/bin/bash\necho 'existing'" > .git/hooks/pre-push
zwischen init
# Choose: backup/append/skip
```
- [ ] Backup option creates `.pre-push.zwischen.backup`
- [ ] Append option adds Zwischen check to existing hook
- [ ] Skip option preserves original hook

**Test 6.3: Default Branch Detection**
- [ ] Detects `main` branch correctly
- [ ] Falls back to `master` if `main` doesn't exist
- [ ] Changed files detection works for both

### Test Suite 7: AI Integration

**Test 7.1: AI-Enabled (If API Key Available)**
```bash
# With valid API key in ~/.zwischen/credentials
zwischen scan --pre-push
```
- [ ] AI analysis runs (may take time)
- [ ] False positives marked/filtered
- [ ] Fix suggestions shown

**Test 7.2: AI Disabled**
```yaml
# .zwischen.yml
ai:
  enabled: false
```
- [ ] Scan completes without AI
- [ ] All findings shown (no false positive filtering)

## Test Report Template

After completing tests, provide a report:

```markdown
# Zwischen Test Report

## Environment
- Ruby version: [output of `ruby -v`]
- Gem location: [output of `gem which zwischen`]
- Test directory: [path used]

## Test Results

### Suite 1: Installation & Setup
- Test 1.1: [PASS/FAIL/SKIP]
- Test 1.2: [PASS/FAIL/SKIP]
- Test 1.3: [PASS/FAIL/SKIP]

### Suite 2: Pre-Push Hook
- Test 2.1: [PASS/FAIL/SKIP]
- Test 2.2: [PASS/FAIL/SKIP]
- Test 2.3: [PASS/FAIL/SKIP]

[... continue for all suites ...]

## Failures
[List any failures with details]

## Issues Found
[Any bugs, edge cases, or improvements needed]

## Overall Status
[PASS/FAIL] - [Summary]
```

## Success Criteria

All critical tests (1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 5.1) must PASS for the gem to be considered functional.

## Cleanup

```bash
# Uninstall test gem
gem uninstall zwischen --user-install

# Clean test directories (adjust path to match your test directory)
rm -rf /tmp/zwischen-test-*  # If using mktemp
# Or manually remove your test directory
```

---

**Instructions for LLM:** Execute all test suites in order. For each test, verify the expected behavior and mark PASS/FAIL/SKIP. Provide a complete test report using the template above. Focus on testing as an installed gem (not from source) to simulate real-world usage.
