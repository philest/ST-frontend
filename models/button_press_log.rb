class ButtonPressLog < Sequel::Model(:button_press_logs)
	plugin :timestamps, :create=>:created_at 
	plugin :association_dependencies

	many_to_one :user

end
