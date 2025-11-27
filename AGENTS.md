# AGENTS.md — Battle Monorepo

Project context for AI coding assistants. Keep this concise and actionable.

## Project Overview

**Battle** is a full-stack web application skeleton for rapid development.

| Layer | Stack |
|-------|-------|
| Frontend | React 19 + TypeScript + Vite 7 + Tailwind CSS |
| Backend | Python 3.12+ + FastAPI + SQLModel |
| Database | PostgreSQL 16 |
| Auth | JWT (OAuth2 password flow) |
| Deployment | Docker Compose + Traefik + GHCR |

## Quick Reference

### Essential Commands

```bash
./scripts/dev.sh      # Start dev environment (DB + backend + frontend)
./scripts/dev-stop.sh # Stop everything
```

**VS Code**: Press F5 → "Full Stack Dev" (uses same scripts)

### URLs (Development)

- Frontend: http://localhost:3002
- Backend API: http://localhost:8002
- API Docs: http://localhost:8002/docs

### URLs (Production)

- App: https://app.battle.wopee.io

## Claude Code Workflow

### Testing Backend Changes

After modifying backend code, verify with curl:

```bash
# Health check
curl http://localhost:8002/health

# Test specific endpoint
curl http://localhost:8002/your-endpoint

# View backend logs
tail -f logs/backend.log
```

### Testing Frontend Changes

After modifying frontend code, verify with Chrome MCP:

```
# Navigate to page
mcp__chrome-devtools__navigate_page url="http://localhost:3002"

# Get page structure (returns element UIDs)
mcp__chrome-devtools__take_snapshot

# Click element
mcp__chrome-devtools__click uid="<uid-from-snapshot>"

# Fill input field
mcp__chrome-devtools__fill uid="<input-uid>" value="test"

# Verify visual result
mcp__chrome-devtools__take_screenshot
```

### Common MCP Operations

| Action | Command |
|--------|---------|
| Navigate | `mcp__chrome-devtools__navigate_page url="..."` |
| Inspect DOM | `mcp__chrome-devtools__take_snapshot` |
| Click | `mcp__chrome-devtools__click uid="..."` |
| Type text | `mcp__chrome-devtools__fill uid="..." value="..."` |
| Screenshot | `mcp__chrome-devtools__take_screenshot` |
| Press key | `mcp__chrome-devtools__press_key key="Enter"` |

### Debugging

```bash
# View logs
tail -f logs/backend.log   # Backend
tail -f logs/frontend.log  # Frontend

# Restart everything
./scripts/dev-stop.sh && ./scripts/dev.sh
```

## Directory Structure

```
/
├── frontend/                 # React + TypeScript SPA
│   ├── src/
│   │   ├── api/client.ts     # Typed API client with token management
│   │   ├── components/       # React components
│   │   ├── App.tsx           # Root component + routing
│   │   └── main.tsx          # Entry point
│   ├── vite.config.ts        # Vite config (API proxy: /auth, /items, /health)
│   └── package.json
│
├── backend/                  # FastAPI application
│   └── app/
│       ├── main.py           # FastAPI setup, CORS, routers
│       ├── config.py         # Pydantic Settings (env-based)
│       ├── db.py             # Database session factory
│       ├── models.py         # SQLModel ORM: User, Item
│       ├── schemas.py        # Pydantic request/response schemas
│       ├── auth_jwt.py       # JWT create/verify utilities
│       ├── auth_routes.py    # /auth/* endpoints
│       ├── routes_items.py   # /items/* CRUD endpoints
│       ├── routes_public.py  # /health endpoint
│       └── github_oauth.py   # GitHub OAuth (placeholder)
│
├── deployment/               # Production deployment
│   ├── battle.wopee.io/      # Prod environment config
│   │   ├── .env              # Non-secret config
│   │   ├── versions.env      # Docker image versions
│   │   └── secrets.enc.env   # SOPS-encrypted secrets
│   ├── up.sh                 # Deploy script
│   └── down.sh               # Teardown script
│
├── openspec/                 # Spec-driven development
│   ├── AGENTS.md             # OpenSpec workflow instructions
│   ├── project.md            # Project conventions
│   ├── specs/                # Current capability specs
│   └── changes/              # Proposed changes
│
├── utils/                    # Shared utilities
├── docker-compose.yml        # Dev orchestration
├── .env.example              # Environment template
└── .github/workflows/        # CI/CD pipelines
```

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health` | GET | No | Health check |
| `/auth/register` | POST | No | Create user account |
| `/auth/token` | POST | No | Get JWT token (OAuth2 password flow) |
| `/auth/me` | GET | Yes | Current user info |
| `/items` | GET | Yes | List user's items |
| `/items` | POST | Yes | Create item |
| `/items/{id}` | DELETE | Yes | Delete item |

## Database Models

```python
# backend/app/models.py

class User:
    id: int (PK)
    email: str (unique, indexed)
    username: str (unique, indexed)
    hashed_password: str
    is_active: bool
    created_at: datetime

class Item:
    id: int (PK)
    title: str
    description: Optional[str]
    owner_id: int (FK → user.id)
    created_at: datetime
```

## Code Conventions

### TypeScript (Frontend)

- Strict mode enabled (`tsconfig.json`)
- Path alias: `@/` → `src/`
- Components: PascalCase files in `components/`
- API calls: Use `api/client.ts` with typed responses
- Styling: Tailwind CSS utilities

### Python (Backend)

- Python 3.12+ required
- Type hints on all functions
- SQLModel for ORM (combines SQLAlchemy + Pydantic)
- Pydantic Settings for configuration
- Logging: Use `logging.getLogger(__name__)`

### General

- Use absolute imports
- One export per file when practical
- Keep functions focused and small (<50 lines)
- Write descriptive variable names

## Environment Variables

Copy `.env.example` to `.env`:

| Variable | Description |
|----------|-------------|
| `POSTGRES_*` | Database connection |
| `SECRET_KEY` | JWT signing key (generate with `openssl rand -hex 32`) |
| `CORS_ORIGINS` | Allowed frontend origins |
| `APP_ENV` | `development` or `production` |
| `VITE_API_URL` | Backend URL for frontend |
| `GITHUB_CLIENT_*` | OAuth (optional) |

## Testing

**Current state**: No test infrastructure set up yet.

**When adding tests**:
- Backend: pytest + httpx (async test client)
- Frontend: Vitest + React Testing Library
- Run before commit

## Git Workflow

- Branch from `main`
- Use descriptive commit messages
- PR required for `main`

## Deployment

### CI/CD (GitHub Actions)

`.github/workflows/deployment.yml`:
1. Build Docker images (frontend, backend)
2. Push to GHCR with `latest` + SHA tags
3. Deploy via `up.sh` on target server

### Manual Deployment

```bash
cd deployment/battle.wopee.io
./up.sh        # Pull, build, start
./down.sh      # Stop services
```

### Secrets Management

- **SOPS** encrypts `secrets.enc.env` using Age keys
- Decrypted at deploy time via `SOPS_AGE_KEY` secret
- NEVER commit plain-text secrets

## OpenSpec Workflow

For new features or breaking changes, use OpenSpec:

1. Read [openspec/AGENTS.md](openspec/AGENTS.md)
2. Create proposal: `openspec/changes/<change-id>/`
3. Validate: `openspec validate <change-id> --strict`
4. Get approval before implementing

**Skip OpenSpec for**: bug fixes, typos, dependency updates, config changes.

## Common Tasks

### Add a New API Endpoint

1. Define Pydantic schemas in `backend/app/schemas.py`
2. Add route in `backend/app/routes_*.py`
3. Register router in `backend/app/main.py`
4. Update `frontend/src/api/client.ts` with typed methods
5. Create React component to consume the endpoint

### Add a New React Component

1. Create file in `frontend/src/components/`
2. Use TypeScript with proper prop types
3. Import in `App.tsx` or parent component
4. Add route if needed in `App.tsx`

### Add Database Model

1. Define SQLModel class in `backend/app/models.py`
2. Add relationship if needed
3. Create corresponding Pydantic schemas
4. Restart backend (auto-creates tables in dev)

### Debug Backend

```bash
# Check logs
docker compose logs -f battle-backend

# Or run locally with debug logging
APP_ENV=development uvicorn app.main:app --reload --log-level debug
```

### Debug Frontend

- Use browser DevTools
- VS Code debugger attaches automatically with F5
- Check Vite terminal for build errors

## Key Files Reference

| File | Purpose |
|------|---------|
| [docker-compose.yml](docker-compose.yml) | Service orchestration |
| [backend/app/main.py](backend/app/main.py) | FastAPI app setup |
| [backend/app/config.py](backend/app/config.py) | Environment config |
| [backend/app/models.py](backend/app/models.py) | Database models |
| [frontend/src/api/client.ts](frontend/src/api/client.ts) | API client |
| [frontend/src/App.tsx](frontend/src/App.tsx) | React app root |
| [frontend/vite.config.ts](frontend/vite.config.ts) | Vite + proxy config |
| [.vscode/launch.json](.vscode/launch.json) | Debug configurations |

## Troubleshooting

### Database connection failed

```bash
docker compose up battle-db -d
docker compose logs battle-db  # Check for errors
```

### CORS errors

- Check `CORS_ORIGINS` in `.env` matches frontend URL
- Restart backend after changing

### JWT token expired

- Default: 30 minutes
- Adjust `ACCESS_TOKEN_EXPIRE_MINUTES` in `.env`

### Frontend can't reach backend

- Check Vite proxy config in `vite.config.ts`
- Verify backend is running on port 8002
- Check browser console for network errors

## Resources

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [SQLModel Docs](https://sqlmodel.tiangolo.com/)
- [React Docs](https://react.dev/)
- [Vite Docs](https://vitejs.dev/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)

---

**Last updated**: 2025-11-26
