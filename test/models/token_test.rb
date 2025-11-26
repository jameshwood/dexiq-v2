require "test_helper"

class TokenTest < ActiveSupport::TestCase
  # TODO: Add tests for Token model

  test "should validate presence of chain_id" do
    token = Token.new(pool_address: "0xabc123")
    assert_not token.valid?
    assert_includes token.errors[:chain_id], "can't be blank"
  end

  test "should validate presence of pool_address" do
    token = Token.new(chain_id: "eth")
    assert_not token.valid?
    assert_includes token.errors[:pool_address], "can't be blank"
  end

  test "should enforce uniqueness of chain_id and pool_address combination" do
    user = users(:one) # Assumes you have fixtures
    Token.create!(chain_id: "eth", pool_address: "0xabc123", user: user)

    duplicate = Token.new(chain_id: "eth", pool_address: "0xabc123", user: user)
    assert_not duplicate.valid?
  end

  test "should have associations" do
    token = Token.new
    assert_respond_to token, :user
    assert_respond_to token, :dexscreener_snapshots
    assert_respond_to token, :gecko_terminal_snapshots
    assert_respond_to token, :purchase_logs
  end

  # TODO: Add tests for:
  # - find_or_create_by_pool! method
  # - latest_dexscreener_snapshot
  # - data_readiness_tier
  # - current_position
end
