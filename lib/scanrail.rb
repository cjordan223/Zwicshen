# frozen_string_literal: true

require_relative "scanrail/version"

module Scanrail
  class Error < StandardError; end
end

# Load all modules when gem is required
require_relative "scanrail/config"
require_relative "scanrail/project_detector"
require_relative "scanrail/finding/finding"
require_relative "scanrail/finding/aggregator"
require_relative "scanrail/scanner/base"
require_relative "scanrail/scanner/gitleaks"
require_relative "scanrail/scanner/semgrep"
require_relative "scanrail/scanner/orchestrator"
require_relative "scanrail/installer"
require_relative "scanrail/ai/claude_client"
require_relative "scanrail/ai/analyzer"
require_relative "scanrail/reporter/terminal"
require_relative "scanrail/cli"
