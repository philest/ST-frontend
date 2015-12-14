class AddBelongsToVariationToUsers < ActiveRecord::Migration
  def change
  	add_reference :variation, :user, index: true
  end
end
