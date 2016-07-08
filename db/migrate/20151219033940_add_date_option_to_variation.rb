class AddDateOptionToVariation < ActiveRecord::Migration
  def change
  	  add_column :variations, :date_option, :datetime
  end
end
