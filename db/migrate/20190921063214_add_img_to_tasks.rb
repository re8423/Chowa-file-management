class AddImgToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :img, :string
  end
end
