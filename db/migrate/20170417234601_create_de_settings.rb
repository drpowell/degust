class CreateDeSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :de_settings do |t|
      t.belongs_to :user, index: true
      t.belongs_to :user_file

      t.string :name
      t.string :secure_id, index: true
      t.string :settings

      t.timestamps
    end
  end
end
