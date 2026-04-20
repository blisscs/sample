-- Create the table for OTel metrics
CREATE TABLE IF NOT EXISTS otel_metrics (
    name String,
    value Float64,
    timestamp DateTime64(3),
    attributes Map(String, String)
) ENGINE = MergeTree()
ORDER BY (name, timestamp);

-- Create the table for OTel traces
CREATE TABLE IF NOT EXISTS otel_traces (
    trace_id String,
    span_id String,
    parent_span_id String,
    name String,
    start_time DateTime64(3),
    end_time DateTime64(3),
    duration Float64,
    attributes Map(String, String),
    status String
) ENGINE = MergeTree()
ORDER BY (name, start_time);
