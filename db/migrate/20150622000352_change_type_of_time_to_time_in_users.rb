class ChangeTypeOfTimeToTimeInUsers < ActiveRecord::Migration
 def up
    remove_column :users, :time, :string
    add_column :users, :time, :time 	 #can't figure out how to set default atm.
  end

  def down
    remove_column :users, :time, :string
    add_column :users, :time, :time 
  end

end
