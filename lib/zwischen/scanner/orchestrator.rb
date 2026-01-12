# frozen_string_literal: true

require_relative "gitleaks"
require_relative "semgrep"

module Zwischen
  module Scanner
    class Orchestrator
      def initialize(config:)
        @config = config
        @scanners = build_scanners
      end

      def scan(project_root = Dir.pwd, only: nil, pre_push: false)
        enabled_scanners = select_scanners(only)
        available_scanners = enabled_scanners.select(&:available?)

        if available_scanners.empty?
          warn "No scanners available. Run 'zwischen doctor' to check installation." unless pre_push
          return []
        end

        # Run scanners in parallel using threads
        threads = available_scanners.map do |scanner|
          Thread.new do
            [scanner.name, scanner.scan(project_root)]
          end
        end

        results = {}
        threads.each do |thread|
          scanner_name, findings = thread.value
          results[scanner_name] = findings
        end

        # Flatten all findings
        # Note: In pre-push mode, we still scan entire repo, filtering happens in CLI layer
        results.values.flatten
      end

      def available_scanners
        @scanners.select(&:available?)
      end

      def missing_scanners
        @scanners.reject(&:available?)
      end

      private

      def build_scanners
        scanners = []

        scanners << Gitleaks.new if @config.scanner_enabled?("gitleaks")
        scanners << Semgrep.new(config: @config.semgrep_config) if @config.scanner_enabled?("semgrep")

        scanners
      end

      def select_scanners(only)
        return @scanners if only.nil? || only.empty?

        only_list = only.split(",").map(&:strip)
        scanner_map = {
          "secrets" => "gitleaks",
          "sast" => "semgrep"
        }

        selected = only_list.map { |name| scanner_map[name.downcase] }.compact

        @scanners.select { |s| selected.include?(s.name) }
      end
    end
  end
end
