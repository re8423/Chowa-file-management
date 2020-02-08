class ChangeColumnDefault < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :completed, :boolean, :default => false
    change_column :tasks, :accepted, :boolean, :default => false
    change_column :tasks, :star, :boolean, :default => false
  end
end
