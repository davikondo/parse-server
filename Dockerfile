# Build stage
FROM node:lts-alpine as build
ARG parserelease=3.6.0

RUN apk update; \
    apk add git; \
    git clone https://github.com/parse-community/parse-server.git -b ${parserelease} /tmp2
WORKDIR /tmp2
RUN npm ci
RUN npm run build

# Release stage
FROM node:lts-alpine as release
ARG parserelease=3.6.0
VOLUME /parse-server/cloud /parse-server/config

WORKDIR /parse-server

COPY --from=build --chown=node:node /tmp2/package*.json ./

RUN npm ci --production --ignore-scripts

COPY --from=build --chown=node:node /tmp2/bin bin
COPY --from=build --chown=node:node /tmp2/public_html public_html
COPY --from=build --chown=node:node /tmp2/views views
COPY --from=build --chown=node:node /tmp2/lib lib

RUN mkdir -p logs && chown -R node:node logs

ENV PORT=1337
EXPOSE $PORT

USER node

ENTRYPOINT ["node", "./bin/parse-server"]
