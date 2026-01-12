# Zwischen

AI-augmented security scanning CLI for vibe coders. Orchestrates Gitleaks and Semgrep scanners, aggregates findings, and uses AI to prioritize and explain security issues.

## Installation

### From RubyGems (when published)

```bash
gem install zwischen
```

### Local Development

For local development and testing:

```bash
# Clone the repository
git clone https://github.com/zwischen/zwischen.git
cd zwischen

# Install system dependencies (required for native gem compilation)
# On Ubuntu/Debian:
sudo apt-get install ruby3.3-dev build-essential

# Install bundler if not already installed
gem install bundler

# Install dependencies
bundle install

# Build and install the gem locally
gem build zwischen.gemspec
gem install ./zwischen-*.gem

# Or use bundler to run directly without installing
bundle exec bin/zwischen --help

# Run tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/zwischen/project_detector_spec.rb
```

**Note:** If `bundle` command is not found, add the gem bin directory to your PATH:
```bash
export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"
```
Add this line to your `~/.bashrc` or `~/.zshrc` to make it permanent.

## Quick Start

```bash
# Check if required tools are installed
zwischen doctor

# Initialize configuration
zwischen init

# Scan your project
zwischen scan --ai claude
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
zwischen doctor
```

## Configuration

Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY=your_key_here
```

Or use the `--api-key` flag:
```bash
zwischen scan --ai claude --api-key your_key_here
```

## Usage

```bash
# Scan with AI analysis
zwischen scan --ai claude

# Scan specific scanner types only
zwischen scan --only secrets,sast

# Output as JSON
zwischen scan --format json
```

## License

MIT
