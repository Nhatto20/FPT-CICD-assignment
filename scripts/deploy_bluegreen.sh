#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Blue-Green Deployment Script
#
# Usage:
#   deploy_bluegreen.sh <image> <active_slot>
#
# Arguments:
#   image        — Full image reference, e.g. ghcr.io/org/myapp:sha
#   active_slot  — Currently LIVE slot: "blue" or "green"
#                  The script will deploy to the OTHER (inactive) slot.
#
# Ports:
#   Blue  → 8000
#   Green → 8001
#
# Exit codes:
#   0 — Deployment successful, traffic switched to new slot
#   1 — Deployment failed, old slot kept alive (rollback)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
IMAGE="${1:-}"
ACTIVE_SLOT="${2:-}"

if [[ -z "$IMAGE" || -z "$ACTIVE_SLOT" ]]; then
  echo "Usage: deploy_bluegreen.sh <image> <active_slot>"
  echo "  active_slot: blue | green"
  exit 1
fi

if [[ "$ACTIVE_SLOT" != "blue" && "$ACTIVE_SLOT" != "green" ]]; then
  echo "❌ active_slot must be 'blue' or 'green', got: '$ACTIVE_SLOT'"
  exit 1
fi

# ── Slot config ───────────────────────────────────────────────────────────────
BLUE_CONTAINER="myapp_blue"
GREEN_CONTAINER="myapp_green"
BLUE_PORT="8000"
GREEN_PORT="8001"

if [[ "$ACTIVE_SLOT" == "blue" ]]; then
  NEW_SLOT="green"
  NEW_CONTAINER="$GREEN_CONTAINER"
  NEW_PORT="$GREEN_PORT"
  OLD_CONTAINER="$BLUE_CONTAINER"
  OLD_PORT="$BLUE_PORT"
else
  NEW_SLOT="blue"
  NEW_CONTAINER="$BLUE_CONTAINER"
  NEW_PORT="$BLUE_PORT"
  OLD_CONTAINER="$GREEN_CONTAINER"
  OLD_PORT="$GREEN_PORT"
fi

HEALTH_URL="http://host.docker.internal:${NEW_PORT}/health"
MAX_RETRIES=15
RETRY_INTERVAL=3

echo "════════════════════════════════════════════"
echo "  Blue-Green Deployment"
echo "  Image:       $IMAGE"
echo "  Active slot: $ACTIVE_SLOT  (port $OLD_PORT)"
echo "  New slot:    $NEW_SLOT     (port $NEW_PORT)"
echo "════════════════════════════════════════════"

# ── Pull new image ────────────────────────────────────────────────────────────
echo ""
echo "▶ [1/4] Pulling image..."
docker pull "$IMAGE"

# ── Clean up inactive slot in case a previous deploy left debris ──────────────
echo ""
echo "▶ [2/4] Clearing inactive slot ($NEW_SLOT)..."
docker stop "$NEW_CONTAINER" 2>/dev/null || true
docker rm   "$NEW_CONTAINER" 2>/dev/null || true

# ── Start new container on inactive slot ──────────────────────────────────────
echo ""
echo "▶ [3/4] Starting $NEW_SLOT container on port $NEW_PORT..."

# Safety net: release the port if anything else is still holding it
PORT_HOLDER=$(docker ps --filter "publish=${NEW_PORT}" --format "{{.Names}}" | head -n1)
if [[ -n "$PORT_HOLDER" ]]; then
  echo "   ⚠️  Port ${NEW_PORT} is held by container '$PORT_HOLDER' — stopping it first..."
  docker stop "$PORT_HOLDER" 2>/dev/null || true
  docker rm   "$PORT_HOLDER" 2>/dev/null || true
fi

docker run -d \
  --name "$NEW_CONTAINER" \
  --label "slot=$NEW_SLOT" \
  --restart unless-stopped \
  -p "${NEW_PORT}:8000" \
  -e ENV=production \
  -e PORT=8000 \
  "$IMAGE"

# ── Health check (poll /health until 200 or timeout) ─────────────────────────
echo ""
echo "▶ [4/4] Health-checking $NEW_SLOT slot (${HEALTH_URL})..."
HEALTHY=false

for i in $(seq 1 $MAX_RETRIES); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")

  if [[ "$HTTP_STATUS" == "200" ]]; then
    HEALTHY=true
    echo "   ✅ Healthy after attempt $i (HTTP 200)"
    break
  fi

  echo "   Attempt $i/$MAX_RETRIES — HTTP $HTTP_STATUS, retrying in ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

# ── Rollback on health check failure ─────────────────────────────────────────
if [[ "$HEALTHY" != "true" ]]; then
  echo ""
  echo "❌ Deployment FAILED — $NEW_SLOT slot did not become healthy"
  echo "   Last 20 log lines from $NEW_CONTAINER:"
  docker logs "$NEW_CONTAINER" --tail 20 2>/dev/null || true
  echo ""
  echo "🔄 Rolling back — stopping $NEW_SLOT container, keeping $ACTIVE_SLOT alive"
  docker stop "$NEW_CONTAINER" 2>/dev/null || true
  docker rm   "$NEW_CONTAINER" 2>/dev/null || true
  echo "   $ACTIVE_SLOT slot (port $OLD_PORT) is still serving traffic."
  exit 1
fi

# ── Switch traffic: stop old slot ────────────────────────────────────────────
echo ""
echo "🔀 Switching traffic: stopping $ACTIVE_SLOT slot (port $OLD_PORT)..."
docker stop "$OLD_CONTAINER" 2>/dev/null || true
docker rm   "$OLD_CONTAINER" 2>/dev/null || true

echo ""
echo "✅ Deployment SUCCESSFUL"
echo "   New active slot: $NEW_SLOT"
echo "   Container:       $NEW_CONTAINER"
echo "   Port:            $NEW_PORT"
echo "   Image:           $IMAGE"