---
skip: {{ has_backend == false }}
---

# ----- base -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-proto:${GIT_BRANCH} AS base
SHELL ["/bin/bash", "-c"]

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=base-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-rust/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}

# args
ARG USER_NAME
ARG RUST_VERSION

ARG WORKSPACE=/home/${USER_NAME}
ENV PROTO_HOME=${WORKSPACE}/.proto
ENV PATH=${WORKSPACE}/.cargo/bin:${PROTO_HOME}/shims:${PROTO_HOME}/bin:${PATH}

# install base packages
USER root
RUN apt-get -y update \
  && apt-get --no-install-recommends -y install curl pkg-config build-essential libssl-dev cmake \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER ${USER_NAME}
RUN proto install rust ${RUST_VERSION} \
  && rustup target add wasm32-unknown-unknown \
  && cargo install cargo-watch \
  && cargo install wasm-pack \
  && cargo install sqlx-cli


# ----- dev -----
FROM base AS dev

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=dev-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-rust/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}


# ----- prod -----
FROM base AS prod

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=prod-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-rust/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}
