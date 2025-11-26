class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :tokens do |t|
      t.string :chain_id, null: false
      t.string :pool_address, null: false
      t.string :symbol
      t.string :quote_symbol
      t.string :token_url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure idempotent token creation by chain_id + pool_address
    add_index :tokens, [:chain_id, :pool_address], unique: true
  end
end
