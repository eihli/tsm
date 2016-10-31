# Transactional State Manager

Helper for handling API to API integrations.

![UML Diagram](/diagrams/tsm.png)

## Major Classes

### WorkerManager

- Has many workers
- Responsible for enqueueing workers in order and handling worker exceptions
- Aggregates workers results

### Worker

- Belongs to a WorkerManager
- Has one state saved in an in-memory store
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
