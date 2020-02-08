class ChangePagestringToint < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :page, :int
  end
end
