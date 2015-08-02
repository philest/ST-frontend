class AddLocaleToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :locale, :string, defaul: 'en'
  end
end
