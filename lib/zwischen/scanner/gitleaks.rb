# frozen_string_literal: true

require_relative "base"
require "json"
require_relative "../finding/finding"

module Zwischen
  module Scanner
    class Gitleaks < Base
      def initialize
        super(name: "gitleaks", command: "gitleaks")
      end

      def build_command(project_root)
        [
          "gitleaks", "detect",
          "--source", project_root,
          "--format", "json",
          "--no-git"
        ]
      end

      def scan_files(files, project_root)
        findings = []
        commands = build_command_for_files(files, project_root)

        commands.each do |command|
          stdout, stderr, status = Open3.capture3(*command, chdir: project_root)
          if status.success?
            next if stdout.strip.empty?
            findings.concat(parse_output(stdout))
          else
            warn "Warning: #{@name} scan failed: #{stderr}" unless stderr.empty?
          end
        end

        findings
      rescue StandardError => e
        warn "Error running #{@name}: #{e.message}"
        []
      end

      def parse_output(output)
        return [] if output.strip.empty?

        findings = []
        json_data = JSON.parse(output)

        # Gitleaks returns an array of findings
        Array(json_data).each do |finding|
          findings << Zwischen::Finding::Finding.new(
            type: "secret",
            scanner: "gitleaks",
            severity: map_severity(finding["RuleID"]),
            file: finding["File"],
            line: finding["StartLine"],
            message: finding["RuleID"] || "Secret detected",
            rule_id: finding["RuleID"],
            code_snippet: finding["Secret"],
            raw_data: finding
          )
        end

        findings
      rescue JSON::ParserError => e
        warn "Failed to parse Gitleaks output: #{e.message}"
        []
      end

      private

      def build_command_for_files(files, project_root)
        files.map do |file|
          [
            "gitleaks", "detect",
            "--source", File.join(project_root, file),
            "--format", "json",
            "--no-git"
          ]
        end
      end

      def map_severity(rule_id)
        # Gitleaks doesn't provide severity, so we map based on rule type
        case rule_id.to_s.downcase
        when /aws.*key|api.*key|private.*key|secret.*key/
          "critical"
        when /password|token|credential/
          "high"
        when /key|secret/
          "medium"
        else
          "medium"
        end
      end
    end
  end
end
