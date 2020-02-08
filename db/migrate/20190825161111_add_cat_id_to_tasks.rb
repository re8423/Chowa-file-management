class AddCatIdToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :cat_id, :integer, default: 1
  end
end
