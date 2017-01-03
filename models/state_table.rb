class StateTable < Sequel::Model(:state_tables)
	plugin :timestamps, :update=>:updated_at, :update_on_create=>true
	plugin :association_dependencies
	
	one_to_one :user
	
	add_association_dependencies user: :nullify

end