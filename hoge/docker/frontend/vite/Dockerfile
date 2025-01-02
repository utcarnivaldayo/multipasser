# ----- base -----
ARG ENVIRONMENT
ARG PROJECT
ARG GIT_BRANCH
FROM ${ENVIRONMENT}-${PROJECT}-common-proto:${GIT_BRANCH} AS base
SHELL ["/bin/bash", "-c"]

# args
ARG USER_NAME
ARG NODE_VERSION
ARG PNPM_VERSION
ARG APP_DIR
ARG FRONTEND_PROJECT
ARG WORKSPACE=/home/${USER_NAME}
ENV PROTO_HOME=${WORKSPACE}/.proto
ENV PATH=${PROTO_HOME}/shims:${PROTO_HOME}/bin:${PATH}

USER ${USER_NAME}
RUN proto install node ${NODE_VERSION} \
  && proto install pnpm ${PNPM_VERSION} \
  && mkdir -p ${WORKSPACE}/${APP_DIR}/${FRONTEND_PROJECT}/node_modules

# ----- dev -----
FROM base AS dev
SHELL ["/bin/bash", "-c"]

# args
ARG PROJECT
ARG ROLE
ARG SERVICE
ARG USER_NAME
ARG VSCODE_EXTENSIONS_JSON
ARG PORT

ARG WORKSPACE=/home/${USER_NAME}
ARG DOCKERFILE_PATH=./${PROJECT}/docker/${ROLE}/${SERVICE}
ARG INIT_VSCODE_EXTENSIONS=init-vscode-extensions

USER root
RUN apt-get -y update \
  && apt-get --no-install-recommends -y install vim nano jq zstd direnv \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER ${USER_NAME}

# vscode extensions
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

EXPOSE ${PORT}

# ----- prod -----
FROM base AS prod
SHELL ["/bin/bash", "-c"]

ARG PORT

EXPOSE ${PORT}
