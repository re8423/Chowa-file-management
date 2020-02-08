class Fileidtable < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :fileid, :string
  end
end
