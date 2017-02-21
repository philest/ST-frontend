require_relative 'bin/local'


require_relative 'lib/workers'


WelcomeTeacherWorker.perform_async(266)


# ["RMP", "the Nantucket Book Foundation", "Flamboyan Elementary", "RIF Elementary", "Mi Primer Libro", "the New Haven YMCA", "YWCA", "New Haven Library", "ST Elementary", "the Nantucket Book Foundation", "Malta House", "Martha's Table", "New Pines", "Freemium School", "Luciano Martinez", "Freemium School", "Freemium", "Freemium School", "Freemium School", "Freemium School", "Freemium School", "StoryTime", "StoryTime"] 



# School.where(signature: "RMP").update(city: 'Denver', state: 'CO')
# School.where(signature: "the Nantucket Book Foundation").update(city: 'Nantucket', state: 'MA')
# School.where(signature: "Flamboyan Elementary").update(city: 'Washington', state: 'DC')
# School.where(signature: "RIF Elementary").update(city: 'Washington', state: 'DC')
# School.where(signature: "the New Haven YMCA").update(city: 'New Haven', state: 'CT')
# School.where(signature: "YWCA").update(city: 'New Haven', state: 'CT')
# School.where(signature: "New Haven Library").update(city: 'New Haven', state: 'CT')
# School.where(signature: "Malta House").update(city: 'New Haven', state: 'CT')
# School.where(signature: "Martha's Table").update(city: 'Washington', state: 'DC')
# School.where(signature: "New Pines").update(city: 'West Palm Beach', state: 'FL')
# School.where(signature: "Luciano Martinez").update(city: 'Palm Springs', state: 'Florida')


def destroy
  if User.where(email: 'david.mcpeek@yale.edu').or(phone: 'david.mcpeek@yale.edu').first
    User.where(email: 'david.mcpeek@yale.edu').or(phone: 'david.mcpeek@yale.edu').first.destroy
  end


  if Teacher.where(email: 'david.mcpeek@yale.edu').or(phone: 'david.mcpeek@yale.edu').first
    Teacher.where(email: 'david.mcpeek@yale.edu').or(phone: 'david.mcpeek@yale.edu').first.destroy
  end

end