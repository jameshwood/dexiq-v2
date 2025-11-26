# frozen_string_literal: true

class CreateDexscreenerSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :dexscreener_snapshots do |t|
      t.references :token, null: false, foreign_key: true
      t.string :chain_id
      t.string :dex_id
      t.string :url

      # Price data
      t.decimal :price_usd, precision: 30, scale: 18
      t.decimal :price_native, precision: 30, scale: 18

      # Transaction counts (stored as JSONB: { "buys": 45, "sells": 32 })
      t.jsonb :txns_5m
      t.jsonb :txns_1h
      t.jsonb :txns_6h
      t.jsonb :txns_24h

      # Volume by timeframe
      t.decimal :volume_5m, precision: 20, scale: 2
      t.decimal :volume_1h, precision: 20, scale: 2
      t.decimal :volume_6h, precision: 20, scale: 2
      t.decimal :volume_24h, precision: 20, scale: 2

      # Price changes (percentage)
      t.decimal :price_change_5m, precision: 10, scale: 4
      t.decimal :price_change_1h, precision: 10, scale: 4
      t.decimal :price_change_6h, precision: 10, scale: 4
      t.decimal :price_change_24h, precision: 10, scale: 4

      # Liquidity
      t.decimal :liquidity_usd, precision: 20, scale: 2
      t.decimal :liquidity_base, precision: 30, scale: 18
      t.decimal :liquidity_quote, precision: 30, scale: 18

      # Market metrics
      t.bigint :fdv
      t.bigint :market_cap

      # Timestamps
      t.datetime :pair_created_at
      t.datetime :captured_at

      t.timestamps
    end

    # Critical index for time-series queries
    add_index :dexscreener_snapshots, [:token_id, :created_at]
  end
end
