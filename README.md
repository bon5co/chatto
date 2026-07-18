# chatto (Railway image)

Railway-tuned wrapper around [`ghcr.io/chattocorp/chatto`](https://github.com/chattocorp/chatto)
(self-hostable team chat, AGPL-3.0). Published as `ghcr.io/bon5co/chatto:latest` and used by the
Railway one-click template.

What the wrapper entrypoint adds on top of the stock image:

- **Env-only config defaults baked in** — upstream's documented toml defaults do not apply when
  no `chatto.toml` exists, so `CHATTO_WEBSERVER_PORT`, `CHATTO_NATS_EMBEDDED_ENABLED=true`,
  `CHATTO_NATS_EMBEDDED_DATA_DIR=/data`, logging, and the operator API are defaulted here.
- **Honors Railway's injected `PORT`** and derives `CHATTO_WEBSERVER_URL` from
  `RAILWAY_PUBLIC_DOMAIN`.
- **Fixes volume ownership** — Railway mounts volumes root-owned; the stock entrypoint doesn't
  chown mounts and Chatto runs as uid 1000.
- **Auto-generates the four required 64-hex secrets** on first boot and persists them at
  `/data/.chatto-secrets.env` so they survive redeploys. Set any of the secret env vars
  explicitly to override.

Voice/video calls are disabled by default (`CHATTO_LIVEKIT_ENABLED=false`) because Railway's
proxy has no public UDP for WebRTC media; point the `CHATTO_LIVEKIT_*` vars at a LiveKit
server to enable them.

Every default is override-by-env. Not affiliated with chattocorp; licensing unchanged (AGPL-3.0).
