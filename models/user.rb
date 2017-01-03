require 'bcrypt'

class User < Sequel::Model(:users)
	include BCrypt
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

	# don't put this in user model?
	def authenticate(input_password=nil)
		# input_password = "password"
		# stored = Password.create(original_password)
		# password_hash = Password.new(stored)
		# return true if 
    begin 
  		return false if input_password.nil? || input_password.empty?
      # return false if self.password_digest.nil?
  		password_hash 	= Password.new(self.password_digest)
  		return password_hash == input_password
    rescue => e
      p e
      return false
    end
	end

	def set_password(new_password)
		return false if new_password.empty? or new_password.nil?
    password = Password.create(new_password)
    self.update(password_digest: password)
    return password
  end

  def get_password
  	Password.new(self.password_digest)
  end
  
	def story_number
		self.state_table.story_number
	end

	def generate_code 
		Array.new(2){[*'0'..'9'].sample}.join
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


    if self.platform != 'app'
		  self.state_table.update(subscribed?: false) unless ENV['RACK_ENV'] == 'test'
      # self.state_table.update(subscribed?: true)
    end

		if not ['fb', 'app'].include? self.platform
			self.code = generate_code
		end
		# puts "start code = #{self.code}"
		while !self.valid?
			self.code = (self.code.to_i + 1).to_s
			# puts "new code = #{self.code}"
		end
		# set default curriculum version
		ENV["CURRICULUM_VERSION"] ||= '0'
		self.update(curriculum_version: ENV["CURRICULUM_VERSION"].to_i)

		# we would want to do 
		# self.save_changes
		# self.state_table.save_changes
		# but this is already done for us with self.update and self.state_table.update

	rescue => e
		p e.message + " could not create and associate a state_table, enrollment_queue, or curriculum_version for this user"
	end

	def match_school(body_text)
      School.each do |school|
        code = school.code
        if code.nil?
          next
        end
        code = code.delete(' ').delete('-').downcase
        # body_text = params[:Body].delete(' ')
        #                          .delete('-')
        #                          .downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            # puts "WE HAVE A MATCH! User #{phone} goes to #{school.signature}"
            I18n.locale = 'en'
            # puts "school info: #{school.signature}, #{school.inspect}"
            school.add_user(self)
            return school
          elsif body_text == sp
            # puts "WE HAVE A MATCH! User #{phone} goes to #{school.signature}"
            I18n.locale = 'es'
            self.update(locale: 'es')
            # puts "school info: #{school.signature}, #{school.inspect}"
            school.add_user(self)
            return school
          else 
            puts "#{code} did not match with #{school.name} regex!"
          end
        else
          puts "code #{body_text} doesn't match with #{school.signature}'s code #{school.code}"
        end
      end
  end


  def match_teacher(body_text)
      # DO THE SAME FOR TEACHERS HERE?
      # not only connect them with a teacher, but connect them to that teacher's school
      Teacher.each do |teacher|
        code = teacher.code
        if code.nil?
          next
        end
        code = code.delete(' ').delete('-').downcase
        # body_text = params[:Body].delete(' ')
        #                          .delete('-')
        #                          .downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            # puts "WE HAVE A MATCH! User #{phone} is in #{teacher.signature}'s class"
            # puts "#{teacher.signature}, #{teacher.inspect}"
            I18n.locale = 'en'
            teacher.add_user(self)
            if !teacher.school.nil? # if this teacher belongs to a school
              teacher.school.add_user(self)
            end
            return teacher

          elsif body_text == sp
            # puts "WE HAVE A MATCH! User #{phone} is in #{teacher.signature}'s class"
            # puts "#{teacher.signature}, #{teacher.inspect}"
            I18n.locale = 'es'
            self.update(locale: 'es')
            # puts "teacher info: #{teacher.signature}, #{teacher.inspect}"
            teacher.add_user(self)
            if !teacher.school.nil? # if this teacher belongs to a school
              teacher.school.add_user(self)
            end
            return teacher
          else 
            puts "#{code} did not match with #{teacher.name} regex!"
          end
        else
          puts "code #{body_text} doesn't match with #{teacher.signature}'s code #{teacher.code}"
        end # if code.include? body_text
      end # Teacher.each do |teacher|

  end


	def validate
    super
    validates_unique :code, :allow_nil=>true, :message => "#{code} is already taken (users)"
    validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (users)"
    validates_unique :fb_id, :allow_nil=>true, :message => "#{fb_id} is already taken (users)"
  end

end














