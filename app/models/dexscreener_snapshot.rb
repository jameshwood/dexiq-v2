# frozen_string_literal: true

# Stores DexScreener API response data for a token
class DexscreenerSnapshot < ApplicationRecord
  belongs_to :token

  validates :data, presence: true
  validates :fetched_at, presence: true

  before_validation :set_fetched_at, on: :create

  private

  def set_fetched_at
    self.fetched_at ||= Time.current
  end
end
