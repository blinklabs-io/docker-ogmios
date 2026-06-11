# docker-ogmios

Builds [Ogmios](https://github.com/IntersectMBO/ogmios) from source on
Debian. This follows the same general pattern as
[docker-cardano-node](https://github.com/blinklabs-io/docker-cardano-node):
a Blink Haskell build image compiles the upstream release, then a slim runtime
image carries the executable and shared runtime libraries.

The default build currently targets upstream tag `v6.14.0.2`.

## Building

```bash
docker build -t ghcr.io/blinklabs-io/ogmios .
```

To build a different upstream tag:

```bash
docker build \
  --build-arg OGMIOS_VERSION=v6.14.0.2 \
  -t ghcr.io/blinklabs-io/ogmios:v6.14.0.2 .
```

## Running

Ogmios needs access to a running `cardano-node` socket. The image includes
the Blink `cardano-configs` files under `/opt/cardano/config`.

```bash
docker run --rm \
  --name ogmios \
  -e NETWORK=preprod \
  -v node-ipc:/ipc \
  -p 1337:1337 \
  ghcr.io/blinklabs-io/ogmios
```

The entrypoint defaults to:

- `NETWORK=mainnet`
- `CARDANO_CONFIG=/opt/cardano/config/${NETWORK}/config.json`
- `CARDANO_SOCKET_PATH=/ipc/node.socket`
- `OGMIOS_HOST=0.0.0.0`
- `OGMIOS_PORT=1337`

These can be overridden with environment variables:

```bash
docker run --rm \
  --name ogmios \
  -e CARDANO_CONFIG=/config/config.json \
  -e CARDANO_SOCKET_PATH=/ipc/node.socket \
  -e OGMIOS_PORT=1338 \
  -v ./config:/config:ro \
  -v ./ipc:/ipc \
  -p 1338:1338 \
  ghcr.io/blinklabs-io/ogmios
```

Additional Ogmios flags can be passed after `run`:

```bash
docker run --rm \
  -v node-ipc:/ipc \
  -p 1337:1337 \
  ghcr.io/blinklabs-io/ogmios run --log-level Info --include-cbor
```

Direct Ogmios subcommands are also available:

```bash
docker run --rm ghcr.io/blinklabs-io/ogmios version
docker run --rm ghcr.io/blinklabs-io/ogmios health-check --port 1337
```
