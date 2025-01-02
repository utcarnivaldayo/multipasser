# ----- dev -----
ARG PROJECT
ARG GIT_BRANCH
FROM dev-${PROJECT}-backend-rdb:${GIT_BRANCH} AS dev
SHELL ["/bin/bash", "-c"]

ARG PROJECT
ARG ROLE
ARG SERVICE
ARG USER_NAME
ARG MYSQL_CONFIG=my.cnf
ARG ENTRYPOINT_SCRIPT=rdb-replica-entrypoint
ARG DOCKERFILE_PATH=./${PROJECT}/docker/${ROLE}/${SERVICE}

USER ${USER_NAME}
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${MYSQL_CONFIG} /etc/mysql/${MYSQL_CONFIG}
COPY --chown=${USER_NAME}:${USER_NAME} ${DOCKERFILE_PATH}/${ENTRYPOINT_SCRIPT} /usr/local/bin/
RUN chmod +x /usr/local/bin/${ENTRYPOINT_SCRIPT}

EXPOSE 3306 33060

ENTRYPOINT ["/usr/local/bin/rdb-replica-entrypoint"]
CMD ["mysqld"]

# ----- prod -----
ARG PROJECT
ARG GIT_BRANCH
FROM prod-${PROJECT}-common-ubuntu:${GIT_BRANCH} AS prod
SHELL ["/bin/bash", "-c"]

EXPOSE 3306 33060
