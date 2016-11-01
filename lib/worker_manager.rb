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
      # Enqueue worker
      # Wait...
      puts worker.join " "
    end
  end
end
