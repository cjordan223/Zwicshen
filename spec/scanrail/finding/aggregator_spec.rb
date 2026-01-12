# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scanrail::Finding::Aggregator do
  let(:finding1) do
    Scanrail::Finding::Finding.new(
      type: "secret",
      scanner: "gitleaks",
      severity: "critical",
      file: "test.rb",
      line: 10,
      message: "API key",
      rule_id: "rule1"
    )
  end

  let(:finding2) do
    Scanrail::Finding::Finding.new(
      type: "sast",
      scanner: "semgrep",
      severity: "high",
      file: "test.rb",
      line: 20,
      message: "SQL injection",
      rule_id: "rule2"
    )
  end

  describe ".aggregate" do
    it "aggregates findings" do
      result = Scanrail::Finding::Aggregator.aggregate([finding1, finding2])

      expect(result[:findings].length).to eq(2)
      expect(result[:summary][:total]).to eq(2)
      expect(result[:summary][:by_severity]["critical"]).to eq(1)
      expect(result[:summary][:by_severity]["high"]).to eq(1)
    end

    it "deduplicates findings" do
      duplicate = Scanrail::Finding::Finding.new(
        type: "secret",
        scanner: "gitleaks",
        severity: "critical",
        file: "test.rb",
        line: 10,
        message: "API key",
        rule_id: "rule1"
      )

      result = Scanrail::Finding::Aggregator.aggregate([finding1, duplicate])
      expect(result[:findings].length).to eq(1)
    end

    it "sorts by severity" do
      result = Scanrail::Finding::Aggregator.aggregate([finding2, finding1])
      expect(result[:findings].first.severity).to eq("critical")
    end

    it "groups by file" do
      result = Scanrail::Finding::Aggregator.aggregate([finding1, finding2])
      expect(result[:grouped]["test.rb"].length).to eq(2)
    end
  end
end
