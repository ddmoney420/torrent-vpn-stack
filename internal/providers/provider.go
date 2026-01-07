package providers

import (
	"context"
)

// Provider defines the interface for download providers
type Provider interface {
	Name() string
	Download(ctx context.Context, req *DownloadRequest) (*DownloadJob, error)
	GetStatus(jobID string) (*JobStatus, error)
	Cancel(jobID string) error
}

// DownloadRequest represents a download request
type DownloadRequest struct {
	URL         string
	Destination string
	Metadata    map[string]string
	Priority    int
	RetryPolicy *RetryPolicy
}

// DownloadJob represents an active download job
type DownloadJob struct {
	ID string
}

// JobStatus represents the status of a download job
type JobStatus struct {
	ID              string
	State           string
	Progress        float64
	BytesDownloaded int64
	BytesTotal      int64
	Error           error
}

// RetryPolicy defines retry behavior
type RetryPolicy struct {
	MaxRetries int
	Backoff    string
}
