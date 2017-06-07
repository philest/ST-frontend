module LoginAttempt
  def getEducatorData(params)
    username    = params[:username]
    password    = params[:password]
    role        = params[:role]

    # instead of a plaintext password, params may include
    # the hashed password_digest instead. 
    # this method can work with both.
    if not params[:digest].nil? and not params[:digest].empty?
      password = params[:password] = params[:digest]
    end

    # if missing any params, return 500
    if username.nil? or password.nil? or username.empty? or password.empty? 
      txt = "username: #{username.inspect}, Password: #{password.inspect}"

      missing = []
      missing << "username" if (username.nil? or username.empty?)
      missing << "password" if (password.nil? or password.empty?)

      notify_admins("A teacher failed to sign in to their account - missing #{missing}", txt)
      return 500
    end

    # educator = the teacher/admin in question.
    case role
    when 'admin'
      educator = Admin.where_username_is(username)
    when 'teacher'
      educator = Teacher.where_username_is(username)
    else
      educator = Admin.where_username_is(username)
      if educator.nil?
        educator = Teacher.where_username_is(username)
        role = 'teacher'
      else
        role = 'admin'
      end
    end


    if educator.nil?
      # never existed
      return @@INCORRECT_LOGIN
    end

    if !educator.grade.nil? and educator.grade > 3 # kindergarten
      # not the right grade!
      if educator.is_not_us
        notify_admins("educator id=#{educator.id} of grade #{educator.grade.inspect} was refused access to the dashboard because they don't teach prek")
      end
      return @@WRONG_GRADE_LEVEL
    end

    school = educator.school

    # if the PASSWORD DIGEST was provided, authenticate it. 
    if not params[:digest].nil? and not params[:digest].empty?
      if educator.password_digest != params[:digest]
        puts "incorrect password digest lol"
        return @@INCORRECT_LOGIN
      end
    # else if the PLAINTEXT PASSWORD was provided, authenticate it. 
    else
      if educator.authenticate(password) == false
        # wrong password!
        puts "incorrect password! lol"
        return @@INCORRECT_LOGIN
      end
    end

    if role == 'teacher'
      FlyerWorker.perform_async(educator.id, school.id) # if new_signup
    end

    # get school/educator metadata.
    educator_hash = educator.to_hash.select {|k, v| [:id, :name, :signature, :email, :phone, :code, :t_number, :signin_count].include? k}
    school_hash   = school.to_hash.select {|k, v| [:id, :name, :signature, :code].include? k }

    unless password.downcase == 'test' or password.downcase == 'read' or ENV['RACK_ENV'] == 'development'
      email_admins("#{role.capitalize} #{educator.signature} at #{school.signature} signed into their account")
    end

    # status 200

    # the educator is signing in, so increment the signin_count
    educator.update(signin_count: educator.signin_count + 1)

    return {
      educator: educator_hash,
      school: school_hash,
      secret: 'our little secret',
      role: role
    }.to_json

  end


  # attemps to login in the teacher or admin based on the provided params.
  def loginAttempt(params)

    data = JSON.parse(getEducatorData(params))

    if data == @@INCORRECT_LOGIN
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
      # return 
      puts "ass me!!!!!!!"
    end

    if data == @@FREEMIUM_PERMISSION_ERROR
      flash[:freemium_permission_error] = "We'll have your free StoryTime profile ready for you soon!"
      redirect '/'
    end

    if data == @@WRONG_GRADE_LEVEL
      flash[:wrong_grade_level_error] = "Right now, Storytime is only available for preschool. We'll email you when it's ready for your grade level!"
      redirect '/'
    end

    # have some secret to make sure this is coming from our server.
    if data["secret"] != 'our little secret'
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    # store in the session
    session[:educator] = data["educator"]
    session[:school]  = data["school"]
    session[:users]   = data["users"]
    session[:role]    = data["role"]

    if session[:educator].nil?
      # maybe have a banner saying, "must log in through teacher account"
      flash[:signin_error] = "Incorrect login information. Check with your administrator for the correct school code!"
      redirect to '/'
    end

    case session[:role]
    when 'admin'
      # automatically open the invite-teachers modal with the invite parameter.
      if params['invite']
        redirect to root + 'dashboard/dashboard_admin?invite=' + params['invite']
      else
        redirect to root + 'dashboard/dashboard_admin'
      end

    when 'teacher'
      # automatically open the invite-flyers modal with the flyers parameter.
      if params['flyers']
        redirect to root + 'dashboard/dashboard_teacher?flyers=' + params['flyers']
      else
        redirect to root + 'dashboard/dashboard_teacher'
      end
    end
  end

end