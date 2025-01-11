#!/usr/bin/env bash

function ssh::connect_and_exit() {
  local -r _server_name="${1:-}"

  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::command_exists 'ssh' >&2 || return 1

  if ! ssh -T -q -o StrictHostKeyChecking=accept-new "${_server_name}" 'exit' >&2; then
    logger::error "failed to connect to ${_server_name}" >&2
    return 1
  fi
}

function ssh::create_workspace() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"

  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::command_exists 'mkdir' >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"
  mkdir -p "${_workspace}" &>/dev/null || :
}

function ssh::get_workspace() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"

  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}/${_cluster_name}" >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"
  validator::directory_exists "${_workspace}" >&2 || return 1

  echo "${_workspace}"
}

function ssh::delete_workspace() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"

  validator::command_exists 'rm' >&2 || return 1
  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}/${_cluster_name}" >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"
  validator::directory_exists "${_workspace}" >&2 || return 1

  rm -rf "${_workspace}" &>/dev/null || :
}

function ssh::create_key() {
  local -r _workspace="${1:-}"
  local -r _ssh_key_name="${2:-}"
  local -r _comment="${3:-}"

  validator::directory_exists "${_workspace}" >&2 || return 1
  validator::is_rfc_1123 "${_ssh_key_name}" >&2 || return 1
  validator::command_exists 'yes' >&2 || return 1
  validator::command_exists 'ssh-keygen' >&2 || return 1

  local -a _args=()
  _args+=('-t' 'ecdsa')
  _args+=('-b' '521')
  _args+=('-N' '')
  _args+=('-f' "${_workspace}/${_ssh_key_name}")
  [[ -n "${_comment}" ]] && _args+=('-C' "${_comment}")
  local -ra _args
  yes | ssh-keygen "${_args[@]}" &>/dev/null || :
}

function ssh::get_public_key() {
  local -r _workspace="${1:-}"
  local -r _ssh_key_name="${2:-}"

  validator::directory_exists "${_workspace}" >&2 || return 1
  validator::is_rfc_1123 "${_ssh_key_name}" >&2 || return 1
  validator::command_exists 'cat' >&2 || return 1

  local -r _public_key="${_workspace}/${_ssh_key_name}.pub"
  validator::file_exists "${_public_key}" >&2 || return 1

  cat "${_public_key}"
}

function ssh::get_local_forward_from_compose_yaml() {
  local -r _docker_compose_yaml="${1:-}"
  validator::yaml_file_exists "${_docker_compose_yaml}" || return 1

  validator::command_exists 'grep' >&2 || return 1
  validator::command_exists 'awk' >&2 || return 1
  validator::command_exists 'cut' >&2 || return 1

  # NOTE
  if ! grep -q 'ports:' "${_docker_compose_yaml}" &> /dev/null; then
    logger::warn "no ports found in ${_docker_compose_yaml}" >&2
    return 0
  fi

  while read -r port; do
    echo "  LocalForward ${port} 0.0.0.0:${port}"
  done < <(awk '/ports:/,/^[[:space:]]*$/{if (/- [0-9]+:[0-9]+/) print $2}' "${_docker_compose_yaml}" | cut -d ':' -f 1)
}

function ssh::refresh_known_hosts() {
  local -r _ssh_config_dir="${1:-}"
  local -r _hostname="${2:-}"
  local -r _backup_suffix="${3:-}"

  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::has_value "${_hostname}" >&2 || return 1
  validator::has_value "${_backup_suffix}" >&2 || return 1

  local -r _ssh_known_hosts="${_ssh_config_dir}/known_hosts"
  validator::file_exists "${_ssh_known_hosts}" >&2 || return 1
  [[ ! -s "${_ssh_known_hosts}" ]] && echo >>"${_ssh_known_hosts}"

  validator::command_exists 'grep' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1

  if grep -q "${_hostname}" "${_ssh_known_hosts}" &>/dev/null; then
    sed -i"${_backup_suffix}" -e "\|^${_hostname}|d" "${_ssh_known_hosts}"
  fi
}

function ssh::create_config() {
  local -r _workspace="${1:-}"
  local -r _server_name="${2:-}"
  local -r _hostname="${3:-}"
  local -r _login_user="${4:-}"
  local -r _ssh_port="${5:-}"
  local -r _docker_compose_yaml="${6:-}"

  validator::directory_exists "${_workspace}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::has_value "${_hostname}" >&2 || return 1
  validator::has_value "${_login_user}" >&2 || return 1
  validator::is_positive_integer "${_ssh_port}" >&2 || return 1

  validator::command_exists 'cat' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1

  local _local_forwards=''
  if [[ -n "${_docker_compose_yaml}" ]]; then
    validator::yaml_file_exists "${_docker_compose_yaml}" >&2 || return 1
    _local_forwards="$(ssh::get_local_forward_from_compose_yaml "${_docker_compose_yaml}")"
  fi
  local -r _local_forwards

  [[ -f "${_workspace}/config" ]] && logger::warn "overwriting ${_workspace}/config" >&2

  local _private_key=''
  # shellcheck disable=SC2001
  _private_key="$(sed -e "s|^${HOME}|~|g" <<< "${_workspace}")/${_server_name}"
  local -r _private_key

  cat - <<EOS >|"${_workspace}/config"
Host ${_server_name}
  HostName ${_hostname}
  User ${_login_user}
  Port ${_ssh_port}
  IdentityFile ${_private_key}
  IdentitiesOnly yes
  Compression yes
  ServerAliveInterval 15
  ServerAliveCountMax 3
  ConnectionAttempts 3
  ForwardAgent yes
${_local_forwards}
EOS
}

function ssh::enable_config() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"
  local -r _backup_suffix="${4:-}"

  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}/${_cluster_name}" >&2 || return 1
  validator::has_value "${_backup_suffix}" >&2 || return 1
  validator::command_exists 'grep' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"
  validator::directory_exists "${_workspace}" >&2 || return 1

  local -r _ssh_workspace_config="${_workspace}/config"
  local -r _ssh_base_config="${_ssh_config_dir}/config"
  validator::file_exists "${_ssh_workspace_config}" >&2 || return 1
  validator::file_exists "${_ssh_base_config}" >&2 || return 1
  [[ ! -s "${_ssh_base_config}" ]] && echo >>"${_ssh_base_config}"

  # shellcheck disable=SC2001
  if ! grep -q "Include $(sed -e "s|^${HOME}|~|g" <<< "${_ssh_workspace_config}")" "${_ssh_base_config}" &>/dev/null; then
    sed -i"${_backup_suffix}" -e "1s|^|Include $(sed -e "s|^${HOME}|~|g" <<< "${_ssh_workspace_config}")\n|" "${_ssh_base_config}"
  else
    logger::warn "already enable ${_ssh_workspace_config} in ${_ssh_base_config}" >&2
  fi
}

function ssh::disable_config() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"
  local -r _backup_suffix="${4:-}"

  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}/${_cluster_name}" >&2 || return 1
  validator::has_value "${_backup_suffix}" >&2 || return 1
  validator::command_exists 'grep' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"
  validator::directory_exists "${_workspace}" >&2 || return 1

  local -r _ssh_workspace_config="${_workspace}/config"
  local -r _ssh_base_config="${_ssh_config_dir}/config"
  validator::file_exists "${_ssh_workspace_config}" >&2 || return 1
  validator::file_exists "${_ssh_base_config}" >&2 || return 1
  [[ ! -s "${_ssh_base_config}" ]] && echo >>"${_ssh_base_config}"

  # shellcheck disable=SC2001
  if grep -q "Include $(sed -e "s|^${HOME}|~|g" <<< "${_ssh_workspace_config}")" "${_ssh_base_config}" &>/dev/null; then
    sed -i"${_backup_suffix}" -e "\|^Include $(sed -e "s|^${HOME}|~|g" <<< "${_ssh_workspace_config}")|d" "${_ssh_base_config}"
  else
    logger::warn "already disable ${_ssh_workspace_config} in ${_ssh_base_config}" >&2
  fi
}

function ssh::create_settings() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"
  local -r _hostname="${4:-}"
  local -r _login_user="${5:-}"
  local -r _key_comment="${6:-}"
  local -r _ssh_port="${7:-}"
  local -r _docker_compose_yaml="${8:-}"
  local -r _backup_suffix="${9:-}"

  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::has_value "${_hostname}" >&2 || return 1
  validator::has_value "${_login_user}" >&2 || return 1
  validator::has_value "${_key_comment}" >&2 || return 1
  validator::is_positive_integer "${_ssh_port}" >&2 || return 1
  validator::has_value "${_backup_suffix}" >&2 || return 1
  if [[ -n "${_docker_compose_yaml}" ]]; then
    validator::yaml_file_exists "${_docker_compose_yaml}" >&2 || return 1
  fi

  ssh::create_workspace "${_ssh_config_dir}" "${_cluster_name}" "${_server_name}" || return 1
  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"

  ssh::create_key "${_workspace}" "${_server_name}" "${_key_comment}" || return 1
  ssh::create_config "${_workspace}" "${_server_name}" "${_hostname}" "${_login_user}" "${_ssh_port}" "${_docker_compose_yaml}" || return 1
  ssh::enable_config "${_ssh_config_dir}" "${_cluster_name}" "${_server_name}" "${_backup_suffix}" || return 1
  ssh::refresh_known_hosts "${_ssh_config_dir}" "${_hostname}" "${_backup_suffix}" || return 1
}

function ssh::delete_settings() {
  local -r _ssh_config_dir="${1:-}"
  local -r _cluster_name="${2:-}"
  local -r _server_name="${3:-}"
  local -r _hostname="${4:-}"
  local -r _backup_suffix="${4:-}"

  validator::is_rfc_1123 "${_cluster_name}" >&2 || return 1
  validator::is_rfc_1123 "${_server_name}" >&2 || return 1
  validator::has_value "${_hostname}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}" >&2 || return 1
  validator::directory_exists "${_ssh_config_dir}/${_cluster_name}" >&2 || return 1
  validator::has_value "${_backup_suffix}" >&2 || return 1

  local -r _workspace="${_ssh_config_dir}/${_cluster_name}/${_server_name}"

  ssh::refresh_known_hosts "${_ssh_config_dir}" "${_hostname}" "${_backup_suffix}" || return 1
  ssh::disable_config "${_ssh_config_dir}" "${_cluster_name}" "${_server_name}" "${_backup_suffix}" || return 1
  ssh::delete_workspace "${_ssh_config_dir}" "${_cluster_name}" "${_server_name}" || return 1
}
