FROM caddy:2.6.4-builder AS builder

RUN xcaddy build \
    --with github.com/pteich/caddy-tlsconsul \
    --with github.com/hundertzehn/caddy-ratelimit

FROM caddy:2.6.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

EXPOSE 80
EXPOSE 443
EXPOSE 2019


CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
