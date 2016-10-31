require 'securerandom'
require_relative './persistence_manager'

class JobManager
  def initialize
    @pm = PersistenceManager.instance
  end

  def create_jobs(worker_definitions)
    @pm.db.transaction

    worker_manager_uuid = SecureRandom.uuid
    @pm.db.execute "insert into worker_managers(uuid) values(\"#{worker_manager_uuid}\")"

    # Save off the worker_manager_id for the foreign key in workers
    worker_manager_id = @pm.db.execute("select last_insert_rowid()")[0][0]

    worker_definitions.each do |worker_definition|
      worker_uuid = SecureRandom.uuid
      # TODO: Pull these queries out into PersistanceManager
      @pm.db.execute <<-SQL
        insert into workers(uuid, state, worker_manager_id)
        values(\"#{worker_uuid}\", "pending", #{worker_manager_id})
      SQL
    end

    @pm.db.commit
  rescue SQLite3::Exception => e
    puts "Exception rescued: #{e}"
    puts e.backtrace
    @pm.db.rollback
  end
end
