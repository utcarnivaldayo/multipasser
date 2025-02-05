# ----- base -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-ubuntu:${GIT_BRANCH} AS base
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
ARG PROTO_VERSION

ARG WORKSPACE=/home/${USER_NAME}

USER root
RUN apt-get -y update \
  && apt-get --no-install-recommends -y install \
  curl \
  git \
  unzip \
  gzip \
  xz-utils \
  util-linux-extra \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER ${USER_NAME}

RUN curl --proto '=https' --tlsv1.2 -fsSL "https://moonrepo.dev/install/proto.sh" \
  | bash -s -- "${PROTO_VERSION}" --yes --no-profile \
  && echo "export PROTO_HOME=${WORKSPACE}/.proto" >> ${WORKSPACE}/.profile \
  && echo 'export PATH=${PROTO_HOME}/shims:${PROTO_HOME}/bin:${PATH}' >> ${WORKSPACE}/.profile \
  && echo "export PROTO_HOME=${WORKSPACE}/.proto" >> ${WORKSPACE}/.bashrc \
  && echo 'export PATH=${PROTO_HOME}/shims:${PROTO_HOME}/bin:${PATH}' >> ${WORKSPACE}/.bashrc


# ----- dev -----
FROM base AS dev
SHELL ["/bin/bash", "-c"]

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
SHELL ["/bin/bash", "-c"]

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=prod-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-rust/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}
