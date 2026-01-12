# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Scanrail::Config do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ".load" do
    it "loads default config when no file exists" do
      config = Scanrail::Config.load(temp_dir)
      expect(config.ai_provider).to eq("claude")
      expect(config.scanner_enabled?("gitleaks")).to be true
    end

    it "merges user config with defaults" do
      config_file = File.join(temp_dir, ".scanrail.yml")
      File.write(config_file, <<~YAML)
        scanners:
          gitleaks:
            enabled: false
      YAML

      config = Scanrail::Config.load(temp_dir)
      expect(config.scanner_enabled?("gitleaks")).to be false
      expect(config.scanner_enabled?("semgrep")).to be true
    end
  end

  describe ".init" do
    it "creates config file" do
      result = Scanrail::Config.init(temp_dir)
      expect(result).to be true
      expect(File.exist?(File.join(temp_dir, ".scanrail.yml"))).to be true
    end

    it "does not overwrite existing config" do
      config_file = File.join(temp_dir, ".scanrail.yml")
      File.write(config_file, "existing: true")

      result = Scanrail::Config.init(temp_dir)
      expect(result).to be false
    end
  end
end
