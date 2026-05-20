# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=24
ARG PNPM_VERSION=10.33.0

FROM node:${NODE_VERSION}-bookworm-slim AS build

ARG PNPM_VERSION
ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}
ENV CI=true
ENV NODE_OPTIONS=--max-old-space-size=8192

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

COPY . .

RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM nginx:1.27-alpine AS runtime

ENV COMFYUI_BACKEND=http://172.24.18.52:8188

COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
