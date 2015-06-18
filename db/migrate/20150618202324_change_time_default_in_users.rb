class ChangeTimeDefaultInUsers < ActiveRecord::Migration
  def change
  	change_column_default :users, :time, "5:30pm"
  end
end
