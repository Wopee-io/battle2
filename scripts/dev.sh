#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

mkdir -p logs

# Load environment
if [ -f .env ]; then
  set -a; source .env; set +a
fi

# Port defaults
DB_PORT="${DB_PORT:-54322}"
BACKEND_PORT="${BACKEND_PORT:-8002}"
VITE_PORT="${VITE_PORT:-3002}"

# Set DATABASE_URL for local development
export DATABASE_URL="postgresql://${POSTGRES_USER:-battle}:${POSTGRES_PASSWORD:-changeme}@localhost:${DB_PORT}/${POSTGRES_DB:-battle}"

echo "Starting Battle dev environment..."

# 1. Database
echo "[1/3] Starting PostgreSQL..."
docker-compose up battle-db -d
sleep 2

# 2. Backend
echo "[2/3] Starting backend on :${BACKEND_PORT}..."
cd backend
source .venv/bin/activate
nohup uvicorn app.main:app --reload --host 0.0.0.0 --port ${BACKEND_PORT} > "$PROJECT_ROOT/logs/backend.log" 2>&1 &
echo $! > "$PROJECT_ROOT/logs/backend.pid"
cd "$PROJECT_ROOT"

# 3. Frontend
echo "[3/3] Starting frontend on :${VITE_PORT}..."
cd frontend
nohup npm run dev > "$PROJECT_ROOT/logs/frontend.log" 2>&1 &
echo $! > "$PROJECT_ROOT/logs/frontend.pid"
cd "$PROJECT_ROOT"

sleep 2

echo ""
echo "Dev environment ready!"
echo "  Frontend: http://localhost:${VITE_PORT}"
echo "  Backend:  http://localhost:${BACKEND_PORT}"
echo "  API Docs: http://localhost:${BACKEND_PORT}/docs"
echo "  Database: localhost:${DB_PORT}"
echo ""
echo "Stop: ./scripts/dev-stop.sh"
