#!/usr/bin/env bash

function validator::has_value() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ -z "${_value}" ]]; then
    local -r _message="value is empty"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_alphanumeric() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ ! "${_value}" =~ ^[a-zA-Z0-9]+$ ]]; then
    local -r _message="value is not alphanumeric (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_alphabetic() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[a-zA-Z]+$ ]]; then
    local -r _message="value is not alphabetic (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_lower_kebab_case() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[a-z][-a-z0-9]*[^-]$ ]]; then
    local -r _message="value is not lower kebabu case (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_lower_snake_case() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[a-z][a-z0-9_]*[^_]$ ]]; then
    local -r _message="value is not lower snake case (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_upper_snake_case() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[A-Z][A-Z0-9_]*[^_]$ ]]; then
    local -r _message="value is not upper snake case (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_rfc_1123() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$ ]]; then
    local -r _message="value is not rfc 1123 (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_semantic_versioning() {
  local -r _version="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ ! "${_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    local -r _message="value is not semantic versioning (${_version})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_interger() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^-?[0-9]$ ]] && [[ ! "${_value}" =~ ^-?[1-9][0-9]*$ ]]; then
    local -r _message="value is not integer (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_positive_integer() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^[0-9]$ ]] && [[ ! "${_value}" =~ ^[1-9][0-9]*$ ]]; then
    local -r _message="value is not positive integer (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_negative_integer() {
  local -r _value="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_value}" =~ ^-[0-9]$ ]] && [[ ! "${_value}" =~ ^-[1-9][0-9]*$ ]]; then
    local -r _message="value is not negative integer (${_value})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::path_exists() {
  local -r _path="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ ! -e "${_path}" ]]; then
    local -r _message="path not found (${_path})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::directory_exists() {
  local -r _directory="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ ! -d "${_directory}" ]]; then
    local -r _message="directory not found (${_directory})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::file_exists() {
  local -r _file="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"
  if [[ ! -f "${_file}" ]]; then
    local -r _message="file not found (${_file})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::json_file_exists() {
  local -r _file="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  validator::file_exists "${_file}" "${_level}" "${_logger_format}" || return $?

  if [[ ! "${_file}" =~ ^.+\.json$ ]]; then
    local -r _message="json file not found (${_file})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::yaml_file_exists() {
  local -r _file="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  validator::file_exists "${_file}" "${_level}" "${_logger_format}" || return $?

  if [[ ! "${_file}" =~ ^.+\.yaml$ ]] && [[ ! "${_file}" =~ ^.+\.yml$ ]]; then
    local -r _message="yaml file not found (${_file})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::tsv_file_exists() {
  local -r _file="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  validator::file_exists "${_file}" "${_level}" "${_logger_format}" || return $?

  if [[ ! "${_file}" =~ ^.+\.tsv$ ]]; then
    local -r _message="tsv file not found (${_file})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::csv_file_exists() {
  local -r _file="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  validator::file_exists "${_file}" "${_level}" "${_logger_format}" || return $?

  if [[ ! "${_file}" =~ ^.+\.csv$ ]]; then
    local -r _message="csv file not found (${_file})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::command_exists() {
  local -r _command="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if ! command -v "${_command}" &>/dev/null; then
    local -r _message="command not found (${_command})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi
}

function validator::is_command_name() {
  local -r _command_path="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  validator::command_exists 'basename' || return $?

  local _command_name=''
  _command_name="$(basename "${_command_path}")"
  local -r _command_name

  validator::is_lower_kebab_case "${_command_name}" "${_level}" "${_logger_format}" || return $?
}

function validator::is_ipv4() {
  local -r _ip_address="${1:-}"
  local -r _level="${2:-error}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  if [[ ! "${_ip_address}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    local -r _message="value is not ipv4 address (${_ip_address})"
    logger::log "${_message}" "${_level}" "${_logger_format}"
    return 1
  fi

  validator::command_exists 'cut' || return $?

  local -a _octets=()
  _octets+=("$(echo "${_ip_address}" | cut -d '.' -f 1)")
  _octets+=("$(echo "${_ip_address}" | cut -d '.' -f 2)")
  _octets+=("$(echo "${_ip_address}" | cut -d '.' -f 3)")
  _octets+=("$(echo "${_ip_address}" | cut -d '.' -f 4)")
  local -ra _octets

  for _octet in "${_octets[@]}"; do
    if ((_octet < 0)) || ((_octet > 255)); then
      local -r _message="value is not ipv4 address (${_ip_address})"
      logger::log "${_message}" "${_level}" "${_logger_format}"
      return 1
    fi
  done
}
