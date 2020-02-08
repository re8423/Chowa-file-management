class AddImgidToDatabase < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :img_id, :string
  end
end
