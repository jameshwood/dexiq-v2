# frozen_string_literal: true

# Stores GeckoTerminal API response data for a token
class GeckoTerminalSnapshot < ApplicationRecord
  belongs_to :token

  validates :data, presence: true
  validates :fetched_at, presence: true

  before_validation :set_fetched_at, on: :create

  private

  def set_fetched_at
    self.fetched_at ||= Time.current
  end
end
