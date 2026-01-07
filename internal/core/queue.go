package core

import (
	"context"
	"sync"
)

// JobState represents the state of a download job
type JobState string

const (
	JobStatePending     JobState = "pending"
	JobStateDownloading JobState = "downloading"
	JobStateCompleted   JobState = "completed"
	JobStateFailed      JobState = "failed"
	JobStateCancelled   JobState = "cancelled"
)

// Job represents a download job
type Job struct {
	ID              string
	URL             string
	Provider        string
	Destination     string
	State           JobState
	Progress        float64
	BytesDownloaded int64
	BytesTotal      int64
	Error           error
}

// JobQueue manages download jobs with concurrency limits
type JobQueue struct {
	maxConcurrent int
	jobs          map[string]*Job
	mu            sync.RWMutex
	ctx           context.Context
	cancel        context.CancelFunc
}

// NewJobQueue creates a new job queue
func NewJobQueue(maxConcurrent int) *JobQueue {
	ctx, cancel := context.WithCancel(context.Background())
	return &JobQueue{
		maxConcurrent: maxConcurrent,
		jobs:          make(map[string]*Job),
		ctx:           ctx,
		cancel:        cancel,
	}
}

// Add adds a new job to the queue
func (q *JobQueue) Add(job *Job) error {
	q.mu.Lock()
	defer q.mu.Unlock()

	q.jobs[job.ID] = job
	job.State = JobStatePending

	// TODO: Implement actual job processing
	return nil
}

// Get retrieves a job by ID
func (q *JobQueue) Get(id string) (*Job, bool) {
	q.mu.RLock()
	defer q.mu.RUnlock()

	job, ok := q.jobs[id]
	return job, ok
}

// List returns all jobs
func (q *JobQueue) List() []*Job {
	q.mu.RLock()
	defer q.mu.RUnlock()

	jobs := make([]*Job, 0, len(q.jobs))
	for _, job := range q.jobs {
		jobs = append(jobs, job)
	}
	return jobs
}

// Cancel cancels a job
func (q *JobQueue) Cancel(id string) error {
	q.mu.Lock()
	defer q.mu.Unlock()

	job, ok := q.jobs[id]
	if !ok {
		return ErrJobNotFound
	}

	job.State = JobStateCancelled
	// TODO: Actually cancel the download
	return nil
}

// Stop stops the job queue
func (q *JobQueue) Stop() {
	q.cancel()
}

// ErrJobNotFound is returned when a job ID is not found
var ErrJobNotFound = &JobError{Message: "job not found"}

// JobError represents a job-related error
type JobError struct {
	Message string
}

func (e *JobError) Error() string {
	return e.Message
}
