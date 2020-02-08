class DeleteFileidCol < ActiveRecord::Migration[5.2]
  def change
    remove_column :tasks, :fileid
  end
end
