class School < Sequel::Model(:schools)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	plugin :association_dependencies
  plugin :json_serializer

	one_to_many :teachers
	one_to_many :users
	many_to_one :district
	one_to_many :school_sessions
  one_to_many :admins

	add_association_dependencies teachers: :nullify, users: :nullify, admins: :nullify

  def signup_teacher(teacher)
    if self.teachers.select {|t| t.id == teacher.id }.size == 0
      teacher_i = self.teacher_index
      while true
        teacher_i += 1
        code = self.code.split('|').map{|c| "#{c}#{teacher_i}" }.join('|')
        # puts "teacher_i = #{teacher_i}"  
        if Teacher.where(code: code).first.nil? 
          teacher.update(code: code)
          teacher.update(t_number: teacher_i)
          break
        end
      end

      self.update(teacher_index: teacher_i)

      self.add_teacher(teacher)

      # puts "#{teacher.inspect}"
    else
      puts "Teacher #{teacher.signature} is already associated with #{self.signature}"
    end
  end
end