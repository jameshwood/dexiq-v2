# frozen_string_literal: true

# Stores AI chat conversations for token analysis
class AiChatInteraction < ApplicationRecord
  belongs_to :token
  belongs_to :user

  validates :prompt, presence: true
  validates :session_id, presence: true

  scope :for_session, ->(session_id) { where(session_id: session_id).order(created_at: :asc) }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }

  before_validation :generate_session_id, on: :create, unless: :session_id?

  private

  def generate_session_id
    self.session_id = SecureRandom.uuid
  end
end
