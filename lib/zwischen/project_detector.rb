# frozen_string_literal: true

module Zwischen
  class ProjectDetector
    DETECTION_PATTERNS = {
      "node" => ["package.json"],
      "python" => ["requirements.txt", "pyproject.toml", "setup.py", "Pipfile", "poetry.lock"],
      "ruby" => ["Gemfile", "Rakefile"],
      "go" => ["go.mod", "go.sum"],
      "java" => ["pom.xml", "build.gradle", "build.gradle.kts"],
      "rust" => ["Cargo.toml", "Cargo.lock"],
      "php" => ["composer.json"],
      "dotnet" => ["*.csproj", "*.sln", "*.fsproj"]
    }.freeze

    def self.detect(project_root = Dir.pwd)
      new(project_root).detect
    end

    def initialize(project_root = Dir.pwd)
      @project_root = project_root
    end

    def detect
      detected_types = []

      DETECTION_PATTERNS.each do |type, patterns|
        if patterns.any? { |pattern| matches_pattern?(pattern) }
          detected_types << type
        end
      end

      {
        types: detected_types,
        primary_type: detected_types.first,
        language: primary_language(detected_types),
        root: @project_root
      }
    end

    private

    def matches_pattern?(pattern)
      if pattern.include?("*")
        # Glob pattern
        Dir.glob(File.join(@project_root, pattern)).any?
      else
        # Exact file
        File.exist?(File.join(@project_root, pattern))
      end
    end

    def primary_language(types)
      return types.first if types.any?

      # Default fallback
      "unknown"
    end
  end
end
