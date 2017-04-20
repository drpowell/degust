class CreateVisiteds < ActiveRecord::Migration[5.0]
  def change
    create_table :visiteds do |t|
      t.belongs_to :user, index: true
      t.belongs_to :de_setting, index:true

      t.datetime :last



      t.timestamps
    end
  end
end
