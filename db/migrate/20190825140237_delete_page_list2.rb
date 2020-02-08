class DeletePageList2 < ActiveRecord::Migration[5.2]
  def change
    remove_column :tasks, :pages2
  end
end
