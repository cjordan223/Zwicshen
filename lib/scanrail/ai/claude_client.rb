# frozen_string_literal: true

require "faraday"
require "json"

module Scanrail
  module AI
    class Error < StandardError; end

    class ClaudeClient
      API_BASE_URL = "https://api.anthropic.com/v1"
      API_VERSION = "2023-06-01"

      def initialize(api_key: nil)
        @api_key = resolve_api_key(api_key)
        raise Error, "Claude API key not found. Set ANTHROPIC_API_KEY env var or use --api-key flag" unless @api_key

        @client = Faraday.new(url: API_BASE_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def analyze(prompt, model: "claude-3-5-sonnet-20241022")
        response = @client.post("/messages") do |req|
          req.headers["x-api-key"] = @api_key
          req.headers["anthropic-version"] = API_VERSION
          req.body = {
            model: model,
            max_tokens: 4096,
            messages: [
              {
                role: "user",
                content: prompt
              }
            ]
          }
        end

        if response.success?
          response.body.dig("content", 0, "text")
        else
          error_message = response.body.dig("error", "message") || "Unknown error"
          raise Error, "Claude API error: #{error_message}"
        end
      rescue Faraday::Error => e
        raise Error, "Network error: #{e.message}"
      end

      private

      def resolve_api_key(provided_key)
        return provided_key if provided_key && !provided_key.empty?

        ENV["ANTHROPIC_API_KEY"] || ENV["GUARDRAIL_API_KEY"]
      end
    end
  end
end
