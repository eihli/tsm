require_relative './persistence_manager'

class WorkerManager
  def initialize(id)
    @pm = PersistenceManager.instance
    @id = id
  end

  def perform
    workers = @pm.db.query(<<-SQL)
      select * from workers where workers.worker_manager_id = #{@id}
    SQL
    workers.each do |worker|
      puts worker.join " "

      # Check cache using workers 'state_key' to get its state
      state = @pm.get(worker[1])

      case state
      when "pending"
        # enqueue worker
        # start polling procedure
      when "started"
        # if worker is already enqueued/running
        #   start polling procedure
        # else if worker is not enqueued/running
        #   enqueue worker
        #   start polling procedure
      when "failed/success"
        # handle completed states
      else
        # handle unknown state
      end
      puts state
    end
  end

  def poll(state_key)
    # get state
    # if state success
    #   handle success
    # if state failed
    #   handle failed
    # else
    #   handle timeouts/retries/etc...
  end
end
