require 'bcrypt'

module AuthenticateModel
  include BCrypt
  # don't put this in user model?
  def authenticate(input_password=nil)
    # input_password = "password"
    # stored = Password.create(original_password)
    # password_hash = Password.new(stored)
    # return true if 
    begin 
      return false if input_password.nil? || input_password.empty?
      # return false if self.password_digest.nil?
      password_hash   = Password.new(self.password_digest)
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

end