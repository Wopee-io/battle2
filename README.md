# Battle

A full-stack web application skeleton with React + TypeScript frontend and FastAPI + PostgreSQL backend.

## Stack

- **Frontend**: Vite + React + TypeScript + Tailwind CSS
- **Backend**: Python + FastAPI + SQLModel
- **Database**: PostgreSQL 16
- **Auth**: JWT-based authentication (OAuth2 password flow)

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Node.js 20+ (for frontend development)
- Python 3.12+ (for backend development)

### Option 1: Full Stack via Docker

```bash
# Copy environment template
cp .env.example .env

# Start all services
docker compose up -d

# Access the app
# Frontend: http://localhost:3002
# Backend API: http://localhost:8002
# API Docs: http://localhost:8002/docs
```

### Option 2: Local Development (VS Code)

The recommended way to run the full stack locally is via VS Code:

1. Open the project folder in VS Code
2. Press **F5** and select **"Full Stack Dev (DB in Docker + backend + frontend)"**
3. Wait for the browser to open at http://localhost:3002

This will:
- Start PostgreSQL in Docker
- Start the FastAPI backend with debug logging and hot reload
- Start the Vite frontend dev server
- Open Chrome with debugger attached

### Option 3: Manual Local Development

For AI agents or manual setup:

```bash
# 1. Start the database
docker compose up battle-db -d

# 2. Start the backend (in backend/ folder)
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002 --log-level debug

# 3. Start the frontend (in frontend/ folder, separate terminal)
cd frontend
npm run dev
```

**First-time setup:**
```bash
# Backend dependencies
cd backend
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt

# Frontend dependencies
cd frontend
npm install
```

**Access the app:**
- Frontend: http://localhost:3002
- Backend API: http://localhost:8002
- API Docs: http://localhost:8002/docs

### Viewing Logs

- **Backend logs**: Check the integrated terminal running "backend: dev" task, or the terminal where uvicorn is running
- **Database logs**: `docker compose logs -f battle-db`
- **Frontend logs**: Check the integrated terminal running "frontend: dev" task

In development mode (`APP_ENV=development`), backend logs include debug-level output with timestamps, log levels, and module names.

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health` | GET | No | Health check |
| `/auth/register` | POST | No | Create user |
| `/auth/token` | POST | No | Get JWT token |
| `/auth/me` | GET | Yes | Current user info |
| `/items` | GET | Yes | List user's items |
| `/items` | POST | Yes | Create item |
| `/items/{id}` | DELETE | Yes | Delete item |

## Project Structure

```
/
├── frontend/           # React + TypeScript frontend
│   ├── src/
│   │   ├── api/        # API client
│   │   └── components/ # React components
│   ├── Dockerfile
│   └── package.json
├── backend/            # FastAPI backend
│   ├── app/
│   │   ├── main.py     # FastAPI entry point
│   │   ├── auth_*.py   # Authentication
│   │   └── routes_*.py # API routes
│   ├── Dockerfile
│   └── requirements.txt
├── deployment/         # Production deployment configs
├── docker-compose.yml  # Development orchestration
└── .env.example        # Environment template
```

## Environment Variables

Copy `.env.example` to `.env` and adjust as needed:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY` | JWT signing key (use `openssl rand -hex 32`) |
| `CORS_ORIGINS` | Allowed frontend origins |
| `APP_ENV` | Environment: `development` or `production` (affects log level) |
| `GITHUB_CLIENT_ID` | GitHub OAuth app client ID (optional) |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth app secret (optional) |

## GitHub OAuth (Placeholder)

The `/auth/github/*` endpoints are placeholders for future GitHub OAuth integration. To enable:

1. Create a GitHub OAuth App at https://github.com/settings/developers
2. Set callback URL to `https://your-domain/auth/github/callback`
3. Add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to `.env`
4. Implement the token exchange in `backend/app/github_oauth.py`

## Production Deployment

The app is configured to deploy to `app.battle.wopee.io` via Traefik. The GitHub Actions workflow builds and pushes images to GHCR on each deployment.

```bash
# Trigger deployment via GitHub Actions
# Or manually:
docker compose -f docker-compose.yml up -d
```
