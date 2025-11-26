# frozen_string_literal: true

class CreateGeckoTerminalSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :gecko_terminal_snapshots do |t|
      t.references :token, null: false, foreign_key: true

      # Token identity
      t.string :address
      t.string :name
      t.string :symbol
      t.integer :decimals
      t.string :role  # 'base' or 'quote' - identifies which token in pair

      # External references
      t.string :coingecko_coin_id

      # Images
      t.string :image_large
      t.string :image_small
      t.string :image_thumb

      # Description and social
      t.text :description
      t.string :twitter_handle
      t.string :discord_url
      t.string :telegram_handle

      # Trust metrics
      t.decimal :gt_score, precision: 10, scale: 2

      # Holder distribution (used for concentration analysis)
      t.integer :holders_count
      t.string :holders_top_10      # "45.2%" string
      t.string :holders_11_20       # "12.5%"
      t.string :holders_21_40       # "8.3%"
      t.string :holders_rest        # "34.0%"

      # Solana-specific authority checks (rug pull indicators)
      t.string :mint_authority
      t.string :freeze_authority

      t.timestamps
    end

    # Index for fetching latest snapshot by role
    add_index :gecko_terminal_snapshots, [:token_id, :role, :created_at]
  end
end
