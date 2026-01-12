# Scanrail

AI-augmented security scanning CLI for vibe coders. Orchestrates Gitleaks and Semgrep scanners, aggregates findings, and uses AI to prioritize and explain security issues.

## Installation

```bash
gem install scanrail
```

## Quick Start

```bash
# Check if required tools are installed
scanrail doctor

# Initialize configuration
scanrail init

# Scan your project
scanrail scan --ai claude
```

## Features

- **Unified Security Scanning**: Wraps Gitleaks (secrets detection) and Semgrep (static analysis)
- **AI-Powered Analysis**: Uses Claude API to prioritize findings, filter false positives, and suggest fixes
- **Language Agnostic**: Works with Node.js, Python, Ruby, Go, Java, Rust, and more
- **Zero Configuration**: Auto-detects project type and adjusts accordingly

## Requirements

- Ruby 3.3+
- Gitleaks (for secrets detection)
- Semgrep (for static analysis)

Install missing tools with:
```bash
scanrail doctor
```

## Configuration

Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY=your_key_here
```

Or use the `--api-key` flag:
```bash
scanrail scan --ai claude --api-key your_key_here
```

## Usage

```bash
# Scan with AI analysis
scanrail scan --ai claude

# Scan specific scanner types only
scanrail scan --only secrets,sast

# Output as JSON
scanrail scan --format json
```

## License

MIT
