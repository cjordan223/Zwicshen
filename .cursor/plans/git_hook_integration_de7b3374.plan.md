---
name: Git Hook Integration
overview: Add interactive `zwischen init` command, secure credential storage, git pre-push hook installation, and `--pre-push` scan mode with compact output. Includes `zwischen uninstall` command.
todos:
  - id: create_credentials
    content: Create lib/zwischen/credentials.rb for secure API key storage in ~/.zwischen/credentials with 0600 permissions
    status: pending
  - id: create_setup
    content: Create lib/zwischen/setup.rb with interactive setup flow (check tools, prompt AI config, prompt hook install, create config). Include test instructions in success message.
    status: pending
  - id: create_hooks
    content: Create lib/zwischen/hooks.rb for git hook installation/removal. Add zwischen_hook? method that checks for marker comment "Zwischen pre-push hook" to avoid nuking custom hooks.
    status: pending
  - id: create_git_diff
    content: Create lib/zwischen/git_diff.rb for detecting changed files. Implement robust default_branch detection (try remote HEAD, then main, then master, then HEAD).
    status: pending
  - id: update_cli_init
    content: Replace init command in lib/zwischen/cli.rb to call Setup.run() instead of Config.init
    status: pending
  - id: update_cli_scan
    content: Add --pre-push flag to scan command, integrate GitDiff filtering and compact reporter
    status: pending
  - id: add_cli_uninstall
    content: Add uninstall command to lib/zwischen/cli.rb
    status: pending
  - id: update_config
    content: Update lib/zwischen/config.rb to support new blocking.severity and ai.enabled config structure, integrate Credentials
    status: pending
  - id: update_reporter
    content: Add report_compact() method to lib/zwischen/reporter/terminal.rb for pre-push mode with minimal output
    status: pending
  - id: update_orchestrator
    content: Update lib/zwischen/scanner/orchestrator.rb to accept pre_push parameter (still scans full repo)
    status: pending
  - id: update_config_example
    content: Update .zwischen.yml.example to match new config structure with blocking and ai.enabled fields
    status: pending
---

# Git Hook Integration for Zwischen

## Overview

Add a "set it and forget it" mode where Zwischen installs itself as a git pre-push hook. Users run `zwischen init` once, answer a few prompts, and Zwischen automatically scans before every push.

## Architecture

```
zwischen init
  ├─> Setup.check_tools() - Verify gitleaks/semgrep installed
  ├─> Setup.prompt_ai_config() - Ask about AI, collect API key
  ├─> Credentials.save() - Store API key in ~/.zwischen/credentials (0600)
  ├─> Setup.prompt_hook_install() - Ask about git hook
  ├─> Hooks.install() - Create .git/hooks/pre-push
  └─> Config.init() - Create .zwischen.yml

git push
  └─> .git/hooks/pre-push
      └─> zwischen scan --pre-push
          ├─> Scanner::Orchestrator.scan() - Scan entire repo
          ├─> Filter findings to changed files only
          ├─> Reporter::Terminal.report_compact() - Minimal output
          └─> Exit 1 if blocking severity found
```

## Files to Create

### `lib/zwischen/setup.rb` (new)

Interactive setup orchestrator:

- `Setup.run()` - Main entry point for `zwischen init`
- `Setup.check_tools()` - Use `Installer` to verify gitleaks/semgrep, show versions
- `Setup.prompt_ai_config()` - Ask if AI enabled, collect API key via `ask()` (masked input)
- `Setup.prompt_hook_install()` - Check for `.git` directory, ask about hook install
- `Setup.prompt_config_create()` - Ask about creating `.zwischen.yml`
- `Setup.uninstall()` - Interactive uninstall flow (remove hook, optionally remove config/credentials)
- Uses `Thor::Shell` for colored prompts (`yes?`, `ask`, `say`)
- Post-init success message includes test instructions:
  ```
  ✅ Done! Zwischen will scan automatically before each push.
  
  Test it now:
    git commit --allow-empty -m "test zwischen"
    git push
  
  Or run manually:
    zwischen scan
  
  Run 'zwischen uninstall' to remove the git hook.
  ```


### `lib/zwischen/credentials.rb` (new)

Secure credential storage:

- `Credentials.load()` - Load from `~/.zwischen/credentials` (YAML)
- `Credentials.save(api_key:)` - Save with file permissions 0600
- `Credentials.get_api_key()` - Check env var `ANTHROPIC_API_KEY` first, then credentials file, then config
- `Credentials.credentials_path` - Returns `File.join(Dir.home, '.zwischen', 'credentials')`
- Create `~/.zwischen/` directory if missing

### `lib/zwischen/hooks.rb` (new)

Git hook management:

- `Hooks.install(project_root:)` - Create `.git/hooks/pre-push` hook
- `Hooks.uninstall(project_root:)` - Remove hook if it's a Zwischen hook
- `Hooks.installed?(project_root:)` - Check if Zwischen hook exists
- `Hooks.zwischen_hook?(hook_path:)` - Check if hook file contains marker comment "Zwischen pre-push hook" (used by uninstall and installed? to avoid nuking user's custom hooks)
- `Hooks.handle_existing_hook(hook_path:)` - Detect existing hook, prompt: backup/append/skip
- Hook template includes marker comment `# Zwischen pre-push hook - installed by 'zwischen init'`
- Hook template includes `ZWISCHEN_SKIP=1` check and `--no-verify` bypass
- Make hook executable with `File.chmod(0755, hook_path)`

### `lib/zwischen/git_diff.rb` (new)

Git diff utilities for pre-push mode:

- `GitDiff.changed_files(remote:, local:)` - Get list of changed files using `git diff --name-only origin/{branch}...HEAD` (or detect default branch)
- `GitDiff.default_branch()` - Detect default branch robustly:
    - First try: `git remote show origin | grep 'HEAD branch'` (most reliable)
    - Fallback: Check if `main` branch exists locally
    - Fallback: Check if `master` branch exists locally (many older repos still use master)
    - Last resort: Return `'HEAD'`
- `GitDiff.filter_findings(findings:, changed_files:)` - Filter findings array to only include files in changed_files list

## Files to Modify

### `lib/zwischen/cli.rb`

- Replace existing `init` method with new interactive flow calling `Setup.run()`
- Add `uninstall` command:
  ```ruby
  desc "uninstall", "Remove Zwischen git hook and optionally config"
  def uninstall
    Setup.uninstall
  end
  ```

- Modify `scan` method:
        - Add `method_option :"pre-push", type: :boolean, desc: "Pre-push mode (quiet, compact output)"
        - When `--pre-push` flag is set:
                - Pass `pre_push: true` to orchestrator
                - Use `Reporter::Terminal.report_compact()` instead of `report()`
                - Suppress "Scanning..." message if clean
                - Use `GitDiff.changed_files()` to filter findings

### `lib/zwischen/config.rb`

- Add `blocking_severity` method - reads from `config["blocking"]["severity"]` (default: "high")
- Add `ai_enabled?` method - reads from `config["ai"]["enabled"]` (default: true if provider set)
- Update `DEFAULT_CONFIG` to include:
  ```ruby
  "ai" => {
    "enabled" => true,
    "provider" => "claude"
  },
  "blocking" => {
    "severity" => "high"  # high, critical, or none
  }
  ```

- Modify `ai_api_key` to check `Credentials.get_api_key()` as fallback

### `lib/zwischen/scanner/orchestrator.rb`

- Modify `scan()` method to accept `pre_push: false` parameter
- When `pre_push: true`, still scan entire repo (don't limit scope)
- Return all findings (filtering happens in CLI layer)

### `lib/zwischen/reporter/terminal.rb`

- Add `report_compact()` class method for pre-push mode:
        - No summary section
        - Only show blocking findings (based on config blocking severity)
        - Compact format: `SEVERITY file:line\n  message\n  → fix suggestion`
        - Show "Push blocked" message at end if blocking
        - Return exit code 1 if blocking findings, 0 otherwise
- Add `should_block?(finding, blocking_severity)` helper
- Modify `exit_code` to respect config blocking severity

### `.zwischen.yml.example`

Update to match new config structure:

```yaml
ai:
  enabled: true
  provider: claude  # uses key from ~/.zwischen/credentials

blocking:
  severity: high  # block on high or critical

scanners:
  gitleaks: true
  semgrep: true

ignore:
  - vendor/
  - node_modules/
```

## Implementation Details

### Pre-Push Hook Template

```bash
#!/usr/bin/env bash
# Zwischen pre-push hook - installed by 'zwischen init'

if [ "$ZWISCHEN_SKIP" = "1" ]; then
  exit 0
fi

zwischen scan --pre-push
exit $?
```

### Changed Files Detection

- Use `git diff --name-only origin/{default_branch}...HEAD` (detect default branch via `GitDiff.default_branch()`)
- Fallback to `git diff --name-only HEAD@{1}...HEAD` if no remote
- Filter findings: `findings.select { |f| changed_files.include?(f.file) }`

**Note:** Current implementation scans entire repo then filters findings. Future optimization (v1.1): pass changed files directly to scanners for faster performance on large repos:

- `gitleaks detect -- file1.rb file2.rb`
- `semgrep --config auto file1.rb file2.rb`

### Credential Storage

- Path: `~/.zwischen/credentials`
- Format: YAML with `anthropic_api_key: sk-ant-xxxxx`
- Permissions: 0600 (read/write owner only)
- Never committed (outside project directory)

### Blocking Logic

- Config `blocking.severity` values:
        - `"high"` - block on high or critical (default)
        - `"critical"` - block only on critical
        - `"none"` - never block, just warn
- Exit code 0 = push proceeds, 1 = push blocked

### Edge Cases

- No `.git` directory → skip hook installation, warn user
- Existing pre-push hook → check if it's a Zwischen hook (via marker comment), if not prompt: backup (rename to `.pre-push.zwischen.backup`), append (add Zwischen check), or skip
- Missing API key when AI enabled → warn but continue without AI
- Scanner not installed → skip that scanner, show warning once
- Non-interactive mode (no TTY) → use env vars, skip prompts
- No remote branch → use local diff `HEAD@{1}...HEAD`
- Default branch detection → handle `main`, `master`, or other branch names robustly

## Testing Considerations

- Test `init` flow with/without existing config
- Test hook installation with existing hook (both Zwischen and custom hooks)
- Test hook detection via marker comment (not just file existence)
- Test default branch detection (main, master, other branches)
- Test pre-push mode with clean repo vs. findings
- Test credential storage permissions
- Test blocking severity levels
- Test changed files filtering
- Test `uninstall` command (only removes Zwischen hooks, preserves custom hooks)

## Dependencies

No new gem dependencies required. Uses existing:

- `thor` for CLI (already has `Thor::Shell` for prompts)
- `yaml` for credential storage
- `fileutils` for file operations