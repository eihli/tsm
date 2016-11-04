require './lib/persistence_manager.rb'

class NotificationService
  include Singleton

  def initialize
    @pm = PersistenceManager.instance
  end

  def notify(state_key, payload = {})
    @pm.redis.mapped_hmset(state_key, payload)
  end
end
