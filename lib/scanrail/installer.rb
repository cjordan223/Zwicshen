# frozen_string_literal: true

require "open3"
require "rbconfig"

module Scanrail
  class Installer
    PLATFORMS = {
      darwin: "macos",
      linux: "linux",
      mingw: "windows",
      mswin: "windows"
    }.freeze

    INSTALL_COMMANDS = {
      gitleaks: {
        macos: {
          brew: "brew install gitleaks",
          pip: "pip install gitleaks",
          manual: "Visit https://github.com/gitleaks/gitleaks/releases"
        },
        linux: {
          brew: "brew install gitleaks",
          pip: "pip install gitleaks",
          manual: "Visit https://github.com/gitleaks/gitleaks/releases"
        },
        windows: {
          manual: "Visit https://github.com/gitleaks/gitleaks/releases"
        }
      },
      semgrep: {
        macos: {
          brew: "brew install semgrep",
          pip: "pip install semgrep",
          manual: "Visit https://semgrep.dev/docs/getting-started/"
        },
        linux: {
          pip: "pip install semgrep",
          brew: "brew install semgrep",
          manual: "Visit https://semgrep.dev/docs/getting-started/"
        },
        windows: {
          pip: "pip install semgrep",
          manual: "Visit https://semgrep.dev/docs/getting-started/"
        }
      }
    }.freeze

    def self.platform
      new.platform
    end

    def self.install_commands(tool, platform = nil)
      new.install_commands(tool, platform)
    end

    def platform
      os = PLATFORMS[RbConfig::CONFIG["host_os"].downcase.to_sym] || "unknown"
      os
    end

    def install_commands(tool, platform = nil)
      platform ||= self.platform
      INSTALL_COMMANDS.dig(tool.to_sym, platform.to_sym) || {}
    end

    def preferred_command(tool, platform = nil)
      platform ||= self.platform
      commands = install_commands(tool, platform)

      # Prefer brew on macOS, pip on Linux
      if platform == "macos" && commands[:brew]
        commands[:brew]
      elsif commands[:pip]
        commands[:pip]
      elsif commands[:brew]
        commands[:brew]
      else
        commands[:manual]
      end
    end

    def check_tool(tool_name)
      system("which", tool_name, out: File::NULL, err: File::NULL)
    end

    def get_version(tool_name)
      return nil unless check_tool(tool_name)

      stdout, _stderr, status = Open3.capture3(tool_name, "--version")
      return nil unless status.success?

      stdout.strip.split("\n").first
    rescue StandardError
      nil
    end
  end
end
