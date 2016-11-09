require_relative './lib/notification_service'

class Worker
  attr_reader :state_key, :args, :pm

  def initialize(state_key, *args)
    @notification_service = NotificationService.instance
    @state_key = state_key
    @args = *args
  end

  def perform(subject)
    # TODO: Handle startup procedure
    # What if we were already started?
    notify({
      status: 'started',
      started_key: 'started_value'
    })

    # Hit some external API
    did_something = do_something

    if did_something
      # TODO: Handle verification
      notify({
        status: 'success',
        success_key: 'success_value'
      })
    else
      notify({
        status: 'failure',
        failure_key: 'failure_value'
      })
    end

    # Either mutate subject passed in or return
    # something that a WorkerManager can deal with
    subject
  end

  def do_something
    Random.rand > 0.9
  end

  def notify(payload)
    @notification_service.notify(@state_key, payload)
  end
end

