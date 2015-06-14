class AddSetBirthdateColumnToUsers < ActiveRecord::Migration
  def change
  	 	  	add_column :users, :set_birthdate, :boolean, default: false
  end
end
