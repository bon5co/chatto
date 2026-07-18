#!/bin/sh
# Railway-tuned bootstrap for Chatto. Env-only config zero-values the struct
# (documented toml defaults do not apply), so bake sane defaults here; every
# value can still be overridden by setting the variable on the service.
set -eu

# Honor Railway's injected PORT (edge proxy + healthcheck both probe it).
export CHATTO_WEBSERVER_PORT="${CHATTO_WEBSERVER_PORT:-${PORT:-4000}}"
if [ -z "${CHATTO_WEBSERVER_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    export CHATTO_WEBSERVER_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
export CHATTO_NATS_EMBEDDED_ENABLED="${CHATTO_NATS_EMBEDDED_ENABLED:-true}"
export CHATTO_NATS_EMBEDDED_DATA_DIR="${CHATTO_NATS_EMBEDDED_DATA_DIR:-/data}"
export CHATTO_LIVEKIT_ENABLED="${CHATTO_LIVEKIT_ENABLED:-false}"
export CHATTO_LOG_LEVEL="${CHATTO_LOG_LEVEL:-info}"
export CHATTO_LOG_FORMAT="${CHATTO_LOG_FORMAT:-json}"
export CHATTO_OPERATOR_API_ENABLED="${CHATTO_OPERATOR_API_ENABLED:-true}"

# Railway mounts volumes root-owned; the stock entrypoint does not chown mounts.
chown -R 1000:1000 /data 2>/dev/null || true

# Auto-generate the required 64-hex secrets once and persist them on the volume
# so they survive redeploys (changing CHATTO_CORE_SECRET_KEY invalidates all
# sessions/tokens). Explicitly-set env vars always win over the stored values.
SECRETS_FILE="/data/.chatto-secrets.env"
if [ ! -f "$SECRETS_FILE" ]; then
    rand_hex() { head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
    umask 077
    {
        echo "CHATTO_WEBSERVER_COOKIE_SIGNING_SECRET=$(rand_hex)"
        echo "CHATTO_WEBSERVER_COOKIE_ENCRYPTION_SECRET=$(rand_hex)"
        echo "CHATTO_CORE_SECRET_KEY=$(rand_hex)"
        echo "CHATTO_CORE_ASSETS_SIGNING_SECRET=$(rand_hex)"
    } > "$SECRETS_FILE"
    chown 1000:1000 "$SECRETS_FILE"
fi
while IFS='=' read -r key value; do
    [ -z "$key" ] && continue
    eval "current=\${$key:-}"
    if [ -z "$current" ]; then
        export "$key=$value"
    fi
done < "$SECRETS_FILE"

exec docker-entrypoint.sh start -c /config/chatto.toml
