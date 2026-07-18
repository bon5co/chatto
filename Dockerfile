FROM ghcr.io/chattocorp/chatto:latest
# Railway wrapper: bakes env-only config defaults, honors Railway's injected
# PORT, chowns the root-owned /data volume mount, and auto-generates the
# required 64-hex secrets onto the volume (persisted across redeploys).
# Published as ghcr.io/bon5co/chatto for the Railway template.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
ENTRYPOINT ["railway-entrypoint.sh"]
EXPOSE 4000
