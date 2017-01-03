class UnionWorker
  include Sidekiq::Worker

  def perform
    puts "I'M GOING ON STRIKE!!!!!!!!!!!!"
  end

end