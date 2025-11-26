class CreateGeckoOhlcvSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :gecko_ohlcv_snapshots do |t|
      t.references :token, null: false, foreign_key: true
      t.jsonb :data, default: {}, null: false
      t.datetime :fetched_at
      t.string :timeframe # e.g., '1h', '1d', '1w'

      t.timestamps
    end

    add_index :gecko_ohlcv_snapshots, :fetched_at
    add_index :gecko_ohlcv_snapshots, [:token_id, :timeframe]
  end
end
