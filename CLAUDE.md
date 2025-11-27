# Battle — Project Context

Full-stack web app: React + TypeScript frontend, FastAPI + Python backend, PostgreSQL.

## Development

### Start Dev Environment
```bash
./scripts/dev.sh      # Start DB + backend + frontend (all in background)
./scripts/dev-stop.sh # Stop everything
```

**VS Code**: Press F5 → "Full Stack Dev" (uses same scripts)

### URLs (when running)
| Service | URL |
|---------|-----|
| Frontend | http://localhost:3002 |
| Backend API | http://localhost:8002 |
| API Docs (Swagger) | http://localhost:8002/docs |

### Test Backend with curl
```bash
# Health check
curl http://localhost:8002/health

# Register user
curl -X POST http://localhost:8002/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser","password":"testpass123"}'

# Login (get JWT token)
curl -X POST http://localhost:8002/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=testpass123"

# Authenticated request (replace <token>)
curl http://localhost:8002/auth/me -H "Authorization: Bearer <token>"
```

### Test Frontend with Chrome MCP
```
# 1. Open frontend
mcp__chrome-devtools__navigate_page url="http://localhost:3002"

# 2. Inspect page structure
mcp__chrome-devtools__take_snapshot

# 3. Interact with elements (use uid from snapshot)
mcp__chrome-devtools__click uid="<element-uid>"
mcp__chrome-devtools__fill uid="<input-uid>" value="test value"

# 4. Take screenshot to verify visual state
mcp__chrome-devtools__take_screenshot
```

### View Logs
```bash
tail -f logs/backend.log   # Backend (uvicorn)
tail -f logs/frontend.log  # Frontend (Vite)
```

### Auto-Reload
- Backend: Auto-reloads on Python file changes (uvicorn --reload)
- Frontend: Auto-reloads on source changes (Vite HMR)
- No restart needed for most code changes

## Key Locations

| Purpose | Path |
|---------|------|
| Backend entry | `backend/app/main.py` |
| API routes | `backend/app/routes_*.py`, `backend/app/auth_routes.py` |
| Database models | `backend/app/models.py` |
| Frontend entry | `frontend/src/App.tsx` |
| API client | `frontend/src/api/client.ts` |
| Environment config | `.env` (copy from `.env.example`) |

## Code Style

- **Python**: Type hints required, SQLModel ORM, Pydantic schemas
- **TypeScript**: Strict mode, path alias `@/` → `src/`
- **General**: Small focused functions, descriptive names, no over-engineering

## Before Coding

1. Read `AGENTS.md` for full project context
2. Check existing code patterns before adding new ones
3. For new features/breaking changes: use OpenSpec workflow (see `openspec/AGENTS.md`)
