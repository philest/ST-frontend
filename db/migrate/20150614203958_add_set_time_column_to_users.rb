class AddSetTimeColumnToUsers < ActiveRecord::Migration
  def change
  	 	  	add_column :users, :set_time, :boolean, default: false
  end
end
