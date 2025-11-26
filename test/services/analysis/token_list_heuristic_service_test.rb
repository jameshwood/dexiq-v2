require "test_helper"

module Analysis
  class TokenListHeuristicServiceTest < ActiveSupport::TestCase
    test "should analyze token list" do
      tokens_data = [
        {
          tokenName: "TestToken",
          price: 0.5,
          volume: 1_000_000,
          change5m: 5.0,
          change1h: 10.0,
          change24h: 25.0,
          liquidity: 500_000
        }
      ]

      service = TokenListHeuristicService.new(tokens_data)
      result = service.analyze

      assert_equal 1, result.length
      assert_equal "TestToken", result.first[:tokenName]
      assert result.first[:score].is_a?(Numeric)
      assert_includes ["low", "medium", "high"], result.first[:risk]
    end

    test "should assign higher scores to tokens with good metrics" do
      high_volume_token = {
        tokenName: "HighVolume",
        price: 1.0,
        volume: 5_000_000,
        liquidity: 2_000_000,
        change24h: 50.0
      }

      low_volume_token = {
        tokenName: "LowVolume",
        price: 1.0,
        volume: 10_000,
        liquidity: 5_000,
        change24h: 5.0
      }

      service = TokenListHeuristicService.new([high_volume_token, low_volume_token])
      results = service.analyze

      high_score = results.find { |r| r[:tokenName] == "HighVolume" }[:score]
      low_score = results.find { |r| r[:tokenName] == "LowVolume" }[:score]

      assert high_score > low_score
    end

    # TODO: Add tests for:
    # - Risk assessment accuracy
    # - Sentiment determination
    # - Edge cases (zero values, negative changes, etc.)
  end
end
