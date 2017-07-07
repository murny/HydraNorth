Resque.redis = $redis

Resque.inline = Rails.env.test?
Resque.redis.namespace = "#{Sufia.config.redis_namespace}:#{Rails.env}"
