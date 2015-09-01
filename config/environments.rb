
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path




configure :development, :production do
 db = URI.parse("postgres://yewixglwzrqdcj:HDaLjcIlP0x7Aznww0HFTKjoVh@ec2-107-20-152-139.compute-1.amazonaws.com:5432/dckt9lre6gdttc")

 
	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => db.user,
			:password => db.password,
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)

#adding development REDIS config
ENV["REDISTOGO_URL"] = "redis://redistogo:120075187f5e39ba84e429f311eb69a5@hammerjaw.redistogo.com:9787/"

end



configure :development do
 db = URI.parse('postgres://postgres:sharlach1@localhost/development')

#adding development REDIS config
ENV["REDISTOGO_URL"] = "redis://redistogo:120075187f5e39ba84e429f311eb69a5@hammerjaw.redistogo.com:9787/"
 
	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => db.user,
			:password => db.password,
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)
end





#set up the test database
configure :test do
 db = URI.parse('postgres://postgres:sharlach1@localhost/test')


#adding development REDIS config
ENV["REDISTOGO_URL"] = "redis://redistogo:120075187f5e39ba84e429f311eb69a5@hammerjaw.redistogo.com:9787/"
 
	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => db.user,
			:password => db.password,
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)
end

