class Start < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :start, :int
  end
end
