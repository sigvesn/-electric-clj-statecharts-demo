FROM clojure:openjdk-11-tools-deps AS clojure-deps
WORKDIR /app
COPY deps.edn deps.edn
COPY src-build src-build
RUN clojure -A:dev -M -e :ok        # preload deps
RUN clojure -T:build noop           # preload build deps

FROM node:14.7-stretch AS node-deps
WORKDIR /app
COPY package.json package.json
RUN npm install

FROM clojure:openjdk-11-tools-deps AS build
WORKDIR /app
COPY --from=node-deps /app/node_modules /app/node_modules
COPY --from=clojure-deps /root/.m2 /root/.m2
COPY shadow-cljs.edn shadow-cljs.edn
COPY deps.edn deps.edn
COPY src src
COPY src-build src-build
COPY resources resources
ARG REBUILD=unknown
ARG VERSION
RUN clojure -T:build build-client :verbose true :version '"'$VERSION'"'

ENV VERSION=$VERSION
CMD clj -J-DHYPERFIDDLE_ELECTRIC_VERSION=$VERSION -M -m prod
