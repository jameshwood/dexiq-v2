# frozen_string_literal: true

class CreateGeckoOhlcvSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :gecko_ohlcv_snapshots do |t|
      t.references :token, null: false, foreign_key: true

      # Timeframe identification
      t.string :timeframe    # 'minute', 'hour', 'day'
      t.integer :aggregate   # 1, 15, 4, 1 (combined with timeframe)
      t.bigint :timestamp    # Unix timestamp (unique per token/timeframe/aggregate)

      # OHLCV data (Open, High, Low, Close, Volume)
      t.decimal :open, precision: 30, scale: 18
      t.decimal :high, precision: 30, scale: 18
      t.decimal :low, precision: 30, scale: 18
      t.decimal :close, precision: 30, scale: 18
      t.decimal :volume, precision: 20, scale: 8

      t.timestamps
    end

    # Critical composite index for time-series queries
    add_index :gecko_ohlcv_snapshots, [:token_id, :timeframe, :aggregate, :timestamp],
              name: 'index_ohlcv_on_token_timeframe_timestamp',
              unique: true
  end
end
