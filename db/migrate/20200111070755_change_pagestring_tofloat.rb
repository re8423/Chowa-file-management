class ChangePagestringTofloat < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :page, :float
  end
end
