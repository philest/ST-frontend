class AddActiveColumnToExperiments < ActiveRecord::Migration
  def change
  	  add_column :experiments, :active, :boolean, default: true
  end
end
