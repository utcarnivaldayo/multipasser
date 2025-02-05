---
skip: {{ has_backend == false }}
---

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
LABEL org.opencontainers.image.source=https://github.com/utcarnivaldayo/multipasser/blob/${GIT_BRANCH}/templates/vite-node/docker/${ROLE}/${SERVICE}/Dockerfile
LABEL org.opencontainers.image.authors=utcarnivaldayo
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}

# args
ARG USER_NAME
ARG MYSQL_VERSION

ARG WORKSPACE=/home/${USER_NAME}
ARG MIGRATION_SQL_DIR=${WORKSPACE}/migration

# install base packages
USER root
RUN apt-get -y update \
  && apt-get --no-install-recommends -y install \
  mysql-server-${MYSQL_VERSION} \
  vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN usermod -aG mysql ${USER_NAME} \
  && rm -rf /var/lib/mysql \
  && mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql ${MIGRATION_SQL_DIR} \
	&& chown -R ${USER_NAME}:${USER_NAME} /var/lib/mysql /var/run/mysqld /var/log/mysql ${MIGRATION_SQL_DIR} \
	&& chmod 1777 /var/run/mysqld /var/lib/mysql /var/log/mysql ${MIGRATION_SQL_DIR}
USER ${USER_NAME}

# ----- dev -----
FROM base AS dev
SHELL ["/bin/bash", "-c"]

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
ARG MYSQL_CONFIG=my.cnf
ARG ENTRYPOINT_SCRIPT=rdb-entrypoint
ARG DOCKERFILE_PATH=./${PROJECT}/docker/${ROLE}/${SERVICE}

USER ${USER_NAME}
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${MYSQL_CONFIG} /etc/mysql/${MYSQL_CONFIG}
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${ENTRYPOINT_SCRIPT} /usr/local/bin/
RUN chmod +x /usr/local/bin/${ENTRYPOINT_SCRIPT}

EXPOSE 3306 33060

ENTRYPOINT ["/usr/local/bin/rdb-entrypoint"]
CMD ["mysqld"]

# ----- prod -----
FROM base AS prod
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

EXPOSE 3306 33060
