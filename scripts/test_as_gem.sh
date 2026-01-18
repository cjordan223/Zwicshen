#!/bin/bash
# test_as_gem.sh - Build and install Zwischen gem for testing
#
# This script builds the gem and installs it locally, mimicking
# a real RubyGems installation for testing purposes.
#
# Usage:
#   ./scripts/test_as_gem.sh
#   ./scripts/test_as_gem.sh --system  # Install system-wide (requires sudo)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "🔨 Building Zwischen gem..."
gem build zwischen.gemspec

GEM_FILE=$(ls -t zwischen-*.gem | head -n1)
echo "✅ Built: $GEM_FILE"

if [[ "$1" == "--system" ]]; then
    echo "📦 Installing system-wide (requires sudo)..."
    sudo gem install "$GEM_FILE"
    INSTALL_PATH=$(gem which zwischen | sed 's|/lib/zwischen.rb||')
    echo "✅ Installed to: $INSTALL_PATH"
    echo ""
    echo "Run: zwischen --help"
else
    echo "📦 Installing to user directory..."
    gem install --user-install "$GEM_FILE"
    
    RUBY_VERSION=$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')
    GEM_BIN_PATH="$HOME/.local/share/gem/ruby/$RUBY_VERSION/bin"
    
    echo "✅ Installed to user directory"
    echo ""
    echo "📝 Add to your PATH:"
    echo "   export PATH=\"$GEM_BIN_PATH:\$PATH\""
    echo ""
    echo "Or add to ~/.bashrc or ~/.zshrc:"
    echo "   echo 'export PATH=\"$GEM_BIN_PATH:\$PATH\"' >> ~/.bashrc"
    echo ""
    echo "Then run:"
    echo "   source ~/.bashrc  # or restart terminal"
    echo "   zwischen --help"
fi

echo ""
echo "🧪 To test in a separate directory:"
echo "   cd /tmp && mkdir zwischen-test && cd zwischen-test  # or any test directory"
echo "   git init && echo '# Test' > README.md && git add . && git commit -m 'Initial'"
echo "   zwischen init"
echo ""
echo "🧹 To uninstall later:"
if [[ "$1" == "--system" ]]; then
    echo "   sudo gem uninstall zwischen"
else
    echo "   gem uninstall zwischen --user-install"
fi
