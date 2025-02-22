---
skip: {{ has_backend == false }}
---

# ----- dev -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-proto:${GIT_BRANCH} AS dev
SHELL ["/bin/bash", "-c"]

# args
ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=dev-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-node/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}

ARG USER_NAME
ARG VSCODE_EXTENSIONS_JSON
ARG APP_DIR
ARG BACKEND_PROJECT
ARG NODE_VERSION
ARG NPM_VERSION
ARG MYSQL_CONFIG
ARG PORT

ARG WORKSPACE=/home/${USER_NAME}
ARG DOCKERFILE_PATH=./${PROJECT}/docker/${ROLE}/${SERVICE}
ARG INIT_VSCODE_EXTENSIONS=init-vscode-extensions

# install dev packages
USER root
RUN apt-get -y update \
  && apt-get --no-install-recommends -y install vim nano jq zstd sqlite3 mysql-client iputils-ping net-tools direnv \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER ${USER_NAME}

# vscode extensions
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${MYSQL_CONFIG} /etc/mysql/${MYSQL_CONFIG}
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${VSCODE_EXTENSIONS_JSON} ${WORKSPACE}/

# init install vscode extensions
RUN <<EOF
cat - <<EOS >>${WORKSPACE}/.bashrc

# install vscode extensions
function install_extensions() { jq -r '.recommendations[]' ${WORKSPACE}/${VSCODE_EXTENSIONS_JSON} | xargs -I {} code --install-extension {} --force; }
if [[ -d ${WORKSPACE}/${INIT_VSCODE_EXTENSIONS} ]] && [[ -e \$(which code) ]] && [[ -f ${WORKSPACE}/${VSCODE_EXTENSIONS_JSON} ]]; then
  rm -rf ${WORKSPACE}/${INIT_VSCODE_EXTENSIONS}
  install_extensions
fi
[[ \${TERM_PROGRAM} != 'vscode' ]] && rm -rf ${WORKSPACE}/${INIT_VSCODE_EXTENSIONS}
if command -v direnv &> /dev/null; then
  eval "\$(direnv hook bash)"
fi
EOS
EOF
RUN echo "mkdir -p ${WORKSPACE}/${INIT_VSCODE_EXTENSIONS}" >> ${WORKSPACE}/.profile

# install proto
ENV PROTO_HOME=${WORKSPACE}/.proto
ENV PATH=${PROTO_HOME}/shims:${PROTO_HOME}/bin:${PATH}

RUN proto install node ${NODE_VERSION} \
  && proto install npm ${NPM_VERSION} \
  && mkdir -p ${WORKSPACE}/${APP_DIR}/${BACKEND_PROJECT}/node_modules

EXPOSE ${PORT}

# ----- prod -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-ubuntu:${GIT_BRANCH} AS prod
SHELL ["/bin/bash", "-c"]

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH

LABEL org.opencontainers.image.title=prod-${PROJECT}-${ROLE}-${SERVICE}
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-node/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}

ARG PORT

EXPOSE ${PORT}
