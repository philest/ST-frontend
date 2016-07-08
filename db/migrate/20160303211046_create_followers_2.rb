class CreateFollowers2 < ActiveRecord::Migration
  def change
  	  	create_table :followers do |t|
  		t.string :name
  		t.string :email
  		end
  end
end
