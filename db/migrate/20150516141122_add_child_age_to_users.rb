class AddChildAgeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :child_age, :integer
  	add_column :users, :child_name, :string

  end
end
