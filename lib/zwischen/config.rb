# frozen_string_literal: true

require "yaml"
require "fileutils"

module Zwischen
  class Config
    DEFAULT_CONFIG = {
      "ai" => {
        "enabled" => true,
        "provider" => "claude",
        "api_key" => nil
      },
      "blocking" => {
        "severity" => "high"  # high, critical, or none
      },
      "scanners" => {
        "gitleaks" => { "enabled" => true },
        "semgrep" => { "enabled" => true, "config" => "auto" }
      },
      "ignore" => [
        "**/node_modules/**",
        "**/vendor/**",
        "**/.git/**",
        "**/dist/**",
        "**/build/**"
      ],
      "severity" => {
        "fail_on" => ["critical", "high"]
      }
    }.freeze

    CONFIG_FILE = ".zwischen.yml"

    def self.load(project_root = Dir.pwd)
      config_path = File.join(project_root, CONFIG_FILE)
      config = DEFAULT_CONFIG.dup

      if File.exist?(config_path)
        user_config = YAML.safe_load(File.read(config_path))
        config = deep_merge(config, user_config) if user_config
      end

      new(config)
    end

    def self.init(project_root = Dir.pwd)
      config_path = File.join(project_root, CONFIG_FILE)
      example_path = File.join(File.dirname(__dir__), "..", ".zwischen.yml.example")

      if File.exist?(config_path)
        puts "Configuration file already exists at #{config_path}"
        return false
      end

      if File.exist?(example_path)
        FileUtils.cp(example_path, config_path)
        puts "Created #{config_path} from example"
      else
        File.write(config_path, DEFAULT_CONFIG.to_yaml)
        puts "Created #{config_path} with default configuration"
      end

      true
    end

    def initialize(config = {})
      @config = DEFAULT_CONFIG.merge(config)
    end

    def ai_provider
      @config.dig("ai", "provider") || "claude"
    end

    def ai_enabled?
      # Default to true if provider is set, otherwise check explicit enabled flag
      provider = ai_provider
      enabled = @config.dig("ai", "enabled")
      enabled.nil? ? !provider.nil? : enabled
    end

    def ai_api_key
      # Check credentials first, then config
      begin
        require_relative "credentials"
        api_key = Credentials.get_api_key
        return api_key if api_key
      rescue LoadError, NameError
        # Credentials not available, fall through to config
      end
      @config.dig("ai", "api_key")
    end

    def blocking_severity
      @config.dig("blocking", "severity") || "high"
    end

    def scanner_enabled?(scanner)
      @config.dig("scanners", scanner.to_s, "enabled") != false
    end

    def semgrep_config
      @config.dig("scanners", "semgrep", "config") || "auto"
    end

    def ignored_paths
      @config["ignore"] || []
    end

    def fail_on_severities
      @config.dig("severity", "fail_on") || ["critical", "high"]
    end

    private

    def self.deep_merge(base, override)
      base.merge(override) do |_key, base_val, override_val|
        if base_val.is_a?(Hash) && override_val.is_a?(Hash)
          deep_merge(base_val, override_val)
        else
          override_val
        end
      end
    end
  end
end
