class CreateUserFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :user_files do |t|
      t.string :name
      t.text :description
      t.string :location
      t.string :content_type
      t.string :md5
      t.integer :size

      t.timestamps
    end
  end
end
