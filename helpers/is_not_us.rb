require 'bcrypt'

class NilClass
  def is_not_us
    return true
  end
end


module IsNotUs
  def is_not_us?(thingy)
    if ENV['RACK_ENV'] == 'development' or ENV['RACK_ENV'] == 'test'
      puts "it's just us! (development)"
      return false
    end

    if thingy.nil? or thingy.empty?
      return true
    end

    fcm_blacklist = [
      "f440qVxzJcQ:APA91bEYM3bFujWpyfqz_sATNOEPlWZzS37UF2gi5UWT2eYx7mAcQkh8iAiGnyChkDNrZTniwDlO2JysXpGEQBJFwTdS84FOvIwLL8oipuv8Wn-ikfZ7NWvQw9aIQaejse1A1WtcSwLs",
      "dqtr9mkCXfE:APA91bHcBlBBcXK0IFxH5E2PMzjU6Wf-iIKRVQuX4_2oSAFYptl-XNyf8udCx7F00npaXgdpAgM2Z-8LVniLUVYe7UEJxIfDTqR3Fz0PgHT2RvccA09JlZYfU8o3xaindTRIZTnZlGAd",
      "dV30D2pz3LI:APA91bEnuZN0QYNY-UcGC1Z2sruA0z60KNkqav37et5xChE5UH4aZmhoHw6ze1ZKCtrB9nU8M6XGqmtqEUV2Z3wkjmdRo3VgDJsqLDTO6qlMg0u8Lwqsjs-C2l56X4iJLE-SycEwGsdj"
    ]
    phone_blacklist = ['8186897323', '5612125831', '3013328953']
    email_blacklist = [
      'josedmcpeek@gmail.com',
      'aawahl@gmail.com',
      'phil.esterman@yale.edu',
      'phil@joinstorytime.com',
      'david@joinstorytime.com',
      'aubrey.wahl@yale.edu'
    ]
    first_name_blacklist = [
      'test'
    ]

    password_blacklist = Password.create('stpass')

    if first_name_blacklist.include? thingy.downcase
      puts "it's just us! (first name)"
      return false
    end

    if fcm_blacklist.include? thingy
      puts "it's just us! (fcm)"
      return false 
    end
    if phone_blacklist.include? thingy
      puts "it's just us! (phone)"
      return false 
    end
    if email_blacklist.include? thingy
      puts "it's just us! (phone)"
      return false 
    end
    if Password.new(password_blacklist) == thingy
      puts "it's just us! (password)"
      return false 
    end

    return true
  end
end

module PersonIsNotUs
  include IsNotUs

  def is_not_us

    [:phone, :email, :first_name, :last_name].each do |att|
      attribute = self.to_hash[att]
      if !is_not_us?(attribute)
        return false
      end
    end 

    if self.class.name == "User"
      if !is_not_us?(self.fcm_token)
        return false
      end 
    end

    return true

  end

end

