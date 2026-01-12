# frozen_string_literal: true

require "colorize"
require_relative "../finding/finding"

module Scanrail
  module Reporter
    class Terminal
      SEVERITY_COLORS = {
        "critical" => :red,
        "high" => :red,
        "medium" => :yellow,
        "low" => :blue,
        "info" => :cyan
      }.freeze

      SEVERITY_BADGES = {
        "critical" => "🔴 CRITICAL",
        "high" => "🔴 HIGH",
        "medium" => "🟡 MEDIUM",
        "low" => "🔵 LOW",
        "info" => "ℹ️  INFO"
      }.freeze

      def self.report(aggregated_results, ai_enabled: false)
        new(aggregated_results, ai_enabled: ai_enabled).report
      end

      def initialize(aggregated_results, ai_enabled: false)
        @results = aggregated_results
        @ai_enabled = ai_enabled
      end

      def report
        print_summary
        print_findings
        exit_code
      end

      private

      def print_summary
        summary = @results[:summary]
        puts "\n" + "=" * 60
        puts "Scanrail Security Scan Results".colorize(:bold)
        puts "=" * 60
        puts "\nTotal Findings: #{summary[:total]}".colorize(:bold)

        if summary[:by_severity].any?
          puts "\nBy Severity:"
          summary[:by_severity].each do |severity, count|
            color = SEVERITY_COLORS[severity] || :white
            puts "  #{severity.capitalize}: #{count}".colorize(color)
          end
        end

        puts "\n" + "-" * 60
      end

      def print_findings
        findings = @results[:findings]
        return if findings.empty?

        puts "\nFindings:\n\n"

        @results[:grouped].each do |file, file_findings|
          puts "📄 #{file}".colorize(:bold)
          puts "-" * 60

          file_findings.each do |finding|
            print_finding(finding)
          end

          puts "\n"
        end
      end

      def print_finding(finding)
        # Skip false positives if AI analysis marked them
        if @ai_enabled && finding.raw_data["ai_false_positive"]
          puts "  ⚠️  [FALSE POSITIVE] #{finding.message}".colorize(:light_black)
          return
        end

        severity_color = SEVERITY_COLORS[finding.severity] || :white
        badge = SEVERITY_BADGES[finding.severity] || finding.severity.upcase

        puts "  #{badge}".colorize(severity_color) + " #{finding.file}:#{finding.line || '?'}"
        puts "    #{finding.message}"

        if finding.rule_id
          puts "    Rule: #{finding.rule_id}".colorize(:light_black)
        end

        if finding.code_snippet
          snippet = finding.code_snippet.split("\n").first(3).join("\n")
          puts "    Code:".colorize(:light_black)
          puts "    #{snippet}".colorize(:light_black)
        end

        # AI recommendations
        if @ai_enabled && finding.raw_data["ai_fix_suggestion"]
          puts "    💡 Fix: #{finding.raw_data['ai_fix_suggestion']}".colorize(:green)
        end

        if @ai_enabled && finding.raw_data["ai_risk_explanation"]
          puts "    ⚠️  Risk: #{finding.raw_data['ai_risk_explanation']}".colorize(:yellow)
        end

        puts ""
      end

      def exit_code
        findings = @results[:findings]
        critical_or_high = findings.any? { |f| f.should_fail? && !(@ai_enabled && f.raw_data["ai_false_positive"]) }

        critical_or_high ? 1 : 0
      end
    end
  end
end
