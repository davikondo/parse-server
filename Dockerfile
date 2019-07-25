# Build stage
FROM node:lts-alpine as build
ARG parserelease=3.6.0

RUN apk update; \
    apk add git; \
    git clone https://github.com/parse-community/parse-server.git -b ${parserelease} /tmp
WORKDIR /tmp
#COPY package*.json ./
RUN npm ci
#COPY . .
RUN npm run build

# Release stage
FROM node:lts-alpine as release
ARG parserelease=3.6.0
VOLUME /parse-server/cloud /parse-server/config

WORKDIR /parse-server

COPY --from=build /tmp/package*.json ./

RUN npm ci --production --ignore-scripts

COPY --from=build /tmp/bin bin
COPY --from=build /tmp/public_html public_html
COPY --from=build /tmp/views views
COPY --from=build /tmp/lib lib

RUN mkdir -p logs && chown -R node: logs

ENV PORT=1337
USER node
EXPOSE $PORT

ENTRYPOINT ["node", "./bin/parse-server"]
