class CreateAiChatInteractions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_chat_interactions do |t|
      t.references :token, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :session_id
      t.text :prompt, null: false
      t.text :reply

      t.timestamps
    end

    add_index :ai_chat_interactions, :session_id
    add_index :ai_chat_interactions, [:session_id, :created_at]
  end
end
