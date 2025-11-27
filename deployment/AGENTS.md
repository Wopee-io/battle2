# AGENTS — Deployment Rules

## Project: Studio Deployment
Stack: Docker Compose + Bash + Traefik + Authentik + PostgreSQL.

## Architecture Overview
The deployment uses a **Split-Domain ForwardAuth** architecture:
- **App Domain (`studio.wopee.io`)**: Hosts the main application and user workspaces. Protected by ForwardAuth.
- **Auth Domain (`auth.studio.wopee.io`)**: Hosts the Identity Provider (Authentik). **NOT** protected by ForwardAuth to avoid redirect loops.

## ⚠️ Critical: Local Development Setup

> [!WARNING]
> **Local Docker context is bound to remote host**
>
> When working in this deployment directory, Docker commands interact with the **remote server** (`studio.wopee.io`), not your local machine.
> **Local file changes do NOT automatically apply to the remote server.**

**Key Points**:
- ✅ `docker compose up/down/restart` - Controls **remote** containers
- ✅ `docker logs` - Shows **remote** container logs
- ❌ Local file edits - Do NOT automatically sync to remote
- ✅ Changes require: Edit → Commit → Push → Remote Pull → Restart

**Workflow for Configuration Changes**:
```bash
# 1. Edit files locally
vim docker-compose.yml

# 2. Commit and push
git commit -am "Update configuration"
git push

# 3. Deploy to remote (depends on your setup):
# Option A: SSH and pull
ssh ubuntu@studio.wopee.io "cd ~/actions-runner_e4/_work/studio/studio && git pull && docker compose restart"

# Option B: use gh CI/CD pipeline to automate deployment
```

**Verify your Docker context**:
```bash
docker context ls  # Check which context is active
docker info | grep "Server Version"  # Verify remote vs local
```

See [TESTING.md](studio.wopee.io/TESTING.md#critical-local-development-setup) for detailed debugging steps.

## Components

### Core Services
- **`traefik`** (External): The reverse proxy handling ingress. Services attach via `traefik.*` labels.
- **`postgresql`**: Database backend for Authentik (Postgres 18).
- **`authentik-server`**: The core Identity Provider service. Handles auth flows and API.
- **`authentik-worker`**: Background worker for Authentik (tasks, blueprint application).
- **`authentik-bootstrap`**: Ephemeral container that configures Authentik on startup:
  - Sets tenant domain (`auth.studio.wopee.io`)
  - Configures embedded outpost `authentik_host` URLs
  - Runs once with `restart: "no"`
  - Requires database credentials from `secrets.enc.env`
  - Must be on the same network as `authentik-db` (proxy network)

### Application Services
- **`spawner`**: Custom Node.js/Docker service that manages user workspaces.
    - Listens on `studio.wopee.io`.
    - Spawns per-user VS Code Server containers (`ovsc-<user>`).
    - Validates authentication headers from ForwardAuth.

## Configuration

### Environment Variables

The deployment uses a **three-layer configuration system**:

1. **`.env`**: Non-secret configuration (domains, paths, public settings)
   - Safe to commit to git
   - Contains references to where secrets come from (comments)
   - Examples: `AUTHENTIK_DOMAIN`, `APP_DOMAIN`, `COOKIE_DOMAIN`, `GITHUB_CLIENT_ID`

2. **`secrets.enc.env`**: Encrypted secrets using SOPS (Secrets OPerationS)
   - Encrypted at rest using AGE encryption
   - Requires `SOPS_AGE_KEY` environment variable to decrypt
   - Contains sensitive values: passwords, tokens, API keys
   - Examples: `GITHUB_CLIENT_SECRET`, `AUTHENTIK_SECRET_KEY`, `AUTHENTIK_POSTGRESQL__PASSWORD`

3. **`versions.env`**: Docker image tags/versions
   - Specifies exact versions to deploy
   - Examples: `AUTHENTIK_TAG=2025.10.2`

### Secret Management Workflow (SOPS)

**How it works**:
```bash
# 1. GitHub workflow provides decryption key
SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}

# 2. up.sh sources the secret loader
. ./utils/load-secrets-enc-env.sh

# 3. load-secrets-enc-env.sh decrypts and exports
eval "$(bash ./utils/shdotenv --env <(sops -d $SECRETS_ENC_FILE))"

# 4. Variables are now available to docker-compose
docker compose up -d
```

**Key Points**:
- ⚠️ **NEVER add plain-text secrets to `.env`** - they belong in `secrets.enc.env` (encrypted)
- ⚠️ **NEVER commit unencrypted secrets to git**
- ✅ The `secrets.enc.env` file is safe to commit (it's encrypted)
- ✅ Decryption happens at deployment time via `sops -d`
- ✅ `SOPS_AGE_KEY` is stored in GitHub Secrets and injected by the workflow

**To add/update a secret**:
```bash
# Install sops if needed
brew install sops age

# Edit encrypted file (will decrypt, open editor, re-encrypt on save)
sops secrets.enc.env

# Or set specific value
sops --set '["NEW_SECRET"] "new_value"' secrets.enc.env
```

**Local development**:
- For local testing, use `debug.env` with dummy/test values
- `debug.env` should NOT be committed (add to `.gitignore`)
- Production secrets stay encrypted in `secrets.enc.env`

### Authentik Blueprints
Located in `blueprints/`. Define the "Infrastructure as Code" for Authentik:
- Flows (Login, Enrollment).
- Policies (Access control).
- Property Mappings (OIDC/SAML claims).
- **Important**: Changes to auth logic should often be done here, not just in the UI.

## Deployment Workflow

### Start (`up.sh`)
1. **Load Environment**: Sources `.env`, decrypts `secrets.enc.env`, loads `versions.env`.
2. **Prepare Directories**: Ensures data directories exist.
3. **Pull Images**: Updates service images.
4. **Build**: Optionally rebuilds `spawner` if needed.
5. **Compose Up**: Runs `docker compose up -d`.

### Stop (`down.sh`)
1. Stops the Docker Compose stack.
2. Does **not** remove data volumes by default.

## Network & Routing
- **Network**: All services join the `proxy` external network to communicate with Traefik.
- **Routing**:
    - `auth.studio.wopee.io` -> `authentik-server:9000` (Priority 1200).
    - `studio.wopee.io` -> `spawner:8080` (Priority 10).
    - `studio.wopee.io/<user>` -> `ovsc-<user>:3002` (Priority 200, handled dynamically by Traefik/Spawner).

## Troubleshooting Principles

### Bootstrap Script Issues

The `authentik-bootstrap` service may fail if environment variables are missing:

**Symptoms**:
- Docker Compose warnings: `The "AUTHENTIK_SECRET_KEY" variable is not set`
- Bootstrap container fails to connect to database
- Outpost configuration shows empty `authentik_host` values

**Root Cause**: Secrets not loaded from `secrets.enc.env`

**Solution**:
```bash
# For GitHub workflow deployment - secrets are auto-loaded from:
# 1. SOPS_AGE_KEY in GitHub secrets
# 2. up.sh -> load-secrets-enc-env.sh -> sops -d secrets.enc.env

# For manual/local testing - run bootstrap directly with environment:
export SOPS_AGE_KEY="<your-age-key>"
eval "$(bash ./utils/shdotenv --env <(sops -d ./deployment/studio.wopee.io/secrets.enc.env))"
docker run --rm --network proxy \
  -e AUTHENTIK_SECRET_KEY \
  -e AUTHENTIK_POSTGRESQL__HOST=authentik-db \
  -e AUTHENTIK_POSTGRESQL__USER \
  -e AUTHENTIK_POSTGRESQL__NAME \
  -e AUTHENTIK_POSTGRESQL__PASSWORD \
  -e AUTHENTIK_DOMAIN \
  studiowopeeio-authentik-bootstrap
```

**Verification**:
```bash
# Check if outpost was configured correctly
docker exec authentik-db psql -U authentik -d authentik -c \
  "SELECT _config::json->>'authentik_host' FROM authentik_outposts_outpost WHERE name = 'authentik Embedded Outpost';"

# Should return: https://auth.studio.wopee.io/
```

### ForwardAuth Issues

- **Never protect `auth.studio.wopee.io` with ForwardAuth** — loops guarantee if the auth domain uses the middleware.
- **Cross-site cookies must be `SameSite=None; Secure`** for both session and proxy cookies:
  - Set `AUTHENTIK_SESSION_COOKIE_SAMESITE=none`, `AUTHENTIK_PROXY_COOKIE_SAMESITE=none`.
  - Set outpost cookies: `AUTHENTIK_OUTPOSTS__PROXY__COOKIE__SECURE=true`, `AUTHENTIK_OUTPOSTS__PROXY__COOKIE__SAMESITE=none`.
  - Keep `AUTHENTIK_COOKIE_DOMAIN=.studio.wopee.io`.
- **ForwardAuth debugging**: call the outpost directly and expect `X-authentik-*` headers when authenticated; 302 to `/if/flow/...` when not.
  - Use internal call to avoid Traefik noise:
    ```
    docker exec authentik-server curl -i \
      -H 'Host: studio.wopee.io' \
      -H 'X-Forwarded-Host: studio.wopee.io' \
      -H 'X-Forwarded-Proto: https' \
      -H 'X-Forwarded-Uri: /' \
      -H 'Cookie: authentik_session=<...>; authentik_proxy_<...>=<...>' \
      http://authentik-server:9000/outpost.goauthentik.io/auth/traefik
    ```
    - 200 + `X-authentik-username` → good.
    - 302 to `/authorize` or `/if/flow` → cookie not accepted; re-check SameSite/secure/domain.
- **Traefik labels must match**:
  - Router `studio` on `studio.wopee.io`, middleware `authentik-auth` (ForwardAuth address `http://authentik-server:9000/outpost.goauthentik.io/auth/traefik`), service `spawner-svc:8080`.
  - Auth router `auth-host` on `auth.studio.wopee.io` with **no** middleware.
- **Restart pattern** (keep DB): recreate only app/auth containers, don’t drop Postgres:
  ```
  docker-compose up -d --force-recreate --no-deps authentik-server authentik-worker spawner
  ```
  If name conflicts appear, stop/remove the old containers first (`docker rm authentik-server authentik-worker spawner`), leaving `authentik-db` running.
- **Conflicts / stale containers**: name-in-use errors mean old containers still exist; remove them or use `--no-deps` to avoid touching the DB.
- **When redirect loops happen**: check cookies (domain, SameSite, Secure), then run the ForwardAuth curl above. If curl returns 302, fix cookies; if 200 without headers, Traefik isn’t forwarding headers (`authResponseHeaders` label).

## Cross-Check Against Definitive ForwardAuth Patterns

- **GitHub OAuth**: Callback must be `https://auth.studio.wopee.io/source/oauth/callback/github/`; envs `GITHUB_CLIENT_ID/SECRET` set on server and worker.
- **Blueprint essentials**: GitHub source, forward_auth proxy provider (mode `forward_single`, external_host `https://studio.wopee.io`, cookie_domain `.studio.wopee.io`), application bound to provider, embedded outpost bound to the provider, identification stage includes GitHub source.
- **Traefik ForwardAuth middleware**: `trustForwardHeader=true` and `authResponseHeaders` includes at least `X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid`.
- **Cookie hygiene**: same-site/secure settings above plus leading-dot cookie domain; no ForwardAuth on the auth domain.
- **Version alignment**: Authentik image pinned (2025.10 here), Traefik v3; avoid `:latest`.

## Reference
- See `studio.wopee.io/TESTING.md` for detailed manual verification steps.
