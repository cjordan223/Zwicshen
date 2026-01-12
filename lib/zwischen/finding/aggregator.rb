# frozen_string_literal: true

require_relative "finding"

module Zwischen
  module Finding
    class Aggregator
      SEVERITY_ORDER = { "critical" => 0, "high" => 1, "medium" => 2, "low" => 3, "info" => 4 }.freeze

      def self.aggregate(findings)
        new.aggregate(findings)
      end

      def aggregate(findings)
        normalized = normalize_severities(findings)
        deduplicated = deduplicate(normalized)
        sorted = sort_by_severity(deduplicated)
        grouped = group_by_file(sorted)

        {
          findings: sorted,
          grouped: grouped,
          summary: build_summary(sorted)
        }
      end

      private

      def normalize_severities(findings)
        findings.map do |finding|
          # Severity is already normalized in Finding class
          finding
        end
      end

      def deduplicate(findings)
        seen = {}
        findings.select do |finding|
          key = "#{finding.file}:#{finding.line}:#{finding.rule_id}"
          if seen[key]
            false
          else
            seen[key] = true
            true
          end
        end
      end

      def sort_by_severity(findings)
        findings.sort_by do |finding|
          [
            SEVERITY_ORDER[finding.severity] || 99,
            finding.file,
            finding.line || 0
          ]
        end
      end

      def group_by_file(findings)
        findings.group_by(&:file)
      end

      def build_summary(findings)
        summary = {
          total: findings.length,
          by_severity: {}
        }

        Finding::SEVERITY_LEVELS.each do |severity|
          count = findings.count { |f| f.severity == severity }
          summary[:by_severity][severity] = count if count > 0
        end

        summary
      end
    end
  end
end
