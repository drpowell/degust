class AddUploadToken < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :upload_token, :string
  end
end
