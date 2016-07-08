class CreateExperimentsAndVariations < ActiveRecord::Migration
  def change

  	create_table :experiments do |t|
  		t.string :variable
  		t.integer :users_to_assign
  		t.datetime :end_date
  		t.timestamps null: false
  	end

  	create_table :variations do |t|
		t.belongs_to :experiment, index: true
		t.belongs_to :user, index: true
		t.string :option
		t.timestamps null: false
	end

  end
end
