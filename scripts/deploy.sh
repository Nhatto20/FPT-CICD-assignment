#!/bin/bash
set -e

# ── Config (matches project Dockerfile + docker-compose) ─────────────────────
IMAGE=$1                                      # passed in from deploy.yml / CI
CONTAINER_NAME="myapp_prod"
PORT="8000"
HEALTH_URL="http://localhost:${PORT}/health"  # matches app.py GET /health
DATA_VOLUME="app_data"                        # named volume from docker-compose
MAX_RETRIES=10
RETRY_INTERVAL=3

# ── Validate args ─────────────────────────────────────────────────────────────
if [[ -z "$IMAGE" ]]; then
  echo "Usage: deploy.sh <image>"
  echo "  e.g. deploy.sh ghcr.io/myorg/myapp:abc1234"
  exit 1
fi

# ── Pull new image ────────────────────────────────────────────────────────────
echo "▶ Main: Pulling image: $IMAGE"
docker pull "$IMAGE"

# ── Stop and replace running container ───────────────────────────────────────
echo "▶ Stopping existing container (if any)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm   "$CONTAINER_NAME" 2>/dev/null || true

echo "▶ Starting new container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${PORT}:${PORT}" \
  -e ENV=production \
  -e PORT="${PORT}" \
  -v "${DATA_VOLUME}:/app/data" \
  "$IMAGE"

# ── Health check ──────────────────────────────────────────────────────────────
echo "▶ Waiting for app to be healthy..."
for i in $(seq 1 $MAX_RETRIES); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || true)

  if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "✅ Deployment successful — app is healthy (attempt $i)"
    echo "   Image:     $IMAGE"
    echo "   Container: $CONTAINER_NAME"
    echo "   Health:    $HEALTH_URL"
    exit 0
  fi

  echo "   Attempt $i/$MAX_RETRIES — got HTTP $HTTP_STATUS, retrying in ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

# ── Health check failed — rollback ────────────────────────────────────────────
echo "❌ Deployment failed — app did not become healthy after $MAX_RETRIES attempts"
echo "   Container logs:"
docker logs "$CONTAINER_NAME" --tail 20
echo "   Stopping failed container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
exit 1