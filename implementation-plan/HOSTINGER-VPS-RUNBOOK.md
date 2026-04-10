# Hostinger VPS Runbook — Execute SignalForge Automation on Your Paperclip

This runbook shows the safest way to run automation for a Paperclip instance hosted on a Hostinger VPS.

## Recommended approach (run script directly on VPS)

Running on the VPS avoids public auth/network complexity.

## 1) SSH into VPS

```bash
ssh <your-user>@<your-vps-ip>
```

## 2) Go to your Paperclip repo

```bash
cd /path/to/your/paperclip/repo
```

## 3) Confirm Paperclip API is reachable on VPS

```bash
curl http://127.0.0.1:3100/api/health
```

If this fails, start Paperclip first (example):

```bash
pnpm dev
```

### If your Paperclip runs in Docker

Check container and mapped port first:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

If port `3100` is mapped to host, health check from host:

```bash
curl http://127.0.0.1:3100/api/health
```

If using compose quickstart in this repo:

```bash
docker compose -f docker/docker-compose.quickstart.yml ps
```

Default service name is `paperclip`.  
If your host port is different, replace `3100` accordingly in `PAPERCLIP_BASE_URL`.

## 4) Run full automation locally on VPS

```bash
PAPERCLIP_BASE_URL="http://127.0.0.1:3100/api" \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

That provisions company, goals, agents, projects, and starter issues.

## 5) Verify from API

```bash
curl http://127.0.0.1:3100/api/companies
```

---

## Alternative: run from your laptop against VPS domain

Only do this if your API is intentionally exposed.

### Option A — Bearer token auth

```bash
PAPERCLIP_BASE_URL="https://your-domain.tld/api" \
PAPERCLIP_TOKEN="<bearer-token>" \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

### Option B — Session cookie auth

If your deployment uses session auth and no bearer token is available:

```bash
PAPERCLIP_BASE_URL="https://your-domain.tld/api" \
PAPERCLIP_COOKIE="<cookie_name>=<cookie_value>" \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

### Option C — Self-signed TLS certificate

```bash
PAPERCLIP_BASE_URL="https://your-domain.tld/api" \
PAPERCLIP_SKIP_TLS_VERIFY=true \
PAPERCLIP_TOKEN="<bearer-token>" \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

---

## Dry run before writes (recommended)

```bash
PAPERCLIP_BASE_URL="http://127.0.0.1:3100/api" \
PAPERCLIP_DRY_RUN=true \
./implementation-plan/scripts/bootstrap-signalforge.sh
```

## Troubleshooting

- `Preflight failed`: check `PAPERCLIP_BASE_URL` and whether Paperclip is running.
- Docker setup: confirm the container port mapping and use the host-mapped port in `PAPERCLIP_BASE_URL`.
- `403/401`: use board-level auth (`PAPERCLIP_TOKEN` or `PAPERCLIP_COOKIE`).
- adapter errors later: creation succeeded but runtime adapter credentials/config still need setup.
