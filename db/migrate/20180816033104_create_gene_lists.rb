class CreateGeneLists < ActiveRecord::Migration[5.0]
  def change
    create_table :gene_lists do |t|
      t.belongs_to :user, index: true
      t.belongs_to :de_setting, index:true

      t.string :title
      t.string :description
      t.string :id_type

      t.string :columns
      t.string :rows

      t.timestamps
    end
  end
end
