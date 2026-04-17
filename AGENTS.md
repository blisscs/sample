# AGENTS.md - AI Agent Context

This file contains project-specific context and conventions for AI agents working on this codebase.

## Project Overview

**Type**: Demo/Production-Ready Application  
**Domain**: Web Application with Observability Stack  
**Primary Language**: Elixir  
**Framework**: Phoenix 1.8.5

## Project Structure Conventions

### Folder Organization

This project uses a **multi-folder structure** for modularity:

```
demo/
├── app/              # Phoenix application (main code)
├── clickhouse/       # ClickHouse database configuration
├── grafana/          # Grafana dashboards and datasources
├── otel/             # OpenTelemetry Collector configuration
└── kamal/            # Kamal deployment configuration
```

**Rule**: Keep domain-specific configurations in their respective folders. Don't merge into root.

### Technology Versions (Locked)

| Component    | Version | Notes                              |
|--------------|---------|------------------------------------|
| Elixir       | 1.19.5  | Stable release                     |
| Erlang/OTP   | 28.4.2  | Stable release                     |
| PostgreSQL   | 18.3    | Latest stable                      |
| ClickHouse   | 26.3    | LTS release                        |
| Phoenix      | 1.8.5   | Hex package version                |
| Grafana      | 13.x    | Use `latest` tag in Docker         |
| Kamal        | 2.x     | Latest stable                      |

**Rule**: Before updating any version, verify with web search. Versions above are confirmed as of project creation.

## Development Environment

### Local Setup

1. **Elixir/Erlang**: Managed via `.tool-versions` + asdf
2. **Infrastructure**: Docker Compose (PostgreSQL, ClickHouse, Grafana, OTel Collector)
3. **Phoenix**: Runs locally (not in Docker for dev)

**Rule**: Phoenix runs locally in dev; only infrastructure services run in Docker.

### Commands by Context

| Action              | Location    | Command                              |
|---------------------|-------------|--------------------------------------|
| Install deps        | `app/`      | `mix deps.get`                       |
| Run tests           | `app/`      | `mix test`                           |
| Start server        | `app/`      | `mix phx.server`                     |
| Database ops        | `app/`      | `mix ecto.*`                         |
| Start infra         | Root        | `docker-compose up -d`               |
| Stop infra          | Root        | `docker-compose down`                |
| View logs           | Root        | `docker-compose logs <service>`      |
| Deploy              | Root        | `kamal deploy`                       |

**Rule**: Always run Elixir commands from `app/` folder, Docker commands from root.

## Architecture Patterns

### OpenTelemetry Flow

```
Phoenix App (Telemetry) 
    → OTLP/HTTP 
    → OpenTelemetry Collector (otel/otel-collector-config.yml)
    → ClickHouse Exporter
    → ClickHouse (clickhouse/migrations/init.sql)
    → Grafana (grafana/provisioning/)
```

**Rule**: All telemetry configuration lives in respective folders, not inline in Phoenix.

### Telemetry Events

Phoenix emits these event namespaces:

| Namespace              | Source                          |
|------------------------|---------------------------------|
| `[:phoenix, :*]`       | Phoenix framework               |
| `[:app, :*]`          | Custom application events       |
| `[:vm, :*]`            | Erlang VM metrics               |
| `[:ecto, :*]`          | Database queries                |

**Rule**: Custom events should use `[:demo, :event_name]` namespace.

## Code Style

### Elixir Conventions

- **Formatter**: Use `mix format` (config in `app/.formatter.exs`)
- **Credo**: Run `mix credo` if available
- **Module naming**: `AppWeb.*` for web layer, `App.*` for contexts
- **Function naming**: `snake_case`
- **Private functions**: Prefixed with `_` or marked with `@doc false`

### Code Generation

**Rule**: When possible, always rely on Phoenix generators rather than generating code manually.

**Rationale**: Generators ensure consistent file structure, naming conventions, and boilerplate that aligns with Phoenix best practices. They also reduce the risk of human error.

**Preferred Generators**:
- `mix phx.gen.context` - Generate context with schema and migration
- `mix phx.gen.html` - Generate controller, views, templates, and tests
- `mix phx.gen.json` - Generate JSON API controller
- `mix ecto.gen.migration` - Generate database migrations
- `mix phx.gen.auth` - Generate authentication

**When to generate manually**: Only when the generator cannot produce the required structure, or for custom business logic that doesn't fit standard patterns.

### Comment Maintenance

**Rule**: When editing code that has associated comments, always check if the comments need to be updated as well.

**Rationale**: Comments often describe implementation details, library choices, or configuration values. When these change, comments can become misleading or outdated.

**Examples**:
- When changing a library/module reference (e.g., `Jason` → `JSON`), update comment from `# Use Jason for...` to `# Use JSON for...`
- When changing a configuration value, update inline comments that document the value
- When refactoring function logic, update `@doc` strings that describe the behavior

### Configuration Management

| Environment | Config File             | Notes                      |
|-------------|-------------------------|----------------------------|
| Dev         | `app/config/dev.exs`    | Local overrides allowed    |
| Test        | `app/config/test.exs`   | Separate test database     |
| Prod        | `app/config/runtime.exs`| Env var based              |

**Rule**: Never hardcode secrets in config files. Use env vars in production.

## Docker Configuration

### Service Dependencies

```yaml
# Startup order matters
1. postgres
2. clickhouse
3. otel-collector
4. grafana
5. app (depends on all above)
```

### Volume Mounts

| Service      | Host Path                    | Container Path                    |
|--------------|------------------------------|-----------------------------------|
| clickhouse   | `./clickhouse/migrations`    | `/docker-entrypoint-initdb.d`     |
|              | `./clickhouse/config`        | `/etc/clickhouse-server/config.d` |
| grafana      | `./grafana/provisioning`     | `/etc/grafana/provisioning`       |
| otel         | `./otel/otel-collector-config.yml` | `/etc/otelcol-contrib/config.yaml` |

**Rule**: Configuration is mounted read-only where possible.

## Deployment

### Kamal Configuration

- **Config location**: `kamal/deploy.yml`
- **Required vars**: See `AGENTS.md` deployment section
- **Registry**: Docker Hub or GHCR (configurable)
- **Proxy**: Traefik (auto-managed by Kamal)

**Rule**: Kamal config uses relative paths from project root.

### GitHub Actions

- **Workflow location**: `.github/workflows/deploy.yml`
- **Trigger**: Push to `main` branch
- **Secrets required**:
  - `KAMAL_HOST` (VPS IP)
  - `KAMAL_SSH_KEY` (private key)
  - `DOCKER_USERNAME`
  - `DOCKER_PASSWORD`

## Testing

### Test Structure

```
app/test/
├── app/              # Context tests
├── app_web/          # Web layer tests
│   ├── controllers/
│   └── live/
└── support/          # Test helpers
```

**Rule**: Match test file structure to `lib/` structure.

### Testing Commands

```bash
cd app
mix test                    # Run all tests
mix test --failed           # Re-run failed tests
mix test test/path_test.exs # Run specific test file
mix test --trace            # Verbose output
```

## Database

### Migration Naming

```
priv/repo/migrations/
├── 20250416000001_create_users.exs
├── 20250416000002_create_posts.exs
└── 20250416000003_add_indexes.exs
```

**Rule**: Use descriptive names, prefix with timestamp.

### Ecto Conventions

- **Contexts**: Group related schemas (e.g., `App.Accounts`, `App.Blog`)
- **Schemas**: Define changesets for all public functions
- **Indexes**: Add for foreign keys and frequently queried fields

## Observability

### Adding Custom Metrics

```elixir
# In controllers or contexts
:telemetry.execute(
  [:demo, :custom_event],
  %{count: 1, duration: time_ms},
  %{user_id: user_id, action: "create"}
)
```

### Metric Types

| Type        | Use Case                    | ClickHouse Table    |
|-------------|-----------------------------|---------------------|
| Counter     | Incremental counts          | otel_metrics        |
| Histogram   | Duration distributions      | otel_metrics        |
| Gauge       | Point-in-time values        | otel_metrics        |
| Traces      | Request traces              | otel_traces         |

## Security Considerations

### Environment Variables

**Never commit files containing:**
- `SECRET_KEY_BASE`
- Database passwords
- API keys
- SSH private keys

**Pattern**: Use `.env.example` for templates, `.env.local` for local overrides (gitignored).

### Dependencies

**Rule**: Before adding new hex packages, consider:
1. Is it actively maintained?
2. Does it have good documentation?
3. Is the license compatible?
4. Can we achieve the same with standard library?

## Common Tasks

### Add a New Page

1. Create controller: `app/lib/app_web/controllers/new_controller.ex`
2. Create view template: `app/lib/app_web/controllers/new_html.ex`
3. Add route: `app/lib/app_web/router.ex`
4. Add test: `app/test/app_web/controllers/new_controller_test.exs`

### Add a Database Table

1. Generate migration: `cd app && mix ecto.gen.migration create_table_name`
2. Define migration in generated file
3. Create schema: `app/lib/app/table_name.ex`
4. Add to context: `app/lib/app/context_name.ex`
5. Run migration: `mix ecto.migrate`

### Update Docker Images

1. Update version in `docker-compose.yml`
2. Update version documentation in `AGENTS.md` and `README.md`
3. Test locally: `docker-compose up -d`
4. Document any breaking changes

## Troubleshooting Guide

### "No data in Grafana"

1. Check ClickHouse: `docker-compose exec clickhouse clickhouse-client`
2. Query: `SELECT * FROM otel_metrics LIMIT 5`
3. Check OTel logs: `docker-compose logs otel-collector`
4. Verify Phoenix is sending: Check `app/config/runtime.exs`

### "Database connection failed"

1. Check PostgreSQL is running: `docker-compose ps postgres`
2. Verify `DATABASE_URL` format
3. Check network: `docker network ls`

### "Phoenix won't start"

1. Check Elixir version: `elixir --version`
2. Reinstall deps: `cd app && mix deps.clean --all && mix deps.get`
3. Check for compilation errors: `mix compile`

## Resources for Agents

When working on this project, refer to:

1. **README.md** - User-facing documentation
2. **AGENTS.md** (this file) - Project-wide AI agent context
3. **app/AGENTS.md** - Phoenix-specific guidelines (always check when working in the Phoenix app)
4. **Official docs**:
   - Phoenix: https://hexdocs.pm/phoenix/
   - Ecto: https://hexdocs.pm/ecto/
   - OpenTelemetry: https://opentelemetry.io/docs/

## Contact

For questions about this project structure, see README.md.
