class CreatePurchaseLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_logs do |t|
      t.references :token, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :transaction_type, null: false # 'buy' or 'sell'
      t.decimal :amount, precision: 20, scale: 8, null: false
      t.decimal :price_per_token, precision: 20, scale: 8, null: false
      t.string :transaction_hash
      t.text :notes

      t.timestamps
    end

    add_index :purchase_logs, [:token_id, :user_id]
  end
end
