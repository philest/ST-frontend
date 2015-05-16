class AddChildAgeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :child_age, :string
  	add_column :users, :child_name, :integer

  end
end
