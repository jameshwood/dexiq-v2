# frozen_string_literal: true

# Stores structured GeckoTerminal token metadata for risk analysis
class GeckoTerminalSnapshot < ApplicationRecord
  belongs_to :token

  # Validations
  validates :token, presence: true
  validates :role, inclusion: { in: %w[base quote], allow_nil: true }

  # Scopes for querying
  scope :recent, -> { order(created_at: :desc) }
  scope :for_token, ->(token) { where(token: token) }
  scope :base_token, -> { where(role: 'base') }
  scope :quote_token, -> { where(role: 'quote') }

  # Check if token has high concentration risk
  def high_concentration_risk?
    return false unless holders_top_10.present?

    # Parse percentage string (e.g., "45.2%" -> 45.2)
    top_10_pct = holders_top_10.to_s.gsub('%', '').to_f
    top_10_pct > 50.0  # Red flag if top 10 hold > 50%
  end

  # Check for rug pull risk (Solana-specific)
  def rug_pull_risk?
    return false unless mint_authority.present? || freeze_authority.present?

    # Risk if authorities are NOT revoked
    mint_authority != 'Revoked' || freeze_authority != 'Revoked'
  end

  # Trust score (0-100)
  def trust_score
    gt_score || 0
  end
end
