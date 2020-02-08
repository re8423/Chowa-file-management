class PageList < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :page, :integer
  end
end
