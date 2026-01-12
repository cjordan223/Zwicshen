# frozen_string_literal: true

require "thor"
require_relative "credentials"
require_relative "hooks"
require_relative "config"

module Zwischen
  class Setup
    def self.run
      new.run
    end

    def self.uninstall
      new.uninstall
    end

    def initialize
      @shell = Thor::Shell::Color.new
    end

    def run
      @shell.say("\n🛡️  Zwischen Setup\n", :bold)

      # Check tools
      check_tools

      # Prompt for AI config
      ai_config = prompt_ai_config

      # Save credentials if API key provided
      if ai_config[:api_key]
        Credentials.save(api_key: ai_config[:api_key])
        @shell.say("  ✓ Credentials stored in ~/.zwischen/credentials - never committed", :green)
      end

      # Prompt for hook installation
      hook_installed = prompt_hook_install

      # Prompt for config creation
      config_created = prompt_config_create

      # Success message
      @shell.say("\n✅ Done! Zwischen will scan automatically before each push.\n", :green)
      @shell.say("\nTest it now:")
      @shell.say("  git commit --allow-empty -m \"test zwischen\"")
      @shell.say("  git push")
      @shell.say("\nOr run manually:")
      @shell.say("  zwischen scan")
      @shell.say("\nRun 'zwischen uninstall' to remove the git hook.\n")
    end

    def uninstall
      @shell.say("\n🗑️  Zwischen Uninstall\n", :bold)

      project_root = Dir.pwd
      hook_path = Hooks.hook_path(project_root)

      # Remove hook
      if Hooks.installed?(project_root)
        if @shell.yes?("Remove git hook?", default: true)
          if Hooks.uninstall(project_root)
            @shell.say("  ✓ Removed .git/hooks/pre-push", :green)
          else
            @shell.say("  ✗ Failed to remove hook", :red)
          end
        end
      else
        @shell.say("  ↳ No Zwischen hook found", :yellow)
      end

      # Remove config
      config_path = File.join(project_root, Config::CONFIG_FILE)
      if File.exist?(config_path)
        if @shell.yes?("Remove project config (.zwischen.yml)?", default: false)
          File.delete(config_path)
          @shell.say("  ✓ Removed .zwischen.yml", :green)
        else
          @shell.say("  ↳ Kept .zwischen.yml", :yellow)
        end
      end

      # Remove credentials
      if File.exist?(Credentials.credentials_path)
        if @shell.yes?("Remove global credentials (~/.zwischen/credentials)?", default: false)
          File.delete(Credentials.credentials_path)
          @shell.say("  ✓ Removed credentials", :green)
        else
          @shell.say("  ↳ Kept credentials", :yellow)
        end
      end

      @shell.say("\n✅ Zwischen uninstalled from this project.\n", :green)
    end

    private

    def check_tools
      @shell.say("Checking for required tools...")
      installer = Installer.new

      tools = {
        "gitleaks" => "Secrets detection",
        "semgrep" => "Static analysis"
      }

      all_installed = true

      tools.each do |tool_name, _description|
        installed = installer.check_tool(tool_name)
        version = installer.get_version(tool_name) if installed

        if installed
          @shell.say("  ✓ #{tool_name} (v#{version || 'unknown'})", :green)
        else
          all_installed = false
          @shell.say("  ✗ #{tool_name} - NOT FOUND", :red)
          @shell.say("    → #{installer.preferred_command(tool_name)}", :yellow)
        end
      end

      @shell.say("") # Empty line

      unless all_installed
        @shell.say("⚠️  Some tools are missing. Install them using the commands above.", :yellow)
        @shell.say("")
      end
    end

    def prompt_ai_config
      enabled = @shell.yes?("Enable AI-powered analysis? (recommended)", default: true)

      api_key = nil
      if enabled
        api_key = @shell.ask("Anthropic API key:") do |q|
          q.echo = false # Mask input
        end

        if api_key.nil? || api_key.strip.empty?
          @shell.say("  ⚠️  No API key provided. AI analysis will be disabled.", :yellow)
          enabled = false
        end
      end

      { enabled: enabled, api_key: api_key }
    end

    def prompt_hook_install
      project_root = Dir.pwd
      git_dir = File.join(project_root, ".git")

      unless File.directory?(git_dir)
        @shell.say("⚠️  No .git directory found. Skipping hook installation.", :yellow)
        return false
      end

      hook_path = Hooks.hook_path(project_root)

      if File.exist?(hook_path) && !Hooks.zwischen_hook?(hook_path)
        action = Hooks.handle_existing_hook(hook_path, @shell)
        return false if action == :skip
      end

      if @shell.yes?("Install git pre-push hook?", default: true)
        if Hooks.install(project_root)
          @shell.say("  ✓ Hook installed at .git/hooks/pre-push", :green)
          return true
        else
          @shell.say("  ✗ Failed to install hook", :red)
          return false
        end
      else
        @shell.say("  ↳ Skipping hook installation", :yellow)
        return false
      end
    end

    def prompt_config_create
      project_root = Dir.pwd
      config_path = File.join(project_root, Config::CONFIG_FILE)

      if File.exist?(config_path)
        @shell.say("  ↳ Config file already exists at .zwischen.yml", :yellow)
        return false
      end

      if @shell.yes?("Create project config (.zwischen.yml)?", default: true)
        if Config.init(project_root)
          @shell.say("  ✓ Config created", :green)
          return true
        else
          @shell.say("  ✗ Failed to create config", :red)
          return false
        end
      else
        @shell.say("  ↳ Skipping config creation", :yellow)
        return false
      end
    end
  end
end
