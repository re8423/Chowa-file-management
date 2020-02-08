class ChangePageColumn < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :page, :string
  end
end
