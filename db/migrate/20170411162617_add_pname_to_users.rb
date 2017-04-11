class AddPnameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :pname, :string
  end
end
