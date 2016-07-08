class AddMmsColumnToUsersTable < ActiveRecord::Migration

  def change
 	  	add_column :users, :mms, :boolean, default: true
  end
end
