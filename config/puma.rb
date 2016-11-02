#workers Integer(ENV['WEB_CONCURRENCY'] || 1)       # one process for now
threads_count = Integer(ENV['PUMA_MAX_THREADS'] || 16)  # 16 is puma default I think
threads threads_count, threads_count # min = threads_count, max = threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 5000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do


end
