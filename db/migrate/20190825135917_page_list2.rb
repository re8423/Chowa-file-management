class PageList2 < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :pages2, :string
  end
end
