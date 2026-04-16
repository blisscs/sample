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
│    ├── PostgreSQL 18.3 (port 5432)                             │
│    ├── ClickHouse 26.3 LTS (port 8123/9000)                  │
│    ├── OpenTelemetry Collector (port 4317/4318)              │
│    └── Grafana 13.x (port 3000)                                │
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
| Grafana   | http://localhost:3000   | admin/admin               |
| Health    | http://localhost:4000/health | -                     |

### 4. View Telemetry in Grafana

1. Open http://localhost:3000
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
| `OTEL_EXPORTER_ENDPOINT`| http://localhost:4318 | http://otel-collector|
| `CLICKHOUSE_URL`        | http://localhost:8123 | Required             |
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
