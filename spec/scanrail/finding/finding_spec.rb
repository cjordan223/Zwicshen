# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scanrail::Finding::Finding do
  describe "#initialize" do
    it "creates a finding with all attributes" do
      finding = Scanrail::Finding::Finding.new(
        type: "secret",
        scanner: "gitleaks",
        severity: "high",
        file: "test.rb",
        line: 42,
        message: "API key detected",
        rule_id: "gitleaks.aws-key"
      )

      expect(finding.type).to eq("secret")
      expect(finding.scanner).to eq("gitleaks")
      expect(finding.severity).to eq("high")
      expect(finding.file).to eq("test.rb")
      expect(finding.line).to eq(42)
      expect(finding.message).to eq("API key detected")
      expect(finding.rule_id).to eq("gitleaks.aws-key")
    end

    it "normalizes severity levels" do
      finding = Scanrail::Finding::Finding.new(
        type: "sast",
        scanner: "semgrep",
        severity: "ERROR",
        file: "test.rb",
        message: "Test"
      )

      expect(finding.severity).to eq("critical")
    end

    it "identifies critical findings" do
      finding = Scanrail::Finding::Finding.new(
        type: "secret",
        scanner: "gitleaks",
        severity: "critical",
        file: "test.rb",
        message: "Test"
      )

      expect(finding.critical?).to be true
      expect(finding.should_fail?).to be true
    end
  end

  describe "#to_h" do
    it "converts finding to hash" do
      finding = Scanrail::Finding::Finding.new(
        type: "secret",
        scanner: "gitleaks",
        severity: "high",
        file: "test.rb",
        line: 42,
        message: "Test"
      )

      hash = finding.to_h
      expect(hash[:type]).to eq("secret")
      expect(hash[:severity]).to eq("high")
    end
  end
end
