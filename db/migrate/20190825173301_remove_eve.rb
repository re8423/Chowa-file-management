class RemoveEve < ActiveRecord::Migration[5.2]
  def change
    drop_table :eve
  end
end
