class ChangeTimeTypeFromTimeToString < ActiveRecord::Migration
  	def self.up
    	change_column :users, :time, :string
  	end

  	def self.down
  		change_column :users, :time, :time
  	end
end
