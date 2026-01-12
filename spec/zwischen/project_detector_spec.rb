# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Zwischen::ProjectDetector do
  let(:temp_dir) { Dir.mktmpdir }
  let(:detector) { Zwischen::ProjectDetector.new(temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ".detect" do
    it "detects Node.js projects" do
      File.write(File.join(temp_dir, "package.json"), '{"name": "test"}')
      result = detector.detect
      expect(result[:types]).to include("node")
      expect(result[:primary_type]).to eq("node")
    end

    it "detects Python projects" do
      File.write(File.join(temp_dir, "requirements.txt"), "requests==2.0")
      result = detector.detect
      expect(result[:types]).to include("python")
    end

    it "detects Ruby projects" do
      File.write(File.join(temp_dir, "Gemfile"), 'source "https://rubygems.org"')
      result = detector.detect
      expect(result[:types]).to include("ruby")
    end

    it "returns unknown for empty directories" do
      result = detector.detect
      expect(result[:primary_type]).to be_nil
      expect(result[:language]).to eq("unknown")
    end
  end
end
