class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable
  pay_customer stripe_attributes: :stripe_attributes

  # DexIQ associations
  has_many :tokens, dependent: :destroy
  has_many :purchase_logs, dependent: :destroy
  has_many :ai_chat_interactions, dependent: :destroy


  def stripe_attributes(pay_customer)
    {
      address: {
        city: pay_customer.address_city,
        country: pay_customer.address_country,
      },
      metadata: {
        pay_customer_id: pay_customer.id,
        user_id: id, # or pay_customer.owner_id
      }
    }
  end

  def premium?
    self.charges.any?
  end

  def admin?
    admin
  end
end
