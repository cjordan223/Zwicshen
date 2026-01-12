# frozen_string_literal: true

require "yaml"
require "fileutils"

module Zwischen
  class Credentials
    def self.credentials_path
      File.join(Dir.home, ".zwischen", "credentials")
    end

    def self.ensure_directory
      dir = File.dirname(credentials_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
    end

    def self.load
      return {} unless File.exist?(credentials_path)

      YAML.safe_load(File.read(credentials_path)) || {}
    rescue StandardError => e
      warn "Failed to load credentials: #{e.message}"
      {}
    end

    def self.save(api_key: nil)
      ensure_directory

      credentials = load
      credentials["anthropic_api_key"] = api_key if api_key

      File.write(credentials_path, credentials.to_yaml)
      File.chmod(0o600, credentials_path)
    rescue StandardError => e
      warn "Failed to save credentials: #{e.message}"
      raise
    end

    def self.get_api_key
      # Priority: ENV var > credentials file > config
      return ENV["ANTHROPIC_API_KEY"] if ENV["ANTHROPIC_API_KEY"]

      credentials = load
      return credentials["anthropic_api_key"] if credentials["anthropic_api_key"]

      nil
    end
  end
end
