# frozen_string_literal: true

# Token represents a blockchain token/pair tracked by DexIQ
# Identified uniquely by chain_id + pool_address
class Token < ApplicationRecord
  belongs_to :user

  has_many :dexscreener_snapshots, dependent: :destroy
  has_many :gecko_terminal_snapshots, dependent: :destroy
  has_many :gecko_ohlcv_snapshots, dependent: :destroy
  has_many :purchase_logs, dependent: :destroy
  has_many :ai_chat_interactions, dependent: :destroy

  validates :chain_id, presence: true
  validates :pool_address, presence: true
  validates :chain_id, uniqueness: { scope: :pool_address, message: "and pool_address combination must be unique" }

  # Find or create a token idempotently
  def self.find_or_create_by_pool!(chain_id:, pool_address:, user:, **attributes)
    find_or_create_by!(chain_id: chain_id, pool_address: pool_address) do |token|
      token.user = user
      token.assign_attributes(attributes)
    end
  end

  # Get the most recent snapshot of each type
  def latest_dexscreener_snapshot
    dexscreener_snapshots.order(created_at: :desc).first
  end

  def latest_gecko_terminal_snapshot(role = 'base')
    gecko_terminal_snapshots.where(role: role).order(created_at: :desc).first
  end

  def latest_gecko_ohlcv_snapshot(timeframe = 'minute', aggregate = 1)
    gecko_ohlcv_snapshots
      .where(timeframe: timeframe, aggregate: aggregate)
      .order(timestamp: :desc)
      .first
  end

  # Calculate data readiness tier: "none", "some", "lots"
  def data_readiness_tier
    @data_readiness_tier ||= TokenDataReadinessService.new(self).calculate_tier
  end

  # Get current position for this token
  def current_position(user)
    PurchaseLogService.new(self, user).current_position
  end
end
