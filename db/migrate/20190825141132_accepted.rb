class Accepted < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :accepted, :boolean
  end
end
