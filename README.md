# Transactional State Manager

Helper for handling API to API integrations.

## The Problem

- Your integration workflow requires making a large number of long-running requests to many different APIs
- Some of those requests can happen in parallel, others must happen in series
- Requests can fail for many reasons, some failures are retriable, some failures should be sent to the user, some logged for developers
- The background jobs which are making these requests can fail at any time
- You cannot lose data, nor do you want duplicate requests to be made

## The Solution

- Each request happens in a single worker process (Redis/Resque/DelayedJob/Celery/Etc...)
  - This keeps a single long-running 'job' with many requests from blocking the entire queue
- Workers persist their state (in-memory cache)
  - At the start of their 'perform' method
    - If their status is already 'started'
      - It means they were started at some point in the past but the process died before verification
      - Handle a restart by checking to see if the work completed
    - Else, they update their state to 'started'
  - After their work has been completed and verified
    - They update their state to 'success' or 'failure'
    - They persist their result, either some 'payload' object, or an error message
- WorkerManagers enqueue and subscribe to updates from workers
  - Handle the ordering of workers - some are parallel, some series
  - Aggregate results
    - Some workers may have error messages that don't block success of the entire job
    - Some workers may need to be enqueued with the results of several other workers
- EventService
  - Pub/Sub for Workers/WorkerManagers/Other subscribers (Logs, Status bar, Error handle...)
- TODO:
  - Think about how to handle retries and backoff strategy

![UML Diagram](/diagrams/tsm.png)

## Major Classes

### WorkerManager

- Has many workers
- Responsible for enqueueing workers in order and handling worker exceptions
- Aggregates workers results
- Can use results from previous workers as arguments to instantiate later workers
- Listen to workers
  - http://stackoverflow.com/questions/6463945/whats-the-most-efficient-node-js-inter-process-communication-library-method
  - https://www.devco.net/archives/2013/01/06/solving-monitoring-state-storage-problems-using-redis.php
  - http://kschiess.github.io/cod/

### Worker

- Belongs to a WorkerManager
- Has state saved in an in-memory store
- Is enqueued for background work
- Succeeds or fails, updates state, returns data for WorkerManager aggregation

### JobManager

- Parses a JobDefinition
- Persists Workers and WorkerManagers to disk storage
- Enqueues WorkerManager

### JobDefinition

- Iterable describing Workers
- Contains args for Workers to be initialized with
- Defines order in which Workers are enqueued

### Verifier

- Used by Worker to determine success/failure of work

### EventStore | MessageQueue

- Pubsub service for Workers and WorkerManagers to communicate

## Workflow

### App and WorkerManagers

- App starts
- Grab WorkerManagers from DB which haven't updated their last\_polled recently (Their process died due to a dirty exit or something)
- For each WorkerManager retrieved
  - Get its Workers in order defined by JobDefinition
  - For each Worker, in order
    - Enqueue the Worker
    - Poll the Worker's state until either
      - Timeout is reached
        - Handle timeout (Log error/Retry)
      - State is completed (success/failure)
        - Handle completion (Log success/Log failure/Retry)
      - Update WorkerManager last\_polled
  - Handle WorkerManager completion (Log result, remove Workers/Manager from storage)

### Workers

- Worker is pulled off queue and `perform` method is called on it
- It checks its state
- If state is started, it means a previous process with this worker was killed in the middle of working
  - Check to see if the work finished
    - Make a GET request for whatever you were trying to POST to see if it was successfully created
    - Maybe some other job already finished what you were trying to do
    - Update state and continue appropriately
- If state is pending
  - Update state to started and get to work
  - When work is complete
    - Verify work
    - Handle result and update state to success/failed
- Return result (if necessary) for WorkerManager aggregation


# Appendix

## Graphviz DOT and VIM

I'm using this repo as an excuse to try out UML diagramming with [Graphviz](http://www.graphviz.org/).

There is a [cool vim plugin](https://github.com/wannesm/wmgraphviz.vim) which gives you some handy shortcuts to automatically compile and view DOT files.
