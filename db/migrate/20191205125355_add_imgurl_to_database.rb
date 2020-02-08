class AddImgurlToDatabase < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :img_url, :string
  end
end
