class User < Sequel::Model(:users)
	plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
	plugin :validation_helpers
	plugin :association_dependencies
	plugin :json_serializer
	
	many_to_one :classroom
	many_to_one :teacher
	many_to_one :school
	one_to_many :button_press_logs
	one_to_one :enrollment_queue
	one_to_one :state_table

	add_association_dependencies enrollment_queue: :destroy, button_press_logs: :destroy, state_table: :destroy

	def story_number
		self.state_table.story_number
	end

	def mod_story_no
		mod = story_number % $story_count
		return mod + 1
	end

	def mod_script
		mod_story_no == 1 ? mod_story_no + 1 : mod_story_no
	end

	# @@code_index = 0

	def generate_code 
		Array.new(2){[*'0'..'9'].sample}.join
		# @@code_index = (@@code_index + 1) % 100
		# sprintf '%02d', @@code_index
	end


	# ensure that user is added EnrollmentQueue upon creation
	def after_create
		super
		# associate an enrollment queue
		eq = EnrollmentQueue.create(user_id: self.id)
		self.enrollment_queue = eq
		eq.user = self
		# associate a state table
		st = StateTable.create(user_id: self.id)
		self.state_table = st
		st.user = self

		self.state_table.update(subscribed?: false) unless ENV['RACK_ENV'] == 'test'
		# new users on sms need to have a story_number of 0
		# if self.platform == 'sms'
		# self.state_table.update(story_number: 0)
		# end

		# do code shit
		if self.platform != 'fb'
			self.code = generate_code
		end
		
		puts "start code = #{self.code}"

		while !self.valid?
			self.code = (self.code.to_i + 1).to_s
			puts "new code = #{self.code}"
		end

		# set default curriculum version
		ENV["CURRICULUM_VERSION"] ||= '0'
		self.update(curriculum_version: ENV["CURRICULUM_VERSION"].to_i)
	rescue => e
		p e.message + " could not create and associate a state_table, enrollment_queue, or curriculum_version for this user"
	end

	def validate
    super
    validates_unique :code, :allow_nil=>true, :message => "#{code} is already taken (users)"
    validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (users)"
    validates_unique :fb_id, :allow_nil=>true, :message => "#{fb_id} is already taken (users)"
  end

end
