class AddTaskIdToEve < ActiveRecord::Migration[5.2]
  def change
    add_column :eve, :task_id, :integer, default: 1
  end
end
