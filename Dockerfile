FROM ghcr.io/blinklabs-io/haskell:9.12.3-3.14.2.0-1 AS ogmios-build
# Install ogmios
ARG OGMIOS_VERSION=v6.14.0.2
ENV OGMIOS_VERSION=${OGMIOS_VERSION}
RUN echo "Building tags/${OGMIOS_VERSION}..." \
    && echo tags/${OGMIOS_VERSION} > /OGMIOS_BRANCH \
    && git clone https://github.com/IntersectMBO/ogmios.git \
    && cd ogmios \
    && git fetch --all --recurse-submodules --tags \
    && git checkout tags/${OGMIOS_VERSION} \
    && git submodule update --init --recursive \
    && cd server \
    && echo "with-compiler: ghc-${GHC_VERSION}" >> cabal.project.local \
    && cabal update \
    && cabal build exe:ogmios \
    && mkdir -p /root/.local/bin/ \
    && cp -p "$(cabal list-bin exe:ogmios)" /root/.local/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ /usr/local/share/doc/ghc-${GHC_VERSION}/ \
    && rm -rf /code/ogmios/server/dist-newstyle/ \
    && rm -rf /root/.cabal/store/ghc-${GHC_VERSION}

FROM ghcr.io/blinklabs-io/cardano-configs:20260623-1 AS cardano-configs

FROM debian:bookworm-slim AS ogmios
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
COPY --from=ogmios-build /usr/local/lib/ /usr/local/lib/
COPY --from=ogmios-build /usr/local/include/ /usr/local/include/
COPY --from=ogmios-build /root/.local/bin/ogmios /usr/local/bin/
COPY --from=cardano-configs /config/ /opt/cardano/config/
COPY bin/ /usr/local/bin/
RUN apt-get update -y && \
  apt-get install -y \
    ca-certificates \
    curl \
    libffi8 \
    libgmp10 \
    liblmdb0 \
    libncursesw5 \
    libnuma1 \
    libsnappy1v5 \
    libssl3 \
    libsystemd0 \
    libtinfo6 \
    liburing2 \
    llvm-14-runtime \
    pkg-config \
    zlib1g && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /usr/local/bin/*
EXPOSE 1337
HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD /usr/local/bin/ogmios health-check --port "${OGMIOS_PORT:-1337}"
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/entrypoint"]
