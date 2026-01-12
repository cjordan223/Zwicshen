# frozen_string_literal: true

module Scanrail
  module Finding
    class Finding
      attr_reader :type, :scanner, :severity, :file, :line, :message, :rule_id, :code_snippet, :raw_data

      SEVERITY_LEVELS = %w[critical high medium low info].freeze

      def initialize(
        type:,
        scanner:,
        severity:,
        file:,
        line: nil,
        message:,
        rule_id: nil,
        code_snippet: nil,
        raw_data: {}
      )
        @type = type.to_s
        @scanner = scanner.to_s
        @severity = normalize_severity(severity)
        @file = file.to_s
        @line = line
        @message = message.to_s
        @rule_id = rule_id.to_s if rule_id
        @code_snippet = code_snippet
        @raw_data = raw_data
      end

      def to_h
        {
          type: @type,
          scanner: @scanner,
          severity: @severity,
          file: @file,
          line: @line,
          message: @message,
          rule_id: @rule_id,
          code_snippet: @code_snippet,
          raw_data: @raw_data
        }
      end

      def to_json(*args)
        require "json" unless defined?(JSON)
        to_h.to_json(*args)
      end

      def critical?
        @severity == "critical"
      end

      def high?
        @severity == "high"
      end

      def should_fail?
        critical? || high?
      end

      private

      def normalize_severity(severity)
        sev = severity.to_s.downcase
        return sev if SEVERITY_LEVELS.include?(sev)

        # Map common variations
        case sev
        when /critical|error|fatal/
          "critical"
        when /high|major/
          "high"
        when /medium|moderate|warning/
          "medium"
        when /low|minor|info/
          "low"
        else
          "info"
        end
      end
    end
  end
end
