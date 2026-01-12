# frozen_string_literal: true

require "thor"
require "json"
require "colorize"
require_relative "scanrail"

module Scanrail
  class CLI < Thor
    desc "init", "Initialize Scanrail configuration"
    def init
      if Config.init
        puts "\n✅ Configuration initialized!"
        puts "Edit .scanrail.yml to customize settings."
      end
    end

    desc "doctor", "Check if required tools are installed"
    def doctor
      installer = Installer.new
      puts "\n" + "=" * 60
      puts "Scanrail Doctor - Tool Status".colorize(:bold)
      puts "=" * 60 + "\n"

      tools = {
        "gitleaks" => "Secrets detection",
        "semgrep" => "Static analysis"
      }

      all_installed = true

      tools.each do |tool_name, description|
        installed = installer.check_tool(tool_name)
        version = installer.get_version(tool_name) if installed

        if installed
          puts "✓ #{tool_name}".colorize(:green) + " - #{description}"
          puts "  Version: #{version}" if version
        else
          all_installed = false
          puts "✗ #{tool_name}".colorize(:red) + " - #{description} - NOT FOUND"
          puts "  → #{installer.preferred_command(tool_name)}"
        end
        puts ""
      end

      if all_installed
        puts "✅ All tools are installed and ready!".colorize(:green)
      else
        puts "⚠️  Some tools are missing. Install them using the commands above.".colorize(:yellow)
      end

      puts ""
    end

    desc "scan", "Run security scan"
    method_option :only, type: :string, desc: "Only run specific scanners (secrets,sast)"
    method_option :ai, type: :string, desc: "Enable AI analysis (claude)"
    method_option :"api-key", type: :string, desc: "API key for AI provider"
    method_option :format, type: :string, default: "terminal", desc: "Output format (terminal, json)"
    def scan
      config = Config.load
      project = ProjectDetector.detect

      puts "🔍 Scanning #{project[:primary_type] || 'project'}...\n"

      # Run scanners
      orchestrator = Scanner::Orchestrator.new(config: config)
      findings = orchestrator.scan(project[:root], only: options[:only])

      if findings.empty?
        puts "\n✅ No security findings detected!".colorize(:green)
        exit 0
      end

      # Aggregate findings
      aggregated = Finding::Aggregator.aggregate(findings)

      # AI analysis if enabled
      ai_enabled = !options[:ai].nil? && !options[:ai].empty?
      if ai_enabled
        begin
          puts "🤖 Analyzing findings with AI...\n"
          analyzer = AI::Analyzer.new(
            api_key: options[:"api-key"],
            project_context: project
          )
          enhanced_findings = analyzer.analyze(aggregated[:findings])
          aggregated = Finding::Aggregator.aggregate(enhanced_findings)
        rescue AI::Error => e
          warn "⚠️  AI analysis unavailable: #{e.message}"
          warn "Continuing with non-AI results..."
        end
      end

      # Report results
      if options[:format] == "json"
        require "json"
        puts JSON.pretty_generate({
          summary: aggregated[:summary],
          findings: aggregated[:findings].map(&:to_h)
        })
        exit aggregated[:findings].any? { |f| f.should_fail? && !(ai_enabled && f.raw_data["ai_false_positive"]) } ? 1 : 0
      else
        exit_code = Reporter::Terminal.report(aggregated, ai_enabled: ai_enabled)
        exit exit_code
      end
    rescue StandardError => e
      puts "❌ Error: #{e.message}".colorize(:red)
      puts e.backtrace if ENV["DEBUG"]
      exit 1
    end

    default_task :scan
  end
end
