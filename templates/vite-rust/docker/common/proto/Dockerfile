# ----- base -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-ubuntu:${GIT_BRANCH} AS base
SHELL ["/bin/bash", "-c"]

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

# ----- prod -----
FROM base AS prod
SHELL ["/bin/bash", "-c"]
