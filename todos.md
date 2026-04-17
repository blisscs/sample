# Project Initialization and Deployment Todos

This document tracks the steps needed to initialize the Phoenix application and prepare for the first deployment.

## Phase 1: Project Initialization

### Todo 1: Initialize Phoenix Application
- **Status**: pending

**Description:** Create a new Phoenix 1.8.5 application in the `app/` folder.

**Steps:**
1. Ensure Elixir 1.19.5 and Erlang 28.4.1 are installed
2. Install Phoenix 1.8.5 archive
3. Run `mix phx.new .` inside `app/` folder (uses directory name as app name)
4. Configure database settings in `config/dev.exs`
5. Update `.tool-versions` in app folder

**Files to be created:**
- Entire Phoenix project structure in `app/`

---

### Todo 2: Setup Docker Compose for Infrastructure
- **Status**: pending

**Description:** Configure Docker Compose for local development infrastructure (PostgreSQL, ClickHouse, Grafana, OTel Collector).

**Steps:**
1. Create `docker-compose.yml` with services:
   - PostgreSQL 18.3
   - ClickHouse 26.3 LTS
   - Grafana (latest)
   - OpenTelemetry Collector
2. Configure ClickHouse with init migrations
3. Configure Grafana with auto-provisioned datasources and dashboards
4. Configure OTel Collector with ClickHouse exporter

**Files to be created/modified:**
- `docker-compose.yml`
- `clickhouse/migrations/init.sql`
- `clickhouse/config/*.xml`
- `grafana/provisioning/datasources/clickhouse.yml`
- `grafana/provisioning/dashboards/*.json`
- `otel/otel-collector-config.yml`

---

### Todo 3: Configure Phoenix for Telemetry
- **Status**: pending

**Description:** Set up OpenTelemetry instrumentation in Phoenix application.

**Steps:**
1. Add opentelemetry dependencies to `mix.exs`
2. Configure telemetry in `config/runtime.exs`
3. Add custom telemetry events
4. Create health check endpoint
5. Add homepage with telemetry events

**Files to be modified/created:**
- `app/mix.exs`
- `app/config/runtime.exs`
- `app/lib/app_web/controllers/health_controller.ex`
- `app/lib/app_web/controllers/page_controller.ex`
- `app/lib/app/telemetry.ex`

---

### Todo 4: Create Basic Homepage
- **Status**: pending

**Description:** Create a simple homepage with health check endpoint.

**Steps:**
1. Create PageController with index action
2. Create health controller for /health endpoint
3. Create basic layout template
4. Add routes in router

**Files to be created:**
- `app/lib/app_web/controllers/page_controller.ex`
- `app/lib/app_web/controllers/health_controller.ex`
- `app/lib/app_web/controllers/page_html.ex`
- `app/lib/app_web/controllers/page_html/index.html.heex`

---

### Todo 5: Setup Kamal Deployment Configuration
- **Status**: pending

**Description:** Configure Kamal for deployment to VPS.

**Steps:**
1. Create `kamal/deploy.yml` with server configuration
2. Configure Docker registry settings
3. Set up Traefik proxy configuration
4. Configure SSL/Let's Encrypt

**Files to be created:**
- `kamal/deploy.yml`
- `app/Dockerfile` (production image)
- `.github/workflows/deploy.yml` (GitHub Actions workflow)

---

## Phase 2: First Deployment

### Todo 6: Test Local Development Setup
- **Status**: pending

**Description:** Verify everything works locally before deployment.

**Steps:**
1. Start infrastructure services: `docker-compose up -d`
2. Run migrations: `mix ecto.setup`
3. Start Phoenix server: `mix phx.server`
4. Verify health endpoint works
5. Verify Grafana shows data
6. Run tests: `mix test`

---

### Todo 7: Configure Production Secrets
- **Status**: pending

**Description:** Set up production environment variables.

**Steps:**
1. Generate `SECRET_KEY_BASE` for production
2. Configure database URL format
3. Set up Docker registry credentials
4. Configure VPS SSH access

---

### Todo 8: First Kamal Deployment
- **Status**: pending

**Description:** Deploy the application to VPS using Kamal.

**Steps:**
1. Push code to `main` branch
2. Trigger GitHub Actions workflow or run `kamal deploy`
3. Verify deployment succeeds
4. Test HTTPS endpoints
5. Verify Grafana dashboards in production

---

## Phase 3: Post-Deployment (Future Todos)

### Todo 9: Add User Authentication (Future)
- **Status**: pending

Add user authentication system with login/signup.

---

### Todo 10: Add Todos Feature (Future)
- **Status**: pending

Add a full CRUD todos feature with detail view.

---

## Quick Reference

### Commands

```bash
# Start infrastructure
docker-compose up -d postgres clickhouse grafana otel-collector

# Setup Phoenix
cd app
mix deps.get
mix ecto.setup
mix phx.server

# Deploy
kamal deploy
```

### Ports

- Phoenix: 4000
- Grafana: 3000
- PostgreSQL: 5432
- ClickHouse: 8123 (HTTP), 9000 (Native)
- OTel Collector: 4317 (gRPC), 4318 (HTTP)

## Notes

- Keep `.env.local` in `app/` for local database URL overrides (gitignored)
- Never commit secrets to repository
- All infrastructure runs in Docker except Phoenix (local dev)
- Phoenix runs in Docker for production deployment

