FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl gcc git gnupg \
        libffi-dev libgmp-dev libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

ARG GHC_VERSION=9.12.4
ARG CABAL_VERSION=3.16.1.0
ARG STACK_VERSION=3.3.1
ARG HLS_VERSION=2.14.0.0

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_NO_UPGRADE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=${GHC_VERSION} \
    BOOTSTRAP_HASKELL_CABAL_VERSION=${CABAL_VERSION} \
    BOOTSTRAP_HASKELL_STACK_VERSION=${STACK_VERSION} \
    BOOTSTRAP_HASKELL_INSTALL_HLS=1 \
    BOOTSTRAP_HASKELL_HLS_VERSION=${HLS_VERSION}

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:/root/.local/bin:${PATH}"

RUN cabal update

LABEL haskell.ghc-version="${GHC_VERSION}" \
      haskell.cabal-version="${CABAL_VERSION}" \
      haskell.stack-version="${STACK_VERSION}" \
      haskell.hls-version="${HLS_VERSION}"

CMD ["sleep", "infinity"]
