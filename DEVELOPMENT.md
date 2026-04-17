# Local Development Guide

This guide helps you develop and test the Phoenix application locally.

## Prerequisites

- Elixir 1.19.5 and Erlang 28.4.1 (via `.tool-versions`)
- Docker (for PostgreSQL)

## Development Workflow

### 1. Start Infrastructure

```bash
# Start PostgreSQL (runs in Docker)
docker compose up -d postgres

# Verify PostgreSQL is running
docker ps

# Check PostgreSQL logs
docker compose logs postgres -f
```

**Connection Info:**
- Host: `localhost`
- Port: `5433`
- Username: `postgres`
- Password: `postgres`
- Databases: `app_dev`, `app_test`

### 2. Setup Phoenix Application

```bash
cd app

# Install dependencies
mix deps.get

# Create database and run migrations
mix ecto.setup
```

### 3. Start Phoenix Server

```bash
# Start the server
mix phx.server

# Or start with IEx for debugging
iex -S mix phx.server
```

**Access:**
- Application: http://localhost:4000
- LiveDashboard: http://localhost:4000/dev/dashboard

### 4. Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/app_web/controllers/page_controller_test.exs

# Run failed tests only
mix test --failed

# Run with verbose output
mix test --trace
```

**Note:** Tests automatically create the `app_test` database.

### 5. Database Operations

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop + create + migrate)
mix ecto.reset

# Access database console
mix ecto.psql
```

### 6. Code Quality

```bash
# Format code
mix format

# Check for compilation warnings
mix compile --warnings-as-errors

# Run precommit checks (compile + deps.unlock --unused + format + test)
mix precommit
```

## Common Tasks

### Reset Everything

```bash
# Stop infrastructure
docker compose down

# Remove database volume
docker compose down -v

# Start fresh
docker compose up -d postgres
cd app
mix deps.clean --unused
mix deps.get
mix ecto.setup
mix phx.server
```

### Check What's Running

```bash
# Docker containers
docker ps

# Docker logs
docker compose logs

# Phoenix processes
ps aux | grep beam
```

## Troubleshooting

### PostgreSQL Connection Failed

```bash
# Check if PostgreSQL is running
docker compose ps

# Check PostgreSQL logs
docker compose logs postgres

# Verify port 5433 is not in use
lsof -i :5433
```

### Mix Tasks Failing

```bash
# Clean and reinstall deps
cd app
mix deps.clean --all
mix deps.get
mix deps.compile
```

### Port Already in Use

The PostgreSQL container uses **port 5433** (not 5432) to avoid conflicts with any PostgreSQL running on your host machine.

## Git Workflow

1. **Pull latest changes:** `git pull origin main`
2. **Create feature branch:** `git checkout -b feature/my-feature`
3. **Commit changes:** `git commit -m "descriptive message"`
4. **Push branch:** `git push -u origin feature/my-feature`
5. **Create PR** via GitHub

## File Structure Reminder

```
demo/
├── app/              # Phoenix application
│   ├── config/       # Configuration
│   ├── lib/          # Application code
│   ├── priv/          # Database migrations
│   └── test/         # Tests
├── docker-compose.yml # Infrastructure (PostgreSQL)
├── todos.md          # Project todos
└── AGENTS.md         # Project conventions
```

**When working in the Phoenix app, also check `app/AGENTS.md` for Phoenix-specific guidelines.**
