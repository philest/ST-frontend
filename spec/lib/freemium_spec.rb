require 'spec_helper'
# require 'app'
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
    @other_school = School.create(signature: "Legit School", name: "Legit Academy", city: "Oz", state: "Oo")
    @freemium_school = School.create(name: "Legit School", signature: "Freemium School", city: "Oz", state: "Oo", code: 'unofficial|unofficial-es')
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
        teacher_email = "test2@test.test"
        @t = Teacher.create(email: teacher_email)
        @other_school.signup_teacher(@t)

        @same_guy = User.create(first_name: "David", last_name: "McPeek", email: "email2@example.com")
        @t.signup_user(@same_guy)

        # puts "teacher users count = #{@t.users.count}"

        session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email2@example.com",
          password_digest: "thisisapassworddigest"
        }

        params = {
          role: "parent",
          teacher_email: teacher_email
        }

        # puts "user count before = #{@t.users.size}"
        post '/freemium-signup', params, 'rack.session' => session

        # @count = User.count
        # puts "user count after = #{@t.users.size}"
        # @teacher.reload
      end

      it "doesn't create a new user" do
        # puts "fun"
        # puts count
        puts "users = #{User.all}"
        expect(User.count).to eq 1
      end

      it "probably shouldn't reassign that user's teacher either" do


      end

    end

    context 'no teacher/user with same contact info exists' do
      before(:each) do

        teacher_email = "test3@test.test"

        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email2@example.com",
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "parent",
          teacher_email: teacher_email
        }
      
      end

      it "adds a new user to db" do
        # puts "user count before = #{@t.users.size}"
        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{User.count}.by 1

      end


      it "adds a new teacher to db" do
        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{Teacher.count}.by 1
      end



      it "associate new user with freemium school and freemium teacher" do
        post '/freemium-signup', @params, 'rack.session' => @session

        expect(User.where(email:@session[:username]).first.school.id).to eq @freemium_default.id

        expect(User.where(email:@session[:username]).first.teacher.id).to eq Teacher.where(email:@params[:teacher_email]).first.id

      end

    end


  end


  context 'teachers' do

    context 'freemium school with same info exists' do
      before(:each) do
        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email2@example.com",
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "teacher",
          signature: "Mr. McPeek",
          school_name: "Legit School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      # we don't want to create a new school with same info....
      # 
      # create teacher
      # create association with that existing school (temporary solution)
      # do nothing with the freemium school

      it "should create an assocation between teacher and existing school" do
        
        post '/freemium-signup', @params, 'rack.session' => @session

        teacher = Teacher.where(email: @session[:username]).first
        expect(teacher.school.id).to eq @freemium_school.id


      end

      it "should not create any new schools" do

        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{School.count}
      end

    end

    context 'teacher with same info exists' do
      before(:each) do
        email = "test4@testing.test"
        @teacher = Teacher.create(email: email)
        @other_school.signup_teacher(@teacher)
        puts "@teacher = #{@teacher.inspect}"

        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: email,
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "teacher",
          signature: "Mr. McPeek",
          school_name: "Legit School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      it "does not create a new teacher" do
        puts "teacher count = #{Teacher.count}"
        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{Teacher.count}

        puts "teacher count after = #{Teacher.count}"
      end

      it "doesn't assign the existing teacher to a new school! it doesn't do JACK SHIT" do
        existing_t = Teacher.where(email: @session[:username]).first
        puts "existing = #{existing_t.inspect}"

        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{existing_t.school.id}

      end
    end

    context 'no teacher/school with same info exists' do
      before(:each) do
        email = "imeanmaybe@testing.test"
        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: email,
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "teacher",
          signature: "Mr. McPeek",
          school_name: "Crazy New School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      it "creates a new school with freemium properties" do
        expect {
            post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{School.count}.by 1
        expect(School.where(name: "Crazy New School", signature: "Freemium School", city: "Oz", state: "Oo").first).to_not be_nil
      end

      it "creates a new teacher that belongs to said freemium school" do
        expect {
            post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{Teacher.count}.by 1

        teacher = Teacher.where(email: @session[:username]).first
        expect(teacher).to_not be_nil
      end

    end
  end


  context 'admins' do
    context 'school with same info exists' do
      before(:each) do
        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: "email2@example.com",
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "admin",
          signature: "Mr. McPeek",
          school_name: "Legit School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      # we don't want to create a new school with same info....
      # 
      # create teacher
      # create association with that existing school (temporary solution)
      # do nothing with the freemium school

      it "should create an assocation between admin and existing school" do
        
        post '/freemium-signup', @params, 'rack.session' => @session

        admin = Admin.where(email: @session[:username]).first
        expect(admin.school.id).to eq @freemium_school.id


      end

      it "should not create any new schools" do

        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{School.count}
      end


    end

    context 'admin with same info exists' do

      before(:each) do
        email = "test4@testing.test"
        @admin = Admin.create(email: email)
        @other_school.add_admin(@admin)
        puts "@admin = #{@admin.inspect}"

        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: email,
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "admin",
          signature: "Mr. McPeek",
          school_name: "Legit School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      it "does not create a new admin" do
        puts "admin count = #{Admin.count}"
        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{Admin.count}

        puts "admin count after = #{Admin.count}"
      end

      it "doesn't assign the existing admin to a new school! it doesn't do JACK SHIT" do
        existing_t = Admin.where(email: @session[:username]).first
        puts "existing = #{existing_t.inspect}"

        expect {
          post '/freemium-signup', @params, 'rack.session' => @session
        }.not_to change{existing_t.school.id}

      end

    end

    context 'no admin/school with same info exists' do
      before(:each) do
        email = "imeanmaybe@testing.test"
        # we're talking about legit school
        @session = {
          first_name: "David",
          last_name: "McPeek",
          email: email,
          password_digest: "thisisapassworddigest"
        }

        @params = {
          role: "admin",
          signature: "Mr. McPeek",
          school_name: "Crazy New School",
          school_city: "Oz",
          school_state: "Oo"
        }

      end

      it "creates a new school with freemium properties" do
        expect {
            post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{School.count}.by 1
        expect(School.where(name: "Crazy New School", signature: "Freemium School", city: "Oz", state: "Oo").first).to_not be_nil
      end

      it "creates a new admin that belongs to said freemium school" do
        expect {
            post '/freemium-signup', @params, 'rack.session' => @session
        }.to change{Admin.count}.by 1

        admin = Admin.where(email: @session[:username]).first
        expect(admin).to_not be_nil


      end

    end

  end


end