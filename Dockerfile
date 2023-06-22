# syntax=docker/dockerfile:1
ARG VOLTO_VERSION
FROM eway/frontend-builder:${VOLTO_VERSION} as builder

# Build Volto Project and then remove directories not needed for production
RUN <<EOT
    set -e 
    yarn build
    rm -rf cache omelette .yarn/cache
EOT

FROM eway/frontend-prod-config:${VOLTO_VERSION} as base

LABEL maintainer="Plone Community <dev@plone.org>" \
      org.label-schema.name="plone-frontend" \
      org.label-schema.description="Plone frontend image" \
      org.label-schema.vendor="Plone Foundation"

# Copy Volto project
COPY --from=builder /app/ /app/
