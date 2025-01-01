# ----- base -----
ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION} AS base
SHELL ["/bin/bash", "-c"]

# args
ARG USER_NAME
ARG USER_PASSWORD

ARG WORKSPACE=/home/${USER_NAME}

# install base package
RUN apt-get -y update \
  && apt-get -s dist-upgrade | grep "^Inst" | grep -i "securi" | cut -d " " -f 2 | xargs apt-get -y install \
  && apt-get --no-install-recommends -y install sudo ca-certificates apt-transport-https tzdata util-linux-extra tini \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV TZ Asia/Tokyo
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8

# add general user
RUN useradd -m -s /bin/bash ${USER_NAME} \
  && echo ${USER_NAME}:${USER_PASSWORD} | chpasswd \
  && usermod -aG sudo ${USER_NAME} \
  && chown -R ${USER_NAME}:${USER_NAME} ${WORKSPACE}

WORKDIR ${WORKSPACE}
USER ${USER_NAME}


# ----- dev -----
FROM base AS dev
SHELL ["/bin/bash", "-c"]


# ----- prod -----
FROM base AS prod
SHELL ["/bin/bash", "-c"]
