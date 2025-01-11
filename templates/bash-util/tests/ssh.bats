#!/usr/bin/env bats

setup() {

  load "../lib/core.sh"
  load "../lib/logger.sh"
  load "../lib/validator.sh"
  load "../lib/ssh.sh"

  export RFC_1123_CLUSTER_NAME='rfc-1123-0123456789012345678901234567890123456789012345-cluster'
  export NO_RFC_1123_CLUSTER_NAME='un-rfc-1123-01234567890123456789012345678901234567890123-cluster'
  export SNAKE_CASE_CLUSTER_NAME='snake_case_cluster'
  export RFC_1123_SERVER_NAME='rfc-1123-01234567890123456789012345678901234567890123456-server'
  export NO_RFC_1123_SERVER_NAME='un-rfc-1123-012345678901234567890123456789012345678901234-server'
  export UNKNOW_SERVER_NAME='unknown-server-name'
  export SNAKE_CASE_SERVER_NAME='snake_case_server'
  export UNKOWN_SSH_DIR_NAME='unknown_ssh_dir'
  export RFC_1123_SSH_KEY_NAME='rfc-1123-0123456789012345678901234567890123456789012345-ssh-key'
  export NO_RFC_1123_SSH_KEY_NAME='un-rfc-1123-01234567890123456789012345678901234567890123-ssh-key'
  export SNAKE_CASE_SSH_KEY_NAME='snake_case_ssh_key'
  export SSH_KEY_COMMENT='ssh_key_comment'
  export BACKUP_SUFFIX='.backup'
  export DOCKER_COMPOSE_YAML="./fixtures/compose.yml"
  export NO_DOCKER_COMPOSE_YAML="./fixtures/no-compose.yml"
  export NO_PORTS_DOCKER_COMPOSE_YAML="./fixtures/no-ports-compose.yml"
  export LOGIN_USER='login_user'
  export SSH_PORT='22'
  export NO_SSH_PORT='-22'
}

teardown() {
  echo
}

@test 'ssh::connect_and_exit with rfc 1123 server name' {

  # NOTE: ssh 接続可能なサーバーを用意していないので、テストをスキップ
  skip

  run ssh::connect_and_exit "${RFC_1123_SERVER_NAME}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::connect_and_exit with known server name' {

  command -v jq &>/dev/null || false
  run ssh::connect_and_exit "${UNKNOW_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::connect_and_exit with no rfc 1123 server name' {

  command -v jq &>/dev/null || false
  run ssh::connect_and_exit "${NO_RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::connect_and_exit with snake case server' {

  command -v jq &>/dev/null || false
  run ssh::connect_and_exit "${SNAKE_CASE_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::create_workspace with rfc 1123 cluster and server names' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 0)) || false
  [[ -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with same workspace' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  ssh::create_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 0)) || false
  [[ -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with unknown ssh directory' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  local -r _unknown_ssh_dir="${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_workspace "${_unknown_ssh_dir}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with no rfc 1123 cluster name' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${NO_RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${NO_RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with no rfc 1123 server name' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${CLUSTER_SINGLE_NAME}/${RFC_1123_SERVER_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${CLUSTER_SINGLE_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with snake case cluster name' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${SNAKE_CASE_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${SNAKE_CASE_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::create_workspace with snake case server name' {

  local -r _expected_workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${SNAKE_CASE_SERVER_NAME}"

  run ssh::create_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${SNAKE_CASE_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::delete_workspace with rfc 1123 cluster and server names' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]]
  [[ ! -d "${_workspace}" ]] || false
}

@test 'ssh::delete_workspace with same workspace' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -d "${_expected_workspace}" ]] || false
}

@test 'ssh::delete_workspace with unknown ssh directory' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local -r unknown_ssh_dir="${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${unknown_ssh_dir}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ -d "${_workspace}" ]] || false
}

@test 'ssh::delete_workspace with no rfc 1123 cluster name' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${NO_RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ -d "${_workspace}" ]] || false
}

@test 'ssh::delete_workspace with no rfc 1123 server name' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${NO_RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ -d "${_workspace}" ]] || false
}

@test 'ssh::delete_workspace with snake case cluster name' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${SNAKE_CASE_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${SNAKE_CASE_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ -d "${_workspace}" ]] || false
}

@test 'ssh::delete_workspace with snake case server name' {

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${SNAKE_CASE_SERVER_NAME}"
  mkdir -p "${_workspace}"

  command -v jq &>/dev/null || false
  run ssh::delete_workspace "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${SNAKE_CASE_SERVER_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ -d "${_workspace}" ]] || false
}

@test 'ssh::create_key with rfc 1123 ssh key name' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"

  run ssh::create_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_expected_ssh_key}" ]] || false
  [[ -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::create_key with same ssh key' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"

  ssh::create_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  run ssh::create_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_expected_ssh_key}" ]] || false
  [[ -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::create_key with unknown ssh directory' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"
  local -r _unknown_ssh_dir="${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_key "${_unknown_ssh_dir}" "${RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_ssh_key}" ]] || false
  [[ ! -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::create_key with rfc 1123 ssh key name and no comment' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"

  run ssh::create_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_expected_ssh_key}" ]] || false
  [[ -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::create_key with no rfc 1123 ssh key name' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${NO_RFC_1123_SSH_KEY_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_key "${BATS_TEST_TMPDIR}" "${NO_RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_ssh_key}" ]] || false
  [[ ! -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::create_key with snake case ssh key name' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${SNAKE_CASE_SSH_KEY_NAME}"

  command -v jq &>/dev/null || false
  run ssh::create_key "${BATS_TEST_TMPDIR}" "${SNAKE_CASE_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_ssh_key}" ]] || false
  [[ ! -f "${_expected_ssh_key}.pub" ]] || false
}

@test 'ssh::get_public_key with rfc 1123 ssh key name' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"
  local -r _expected_ssh_key_pub="${_expected_ssh_key}.pub"

  ssh::create_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}" "${SSH_KEY_COMMENT}"
  run ssh::get_public_key "${BATS_TEST_TMPDIR}" "${RFC_1123_SSH_KEY_NAME}"

  (( status == 0 )) || false
  [[ -f "${_expected_ssh_key}.pub" ]] || false
  [[ "${output}" = "$(cat "${_expected_ssh_key}.pub")" ]] || false
}

@test 'ssh::get_public_key with unknown ssh directory' {

  local -r _expected_ssh_key="${BATS_TEST_TMPDIR}/${RFC_1123_SSH_KEY_NAME}"
  local -r _unknown_ssh_dir="${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}"

  run ssh::get_public_key "${_unknown_ssh_dir}" "${RFC_1123_SSH_KEY_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::get_public_key with no rfc 1123 ssh key name' {

  run ssh::get_public_key "${BATS_TEST_TMPDIR}" "${NO_RFC_1123_SSH_KEY_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::get_public_key with snake case ssh key name' {

  run ssh::get_public_key "${BATS_TEST_TMPDIR}" "${SNAKE_CASE_SSH_KEY_NAME}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::get_local_forward_from_compose_yaml with compose.yml' {

  skip
  run ssh::get_local_forward_from_compose_yaml "${DOCKER_COMPOSE_YAML}"

  (( status == 0 )) || false
  # assert_line --index 0 '  LocalForward 5173 0.0.0.0:5173'
  # assert_line --index 1 '  LocalForward 3001 0.0.0.0:3001'
  # assert_line --index 2 '  LocalForward 8081 0.0.0.0:8081'
}

@test 'ssh::get_local_forward_from_compose_yaml with no-ports-compose.yml' {

  skip
  run ssh::get_local_forward_from_compose_yaml "${NO_PORTS_DOCKER_COMPOSE_YAML}"

  (( status == 0 )) || false
  # assert_output --regexp '^\{(.+:.+,){4}.+:.+\}$'
}

@test 'ssh::get_local_forward_from_compose_yaml with no-compose.yml' {

  skip
  run ssh::get_local_forward_from_compose_yaml "${NO_DOCKER_COMPOSE_YAML}"

  (( status == 1 )) || false
  # assert_output --regexp '^\{(.+:.+,){4}.+:.+\}$'
}

@test 'ssh::refresh_known_hosts with rfc 1123 server name' {

  local -r _expected_known_hosts="${BATS_TEST_TMPDIR}/known_hosts"
  : > "${_expected_known_hosts}"

  run ssh::refresh_known_hosts "${BATS_TEST_TMPDIR}" "${RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_expected_known_hosts}" ]] || false
}

@test 'ssh::refresh_known_hosts with known rfc 1123 server name' {

  local _expected_known_hosts="${BATS_TEST_TMPDIR}/known_hosts"
  cat - <<EOS >"${_expected_known_hosts}"
${RFC_1123_SERVER_NAME}.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIv
${RFC_1123_SERVER_NAME}.local ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3
${RFC_1123_SERVER_NAME}.local ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF
192.168.64.239 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIv
192.168.64.239 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3
192.168.64.239 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF
EOS
  local -r _expected_known_hosts

  run ssh::refresh_known_hosts "${BATS_TEST_TMPDIR}" "${RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ -f "${_expected_known_hosts}" ]] || false
}

@test 'ssh::refresh_known_hosts with unknown ssh directory' {

  local -r _expected_known_hosts="${BATS_TEST_TMPDIR}/known_hosts"
  : > "${_expected_known_hosts}"

  local _refresh_known_hosts_args=()
  _refresh_known_hosts_args+=("${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}")
  _refresh_known_hosts_args+=("${RFC_1123_SERVER_NAME}")
  _refresh_known_hosts_args+=("${BACKUP_SUFFIX}")
  local -r _refresh_known_hosts_args

  command -v jq &>/dev/null || false
  run ssh::refresh_known_hosts "${_refresh_known_hosts_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::refresh_known_hosts with no rfc 1123 server name' {
  local _expected_known_hosts="${BATS_TEST_TMPDIR}/known_hosts"
  cat - <<EOS >"${_expected_known_hosts}"
${RFC_1123_SERVER_NAME}.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIv
${RFC_1123_SERVER_NAME}.local ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3
${RFC_1123_SERVER_NAME}.local ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF
192.168.64.239 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIv
192.168.64.239 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3
192.168.64.239 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF
EOS
  local -r _expected_known_hosts

  command -v jq &>/dev/null || false
  run ssh::refresh_known_hosts "${BATS_TEST_TMPDIR}" "${NO_RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::refresh_known_hosts with snake case server name' {

  local -r _expected_known_hosts="${BATS_TEST_TMPDIR}/known_hosts"
  : > "${_expected_known_hosts}"

  run ssh::refresh_known_hosts "${BATS_TEST_TMPDIR}" "${SNAKE_CASE_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::create_config with rfc 1123 server name' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::create_config with overwriting config' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  command -v jq &>/dev/null || false
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
  [[ -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with unknown ssh directory' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args

  command -v jq &>/dev/null || false
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with no rfc 1123 server name' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${NO_RFC_1123_SERVER_NAME}")
  _create_config_args+=("${NO_RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args

  command -v jq &>/dev/null || false
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with snake case server name' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${SNAKE_CASE_SERVER_NAME}")
  _create_config_args+=("${SNAKE_CASE_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with empty host name' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=('')
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with empty login user' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=('')
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with no ssh port' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${NO_SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with no docker compose yaml' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${NO_DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_expected_config}" ]] || false
}

@test 'ssh::create_config with empty docker compose yaml' {

  local -r _expected_config="${BATS_TEST_TMPDIR}/config"

  local _create_config_args=()
  _create_config_args+=("${BATS_TEST_TMPDIR}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  local -r _create_config_args
  run ssh::create_config "${_create_config_args[@]}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_expected_config}" ]] || false
}

@test 'ssh::enable_config with rfc 1123 cluster and server names' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  run ssh::enable_config "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::enable_config with already enable config' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args

  ssh::create_config "${_create_config_args[@]}"
  ssh::enable_config "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  command -v jq &>/dev/null || false
  run ssh::enable_config "${BATS_TEST_TMPDIR}" "${RFC_1123_CLUSTER_NAME}" "${RFC_1123_SERVER_NAME}" "${BACKUP_SUFFIX}"

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'ssh::enable_config with unknown ssh directory' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::enable_config "${_enable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::enable_config with no rfc 1123 cluster name' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${NO_RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::enable_config "${_enable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::enable_config with no rfc 1123 server name' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${NO_RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::enable_config "${_enable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::enable_config with snake case cluster name' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${SNAKE_CASE_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::enable_config "${_enable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::enable_config with snake case server name' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${SNAKE_CASE_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::enable_config "${_enable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::disable_config with rfc 1123 cluster and server names' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}")
  _disable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _disable_config_args+=("${RFC_1123_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'ssh::disable_config with already disable config' {

  : > "${BATS_TEST_TMPDIR}/config"

  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_enable_config_args[@]}"

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'ssh::disable_config with unknown ssh directory' {

  : > "${BATS_TEST_TMPDIR}/config"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}/${UNKOWN_SSH_DIR_NAME}")
  _disable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _disable_config_args+=("${RFC_1123_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::disable_config with no rfc 1123 cluster name' {

  : > "${BATS_TEST_TMPDIR}/config"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}")
  _disable_config_args+=("${NO_RFC_1123_CLUSTER_NAME}")
  _disable_config_args+=("${RFC_1123_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::disable_config with no rfc 1123 server name' {

  : > "${BATS_TEST_TMPDIR}/config"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}")
  _disable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _disable_config_args+=("${NO_RFC_1123_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::disable_config with snake case cluster name' {

  : > "${BATS_TEST_TMPDIR}/config"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}")
  _disable_config_args+=("${SNAKE_CASE_CLUSTER_NAME}")
  _disable_config_args+=("${RFC_1123_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::disable_config with snake case server name' {

  : > "${BATS_TEST_TMPDIR}/config"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"
  mkdir -p "${_workspace}"

  local _create_config_args=()
  _create_config_args+=("${_workspace}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}")
  _create_config_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_config_args+=("${LOGIN_USER}")
  _create_config_args+=("${SSH_PORT}")
  _create_config_args+=("${DOCKER_COMPOSE_YAML}")
  local -r _create_config_args
  ssh::create_config "${_create_config_args[@]}"

  local _enable_config_args=()
  _enable_config_args+=("${BATS_TEST_TMPDIR}")
  _enable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _enable_config_args+=("${RFC_1123_SERVER_NAME}")
  _enable_config_args+=("${BACKUP_SUFFIX}")
  local -r _enable_config_args
  ssh::enable_config "${_enable_config_args[@]}"

  local _disable_config_args=()
  _disable_config_args+=("${BATS_TEST_TMPDIR}")
  _disable_config_args+=("${RFC_1123_CLUSTER_NAME}")
  _disable_config_args+=("${SNAKE_CASE_SERVER_NAME}")
  _disable_config_args+=("${BACKUP_SUFFIX}")
  local -r _disable_config_args

  command -v jq &>/dev/null || false
  run ssh::disable_config "${_disable_config_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'ssh::create_settings with rfc 1123 cluster and server names' {

  : > "${BATS_TEST_TMPDIR}/config"
  : > "${BATS_TEST_TMPDIR}/known_hosts"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  local _create_settings_args=()
  _create_settings_args+=("${BATS_TEST_TMPDIR}")
  _create_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_settings_args+=("${LOGIN_USER}")
  _create_settings_args+=("${SSH_KEY_COMMENT}")
  _create_settings_args+=("${SSH_PORT}")
  _create_settings_args+=("${DOCKER_COMPOSE_YAML}")
  _create_settings_args+=("${BACKUP_SUFFIX}")
  local -r _create_settings_args
  run ssh::create_settings "${_create_settings_args[@]}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ -f "${_workspace}/config" ]] || false
  [[ -f "${_workspace}/${RFC_1123_SERVER_NAME}" ]] || false
  [[ -f "${_workspace}/${RFC_1123_SERVER_NAME}.pub" ]] || false
}

@test 'ssh::create_settings with orverwriting' {

  : > "${BATS_TEST_TMPDIR}/config"
  : > "${BATS_TEST_TMPDIR}/known_hosts"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  local _create_settings_args=()
  _create_settings_args+=("${BATS_TEST_TMPDIR}")
  _create_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_settings_args+=("${LOGIN_USER}")
  _create_settings_args+=("${SSH_KEY_COMMENT}")
  _create_settings_args+=("${SSH_PORT}")
  _create_settings_args+=("${DOCKER_COMPOSE_YAML}")
  _create_settings_args+=("${BACKUP_SUFFIX}")
  local -r _create_settings_args
  ssh::create_settings "${_create_settings_args[@]}"

  command -v jq &>/dev/null || false
  run ssh::create_settings "${_create_settings_args[@]}"

  (( status == 0 )) || false
  jq -r '.level' <<< "${output}" | xargs -I{} test "{}" = 'WARN' || false
  [[ -f "${_workspace}/config" ]] || false
  [[ -f "${_workspace}/${RFC_1123_SERVER_NAME}" ]] || false
  [[ -f "${_workspace}/${RFC_1123_SERVER_NAME}.pub" ]] || false
}

@test 'ssh::delete_settings with rfc 1123 cluster and server names' {

  : > "${BATS_TEST_TMPDIR}/config"
  : > "${BATS_TEST_TMPDIR}/known_hosts"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  local _create_settings_args=()
  _create_settings_args+=("${BATS_TEST_TMPDIR}")
  _create_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_settings_args+=("${LOGIN_USER}")
  _create_settings_args+=("${SSH_KEY_COMMENT}")
  _create_settings_args+=("${SSH_PORT}")
  _create_settings_args+=("${DOCKER_COMPOSE_YAML}")
  _create_settings_args+=("${BACKUP_SUFFIX}")
  local -r _create_settings_args
  ssh::create_settings "${_create_settings_args[@]}"

  local _delete_settings_args=()
  _delete_settings_args+=("${BATS_TEST_TMPDIR}")
  _delete_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _delete_settings_args+=("${RFC_1123_SERVER_NAME}")
  _delete_settings_args+=("${BACKUP_SUFFIX}")
  local -r _delete_settings_args
  run ssh::delete_settings "${_delete_settings_args[@]}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
  [[ ! -f "${_workspace}/config" ]] || false
  [[ ! -f "${_workspace}/${RFC_1123_SERVER_NAME}" ]] || false
  [[ ! -f "${_workspace}/${RFC_1123_SERVER_NAME}.pub" ]] || false
}

@test 'ssh::delete_settings with already deleted' {

  : > "${BATS_TEST_TMPDIR}/config"
  : > "${BATS_TEST_TMPDIR}/known_hosts"
  local -r _workspace="${BATS_TEST_TMPDIR}/${RFC_1123_CLUSTER_NAME}/${RFC_1123_SERVER_NAME}"

  local _create_settings_args=()
  _create_settings_args+=("${BATS_TEST_TMPDIR}")
  _create_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}")
  _create_settings_args+=("${RFC_1123_SERVER_NAME}.local")
  _create_settings_args+=("${LOGIN_USER}")
  _create_settings_args+=("${SSH_KEY_COMMENT}")
  _create_settings_args+=("${SSH_PORT}")
  _create_settings_args+=("${DOCKER_COMPOSE_YAML}")
  _create_settings_args+=("${BACKUP_SUFFIX}")
  local -r _create_settings_args
  ssh::create_settings "${_create_settings_args[@]}"

  local _delete_settings_args=()
  _delete_settings_args+=("${BATS_TEST_TMPDIR}")
  _delete_settings_args+=("${RFC_1123_CLUSTER_NAME}")
  _delete_settings_args+=("${RFC_1123_SERVER_NAME}")
  _delete_settings_args+=("${BACKUP_SUFFIX}")
  local -r _delete_settings_args
  ssh::delete_settings "${_delete_settings_args[@]}"

  command -v jq &>/dev/null || false
  run ssh::delete_settings "${_delete_settings_args[@]}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ ! -f "${_workspace}/config" ]] || false
  [[ ! -f "${_workspace}/${RFC_1123_SERVER_NAME}" ]] || false
  [[ ! -f "${_workspace}/${RFC_1123_SERVER_NAME}.pub" ]] || false
}
