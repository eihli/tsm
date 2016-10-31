require_relative './persistence_manager'

class Worker
  attr_reader :state_key, :args, :pm

  def initialize(state_key, *args)
    @pm = PersistenceManager.instance
    @state_key = state_key
    @args = *args
  end

  def perform(subject)
    @pm.set(@state_key, 'started')

    did_something = do_something
    if did_something
      @pm.set(@state_key, 'success')
    else
      @pm.set(@state_key, 'failed')
    end

    # Either mutate subject passed in or return
    # something that a WorkerManager can deal with
    subject
  end

  def do_something
    Random.rand > 0.9
  end
end

