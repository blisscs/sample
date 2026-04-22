# Demo Project: Phoenix + PostgreSQL + ClickHouse + Grafana + Kamal

A production-ready demo application showcasing modern observability stack with Elixir Phoenix, PostgreSQL, ClickHouse for metrics storage, Grafana for visualization, and Kamal for deployment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Local Development                           │
├─────────────────────────────────────────────────────────────────┤
│  Host Machine:                                                  │
│    ├── Elixir 1.19.5 (via .tool-versions)                      │
│    ├── Erlang/OTP 28.4.2                                        │
│    └── Phoenix 1.8.5 (local)                                    │
│                                                                 │
│  Docker Compose:                                                │
│    ├── PostgreSQL 18.3 (port 5433)                             │
│    ├── ClickHouse 26.3 LTS (port 8124/9001)                  │
│    ├── OpenTelemetry Collector (port 4319/4320)              │
│    └── Grafana 13.x (port 3001)                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Production (VPS)                          │
├─────────────────────────────────────────────────────────────────┤
│  Kamal 2.x Deployment:                                          │
│    ├── Phoenix App (Docker) → Traefik proxy                    │
│    ├── PostgreSQL 18.3 (Docker)                                │
│    ├── ClickHouse 26.3 LTS (Docker)                              │
│    ├── OpenTelemetry Collector (Docker)                        │
│    └── Grafana 13.x (Docker)                                    │
│                                                                 │
│  HTTPS via Let's Encrypt (auto-managed by Kamal/Traefik)       │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
demo/
├── .tool-versions                    # asdf version management
├── docker-compose.yml                # Local development orchestration
├── README.md                         # This file
├── AGENTS.md                         # AI agent context and conventions
│
├── app/                              # Phoenix Application
│   ├── config/                       # Application configuration
│   ├── lib/                          # Business logic
│   ├── priv/                         # Database migrations, static assets
│   ├── rel/                          # Release configuration
│   ├── Dockerfile                    # Production image
│   └── mix.exs                       # Elixir dependencies
│
├── clickhouse/                       # ClickHouse Configuration
│   ├── config/                       # Custom ClickHouse config
│   ├── migrations/                   # Schema initialization
│   └── data/                         # Data volume (gitignored)
│
├── grafana/                          # Grafana Configuration
│   ├── provisioning/                 # Auto-provisioned configs
│   │   ├── datasources/              # ClickHouse data source
│   │   └── dashboards/               # Pre-built dashboards
│   └── data/                         # Data volume (gitignored)
│
├── otel/                             # OpenTelemetry Collector
│   └── otel-collector-config.yml     # OTel → ClickHouse config
│
└── kamal/                            # Kamal Deployment
    └── deploy.yml                    # Kamal deployment configuration
```

## Technology Stack

| Component        | Version        | Purpose                          |
|------------------|----------------|----------------------------------|
| Elixir           | 1.19.5         | Primary language                 |
| Erlang/OTP       | 28.4.2         | BEAM runtime                     |
| Phoenix          | 1.8.5          | Web framework                    |
| PostgreSQL       | 18.3           | Application data                 |
| ClickHouse       | 26.3 LTS       | Metrics & observability backend  |
| Grafana          | 13.x           | Visualization & dashboards       |
| OpenTelemetry    | Latest         | Telemetry collection             |
| Kamal            | 2.x            | Deployment tool                  |

## Prerequisites

### Local Development

1. **asdf** version manager installed
2. **Docker** and **Docker Compose** installed
3. **Elixir/Erlang** via asdf (see `.tool-versions`)

### Setup

```bash
# Install Elixir/Erlang via asdf
cd /home/suracheth-chawla/Projects/demo
asdf install

# Verify installation
elixir --version
# Should show Elixir 1.19.5 and Erlang/OTP 28.4.2
```

## Quick Start

### 1. Start Infrastructure Services

```bash
# Start PostgreSQL, ClickHouse, Grafana, and OTel Collector
docker-compose up -d postgres clickhouse grafana otel-collector

# Wait for services to be ready (30 seconds)
docker-compose ps
```

### 2. Setup Phoenix Application

```bash
cd app

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start Phoenix server
mix phx.server
```

### 3. Access the Application

| Service   | URL                     | Credentials               |
|-----------|-------------------------|---------------------------|
| Phoenix   | http://localhost:4000   | -                         |
| Grafana   | http://localhost:3001   | admin/admin               |
| Health    | http://localhost:4000/health | -                     |

### 4. View Telemetry in Grafana

1. Open http://localhost:3001
2. Login with `admin/admin`
3. Navigate to Dashboards → Phoenix Application
4. See real-time metrics from your Phoenix app

## Development Workflow

### Running Tests

```bash
cd app
mix test
```

### Code Formatting

```bash
cd app
mix format
```

### Database Migrations

```bash
cd app
mix ecto.migrate
```

### Adding Telemetry Events

The application is pre-configured with OpenTelemetry. To add custom telemetry:

```elixir
# In your controller or context
:telemetry.execute([:demo, :custom_event], %{count: 1}, %{metadata: "value"})
```

## Telemetry Architecture

```
Phoenix App ──OTLP/HTTP──► OpenTelemetry Collector ──ClickHouse Exporter──► ClickHouse
                              (otel/ folder)                                      │
                                                                                   ▼
                                                                            ┌─────────────┐
                                                                            │   Grafana   │
                                                                            │  (Dashboard)│
                                                                            └─────────────┘
```

### Collected Metrics

- **HTTP Request Metrics**: Duration, status codes, endpoint usage
- **VM Metrics**: Memory usage, scheduler stats, process counts
- **Custom Business Metrics**: Health check counts, homepage visits
- **Database Metrics**: Ecto query durations

## Logging Architecture

This project collects logs through two independent paths:

1. **Application Logs** (`clickhouse_logger`): Elixir Logger backend sends logs directly to ClickHouse via HTTP
2. **Telemetry/Traces** (OpenTelemetry): Metrics and traces via OTel Collector → ClickHouse

### Log Data Flow

```
Phoenix App ──Logger Backend──► ClickHouse (logs DB)
     │
     └───OTLP/HTTP──► OTel Collector ──► ClickHouse (default DB)
                              │
                              └─── Metrics, Traces, Exponential Histograms
```

### ClickHouse Databases and Tables

| Database | Table | Purpose | Source |
|----------|-------------|----------|---------|
| `logs` | `logs` | Application logs (level, message, module, file, line, request_id) | `clickhouse_logger` |
| `default` | `otel_metrics_*` | Counter, gauge, histogram, summary metrics | OTel Collector |
| `default` | `otel_traces` | Distributed traces (spans, trace IDs) | OTel Collector |
| `default` | `otel_logs` | OpenTelemetry logs (if configured) | OTel Collector |

### ClickHouse Logs Table Schema

```sql
-- logs.logs (Application logs from clickhouse_logger)
CREATE TABLE logs.logs (
    ts        UInt64,    -- timestamp in milliseconds
    level     UInt8,     -- 0=debug, 1=info, 2=warn, 3=error
    msg       String,    -- log message
    module    String,    -- Elixir module name
    function  String,    -- function name
    file      String,    -- source file path
    line      UInt32,    -- line number
    request_id String    -- Phoenix request ID
)
ENGINE = MergeTree()
ORDER BY ts;
```

## Viewing Logs in Grafana

### Prerequisites

Infrastructure services must be running:

```bash
docker compose up -d postgres clickhouse grafana
```

Verify the datasource is provisioned:

```bash
curl -s http://admin:admin@localhost:3001/api/datasources | grep -o '"name":"[^"]*"'
# Expected: "name":"ClickHouse"
```

If the datasource is missing, restart Grafana: `docker compose restart grafana`

### 1. Start Phoenix (to generate logs)

```bash
cd app
mix deps.get
mix ecto.setup     # if not already done
mix phx.server
```

Wait ~10 seconds (dev buffer timeout) for logs to flush to ClickHouse, then visit `http://localhost:4000` to generate traffic.

### 2. Verify Data in ClickHouse

```bash
docker exec demo-clickhouse clickhouse-client --query '
  SELECT count() FROM logs.logs
'
# Expect a positive number after Phoenix has run briefly
```

### 3. Create Dashboard via UI (Manual)

1. Open **http://localhost:3001** → login `admin` / `admin`
2. Go to **+ → Dashboard → Add visualization**
3. Select datasource: **ClickHouse**
4. Build panels — suggested queries below

#### Panel A: Log Volume (Time Series)

- **Query** (raw SQL):

```sql
SELECT toDateTime(ts / 1000) as t, count() as cnt
FROM logs.logs
WHERE ts >= (now() - INTERVAL 1 HOUR)
GROUP BY t
ORDER BY t
```

- **Visualization**: Time series
- Set **X-axis** to field `t`, **Y-axis** to field `cnt`

#### Panel B: Log Level Distribution (Pie Chart)

- **Query**:

```sql
SELECT
  multiIf(level = 0, 'debug', level = 1, 'info', level = 2, 'warn', level = 3, 'error', 'other') as level_name,
  count() as cnt
FROM logs.logs
WHERE ts >= (now() - INTERVAL 1 HOUR)
GROUP BY level_name
```

- **Visualization**: Pie chart
- Set **Value** to `cnt`, **Name** to `level_name`

#### Panel C: Latest Logs (Logs / Table)

- **Query**:

```sql
SELECT
  toDateTime(ts / 1000) as timestamp,
  multiIf(level = 0, 'debug', level = 1, 'info', level = 2, 'warn', level = 3, 'error', 'other') as level,
  msg as message,
  module,
  file,
  line,
  request_id
FROM logs.logs
WHERE ts >= (now() - INTERVAL 1 HOUR)
ORDER BY ts DESC
LIMIT 100
```

- **Visualization**: Table (or Logs panel if available)
- Add **Value mappings** for `level` field: `debug` = blue, `info` = green, `warn` = yellow, `error` = red

#### Panel D: Top Error Modules (Table)

- **Query**:

```sql
SELECT module, count() as cnt
FROM logs.logs
WHERE ts >= (now() - INTERVAL 1 HOUR)
GROUP BY module
ORDER BY cnt DESC
LIMIT 20
```

- **Visualization**: Table

### 4. Save Dashboard

- Click **Save** → Name: `Application Logs (ClickHouse Logger)`
- Optional: set refresh to `10s`

### Manual ClickHouse Verification (optional)

```bash
# Query recent logs directly
docker exec demo-clickhouse clickhouse-client --query '
  SELECT
    toDateTime(ts / 1000) as time,
    multiIf(level=0,\'debug\',level=1,\'info\',level=2,\'warn\',level=3,\'error\',\'other\') as lvl,
    msg,
    module
  FROM logs.logs
  ORDER BY ts DESC
  LIMIT 10
'

# Count by log level in the last hour
docker exec demo-clickhouse clickhouse-client --query '
  SELECT
    multiIf(level=0,\'debug\',level=1,\'info\',level=2,\'warn\',level=3,\'error\',\'other\') as lvl,
    count() as cnt
  FROM logs.logs
  WHERE ts >= (now() * 1000) - (3600 * 1000)
  GROUP BY lvl
'
```

## Deployment

### Prerequisites

1. VPS with SSH access
2. Docker installed on VPS
3. GitHub repository with secrets configured

### Configure Kamal

Edit `kamal/deploy.yml` with your:
- VPS IP address
- Domain name
- Registry credentials

### Deploy via GitHub Actions

Push to `main` branch triggers automatic deployment:

```bash
git add .
git commit -m "Prepare for deployment"
git push origin main
```

### Manual Deployment

```bash
# From project root
kamal deploy
```

## Configuration

### Environment Variables

| Variable                | Development           | Production           |
|-------------------------|-----------------------|----------------------|
| `DATABASE_URL`          | postgres://...        | Required             |
| `SECRET_KEY_BASE`       | auto-generated        | Required (64 chars)  |
| `PHX_HOST`              | localhost             | Your domain          |
| `OTEL_EXPORTER_ENDPOINT`| http://localhost:4320 | http://otel-collector|
| `CLICKHOUSE_URL`        | http://localhost:8124 | Required             |
| `GRAFANA_ADMIN_PASSWORD`| admin                 | Required             |

### Local Development

Create `app/.env.local` for local overrides (do not commit):

```bash
# app/.env.local
export DATABASE_URL="postgres://postgres:postgres@localhost/demo_dev"
```

## Troubleshooting

### Docker Services Won't Start

```bash
# Check logs
docker-compose logs

# Reset volumes (WARNING: data loss)
docker-compose down -v
docker-compose up -d
```

### Database Connection Issues

```bash
# Reset database
cd app
mix ecto.drop
mix ecto.setup
```

### No Data in Grafana

1. Check OTel Collector is running: `docker-compose ps otel-collector`
2. Verify ClickHouse schema: `docker-compose exec clickhouse clickhouse-client --query "SHOW TABLES"`
3. Check Phoenix logs for telemetry export errors

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Resources

- [Phoenix Documentation](https://hexdocs.pm/phoenix/)
- [OpenTelemetry Elixir](https://opentelemetry.io/docs/instrumentation/elixir/)
- [ClickHouse Documentation](https://clickhouse.com/docs)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kamal Documentation](https://kamal-deploy.org/)

## Support

For issues and questions:
1. Check AGENTS.md for AI agent context
2. Review the troubleshooting section above
3. Open an issue in the repository
