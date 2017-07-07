require 'redis'

# We should not even have a redis.yml file...
# Just use REDIS_URL or fallback to the defaults which redis does automagically
# Have to undo this stupid if we are using a ENV VAR now...

# initialize redis connection
if ENV['REDIS_URL']
  $redis = Redis.new
else
  # use config/redis.yml to load settings
  redis_config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env]
  $redis = Redis.new(redis_config)
end
