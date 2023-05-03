Introduction: This project aims to build a simple background job system that can be used with Rails applications and is based on GCP Pub/Sub. The system consists of a queue adapter that allows enqueueing of jobs to Pub/Sub and a rake task that dequeues and executes pending jobs. This repository contains:

A configured adapter (lib/active_job/queue_adapters/pubsub_adapter.rb) to enqueue jobs.
A rake task (lib/tasks/worker.rake) to launch the worker process. It pulls the messages from a subscription
A class (lib/pubsub.rb) that wraps the GCP Pub/Sub client.
A Dockerfile and a docker-compose.yml configured to spin up necessary services (web server, worker, pub/sub emulator).
To start all services, open 3 terminal windows, make sure you have Docker installed and run:

1) Terminal window 1: docker-compose up --build
2) Terminal window 2: docker-compose run --rm worker bin/rails worker:run
3) Terminal 3: docker-compose run --rm worker bin/rails worker:test
You can observe messages being enqueued at Terminal window 3, and observe them being pulled from the PubSub topic in the Terminal window 2.

Retry logic semantics. Note! I implemented 5 second delay so that it will be easier for you to observe the retry logic in the logs: The retry logic is implemented in a rescue block, which catches a specific exception SimulatedJobFailure that may occur during job execution. If the exception is caught, the method retries the job up to three times with a delay of 5 seconds between retries. If the job still fails after three attempts, it is enqueued to a 'morgue' queue. My initial plan was to implement the retry logic with "retry on", and I have a version of that code as well. I admit, i though this method seemed elegant and easy at first, I got stuck in trying to properly trigger the retry logic, and decided to move on to this implementation.

The perform method also logs the progress of the job by printing status messages to the console, depending on whether the job was completed successfully or not.

In terms of message semantics, this approach can lead to at least once message semantics, as the job is retried up to three times if an error occurs. If the job fails after three attempts, it is enqueued to the 'morgue' queue, where it will likely be processed only once.