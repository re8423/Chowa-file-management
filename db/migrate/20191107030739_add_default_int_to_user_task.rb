class AddDefaultIntToUserTask < ActiveRecord::Migration[5.2]
  def down
    change_column :tasks, :user_id, :integer, default: nil
  end
end
