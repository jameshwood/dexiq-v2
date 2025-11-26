class CreateDexscreenerSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :dexscreener_snapshots do |t|
      t.references :token, null: false, foreign_key: true
      t.jsonb :data, default: {}, null: false
      t.datetime :fetched_at

      t.timestamps
    end

    add_index :dexscreener_snapshots, :fetched_at
  end
end
