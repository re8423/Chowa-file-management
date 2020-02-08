class End < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :end, :int
  end
end
