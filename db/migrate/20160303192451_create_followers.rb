class CreateFollowers < ActiveRecord::Migration
  def change
		def up
	    create_table :followers do |t|
	      t.string :name
	      t.string :email

	      t.timestamps
	  	end
		end

	  def down
	    drop_table :followers
	  end

  end
end
