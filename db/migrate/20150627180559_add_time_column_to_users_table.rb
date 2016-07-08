class AddTimeColumnToUsersTable < ActiveRecord::Migration
  def change
  	add_column :users, :time, :time
  end
end
