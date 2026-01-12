# frozen_string_literal: true

require "open3"

module Zwischen
  module Scanner
    class Base
      attr_reader :name, :command

      def initialize(name:, command:)
        @name = name
        @command = command
      end

      def available?
        system("which", @command, out: File::NULL, err: File::NULL)
      end

      def scan(project_root = Dir.pwd)
        return [] unless available?

        stdout, stderr, status = Open3.capture3(*build_command(project_root), chdir: project_root)

        if status.success?
          parse_output(stdout)
        else
          warn "Warning: #{@name} scan failed: #{stderr}" unless stderr.empty?
          []
        end
      rescue StandardError => e
        warn "Error running #{@name}: #{e.message}"
        []
      end

      def parse_output(_output)
        raise NotImplementedError, "Subclasses must implement parse_output"
      end

      protected

      def build_command(_project_root)
        raise NotImplementedError, "Subclasses must implement build_command"
      end

      def read_file_snippet(file_path, line_number, context_lines = 3)
        return nil unless File.exist?(file_path)

        lines = File.readlines(file_path)
        start_line = [0, line_number - context_lines - 1].max
        end_line = [lines.length - 1, line_number + context_lines - 1].min

        lines[start_line..end_line].join
      rescue StandardError
        nil
      end
    end
  end
end
