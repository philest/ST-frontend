require 'spec_helper'
require 'app'
require 'timecop'
require 'active_support/time'
require 'workers'
require_relative '../../app/app'

describe 'freemium signup' do
  include Rack::Test::Methods

  ENV['RACK_ENV'] = 'test'

  def app
    App
  end

  before(:each) do
    @freemium_default = School.create(signature: "Freemium", name: "Unnamed", code: 'freemium|freemium-es')
    puts "default id = " + @freemium_default.id.to_s
    @other_school = School.create(signature: "Legit School", name: "Legit Academy")
    puts "other school id = " + @other_school.id.to_s
  end

  context 'parents' do
    context 'teacher with same email exists' do
      before(:each) do
        teacher_email = "test@test.test"
        @teacher = Teacher.create(email: teacher_email)
        @other_school.signup_teacher(@teacher)

        @some_guy = User.create(first_name: "Some", last_name: "Guy")
        @teacher.signup_user(@some_guy)

        # puts "teacher users count = #{@teacher.users.count}"

        session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email@example.com",
          password_digest: "thisisapassworddigest"
        }

        params = {
          role: "parent",
          teacher_email: teacher_email
        }

        # puts "user count before = #{@teacher.users.size}"
        post '/freemium-signup', params, 'rack.session' => session

        # puts "user count after = #{@teacher.users.size}"
        # @teacher.reload
      end

      # use case
      # parent at RMP discovers Storytime, didn't know their teacher was already on
      # they sign up using their teacher's email, which is already in the system.

      # when freemium is actually built, we'll notify them that their teacher is
      # already enrolled in storytime and that they can join the class
      # 
      # 
      # until then, we're going for low-impact
      # we'll create the user with their contact info
      # then connect them to the teacher just through the teacher id
      # that way, we've recorded the teacher they want, 
      #   but they're not added to that existing teacher's class.
      #   
      # also - that teacher's school does not change. the teacher is not assigned to the freemium school.
      # 


      it "creates a user with the proper fields" do
        user = User.where(email: "email@example.com", password_digest: "thisisapassworddigest").first
        expect(user).to_not be_nil
      end

      it "creates an association with the existing teacher and school (short-term solution)" do
        user = User.where(email: "email@example.com", password_digest: "thisisapassworddigest").first
        expect(user.school_id).to eq @other_school.id
        expect(user.teacher_id).to eq @teacher.id
        expect(@teacher.users).to include user
        expect(@teacher.users.count).to eq 2
      end

      it "does not reassign the teacher to the freemium school. teacher's school remains the same." do
        @teacher.reload
        expect(@teacher.school.id).to eq @other_school.id
      end

    end

    context 'users with same contact info exists' do
      before(:each) do
        teacher_email = "test@test.test"
        @teacher = Teacher.create(email: teacher_email)
        @other_school.signup_teacher(@teacher)

        @same_guy = User.create(first_name: "David", last_name: "McPeek", email: "email@example.com")
        @teacher.signup_user(@same_guy)

        # puts "teacher users count = #{@teacher.users.count}"

        session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email@example.com",
          password_digest: "thisisapassworddigest"
        }

        params = {
          role: "parent",
          teacher_email: teacher_email
        }

        # puts "user count before = #{@teacher.users.size}"
        post '/freemium-signup', params, 'rack.session' => session


        # @count = User.count
        # puts "user count after = #{@teacher.users.size}"
        # @teacher.reload
      end

      it "doesn't create a new user" do
        # User.each do |u|
        #   puts u

        # end

        # expect(User.count).to eq 1
      end

    end

    context 'no teacher/user with same contact info exists' do

    end
  end


  context 'teachers' do
    context 'school with same info exists' do

    end

    context 'teacher with same info exists' do

    end

    context 'no teacher/school with same info exists' do

    end
  end


  context 'admins' do
    context 'school with same info exists' do

    end

    context 'admin with same info exists' do

    end

    context 'no admin/school with same info exists' do

    end

  end


end