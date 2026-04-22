# ClickHouse logger migration
# Creates the logs table used by the clickhouse_logger Elixir backend.

CREATE DATABASE IF NOT EXISTS logs;

CREATE TABLE IF NOT EXISTS logs.logs (
    ts UInt64,
    level UInt8,
    msg String,
    module String,
    function String,
    file String,
    line UInt32,
    request_id String
)
ENGINE = MergeTree()
ORDER BY ts;
