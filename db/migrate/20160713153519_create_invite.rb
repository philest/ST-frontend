class CreateInvite < ActiveRecord::Migration
  def change

  	 create_table :invites do |t|
  		t.string :email
  	 end

  end
end
