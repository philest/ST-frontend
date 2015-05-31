
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path



configure :development, :production, :test do
 db = URI.parse(ENV['DATABASE_URL'] || 'postgres://postgres:sharlach1@localhost/development')


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
