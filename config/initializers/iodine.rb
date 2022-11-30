if defined?(Iodine)
  Iodine.threads                  = ENV.fetch('RAILS_MAX_THREADS', 5).to_i if Iodine.threads.zero?
  Iodine.workers                  = ENV.fetch('WEB_CONCURRENCY', 2).to_i if Iodine.workers.zero?
  Iodine::DEFAULT_SETTINGS[:port] = ENV['PORT'] if ENV['PORT']
end

# FIXME: watch out for idle CPU usage: https://github.com/boazsegev/iodine/issues/132