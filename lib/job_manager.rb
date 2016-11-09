require 'securerandom'
require_relative './persistence_manager'

class JobManager
  attr_accessor :pm

  def initialize
    @pm = PersistenceManager.instance
  end

  # Currently doesn't actualy run jobs.
  # Spent too much time learning sprintf formatting
  # to bother with that part of the method.
  def run_jobs
    # TODO: ORM? DB Adapter?
    cursor = @pm.db.query(<<-SQL)
      select `workers`.*, `worker_managers`.* from worker_managers
      join workers on workers.worker_manager_id = worker_managers.id
    SQL

    # Some ugly as sin console table formatting follows
    # Cool. It works. Now get it out of here.
    #
    # Zip column headers with first row
    cursors_and_columns = cursor.columns.zip cursor.first
    widths = cursors_and_columns.map { |c|
      # spaceship operator: https://en.wikipedia.org/wiki/Three-way_comparison
      # Get the length(width) of the longer(wider) of the two columns
      c.max { |a, b| a.to_s.length <=> b.to_s.length }.length
    }

    format = ""
    widths.each_with_index { |w, i|
      # "%<arg index>$<width/padding>s"
      format = format + "%#{i+1}$#{w}s "
    }
    puts sprintf(format, *cursor.columns)
    cursor.each { |row|
      puts sprintf(format, *row.to_a)
    }
    cursor.close
    nil
  end

  def create_jobs(worker_definitions)
    @pm.db.transaction

    worker_manager_uuid = SecureRandom.uuid
    @pm.db.execute "insert into worker_managers(uuid) values(\"#{worker_manager_uuid}\")"

    # Save off the worker_manager_id for the foreign key in workers
    worker_manager_id = @pm.db.execute("select last_insert_rowid()")[0][0]

    worker_definitions.each do |worker_definition|
      worker_uuid = SecureRandom.uuid
      # TODO: Pull these queries out
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
