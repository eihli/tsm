require 'sqlite3'
require 'redis'
require 'singleton'

class PersistenceManager
  include Singleton
  # Hardcoding a prefix manager for easy Redis #keys searching
  REDIS_PREFIX = 'com.owoga.tsm.'

  attr_reader :redis, :db

  def initialize
    # TODO: Pass in db connections
    @redis = Redis.new
    @db = SQLite3::Database.new 'test.db'
  end

  def set(key, value)
    @redis.set(REDIS_PREFIX + key, value)
  end

  def get(key)
    @redis.get(REDIS_PREFIX + key)
  end
end

