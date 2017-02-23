class NilClass
  def email?(string)
    false
  end

  def phone?(string)
    false
  end
end


class String
  def email?(string)
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    email_regex.match(string) ? true : false
  end

  def phone?
    
  end

end