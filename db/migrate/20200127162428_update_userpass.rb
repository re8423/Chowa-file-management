class UpdateUserpass < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :pass, :string, default: "Add password"
  end
end
