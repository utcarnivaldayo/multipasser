#!/usr/bin/env bash

export LOGGER_FORMAT="${LOGGER_FORMAT:-json}"
export LOGGER_PRINT_TRACE="${LOGGER_ENABLE_TRACE:-true}"
export LOGGER_PRINT_DEBUG="${LOGGER_ENABLE_DEBUG:-true}"
export LOGGER_PRINT_INFO="${LOGGER_ENABLE_INFO:-true}"
export LOGGER_PRINT_WARN="${LOGGER_ENABLE_WARN:-true}"
export LOGGER_PRINT_ERROR="${LOGGER_ENABLE_ERROR:-true}"
export LOGGER_PRINT_FATAL="${LOGGER_ENABLE_FATAL:-true}"
export LOGGER_PRINT_MESSAGE_ONLY="${LOGGER_PRINT_MESSAGE_ONLY:-false}"
export LOGGER_HEADER_DATETIME="${LOGGER_HEADER_DATETIME:-datetime}"
export LOGGER_HEADER_SERVER="${LOGGER_HEADER_SERVER:-server}"
export LOGGER_HEADER_TARGET_TRIPLE="${LOGGER_HEADER_TARGET_TRIPLE:-target_triple}"
export LOGGER_HEADER_LEVEL="${LOGGER_HEADER_LEVEL:-level}"
export LOGGER_HEADER_MESSAGE="${LOGGER_HEADER_MESSAGE:-message}"

function logger::set_default_config() {
  export LOGGER_FORMAT='json'
  export LOGGER_PRINT_TRACE='true'
  export LOGGER_PRINT_DEBUG='true'
  export LOGGER_PRINT_INFO='true'
  export LOGGER_PRINT_WARN='true'
  export LOGGER_PRINT_ERROR='true'
  export LOGGER_PRINT_FATAL='true'
  export LOGGER_HEADER_DATETIME='datetime'
  export LOGGER_HEADER_SERVER='server'
  export LOGGER_HEADER_TARGET_TRIPLE='target_triple'
  export LOGGER_HEADER_LEVEL='level'
  export LOGGER_HEADER_MESSAGE='message'
}

function logger::print_level() {
  local -r _log_level="${1:-}"
  case "${_log_level}" in
  trace | TRACE)
    echo 'TRACE'
    ;;
  debug | DEBUG)
    echo 'DEBUG'
    ;;
  info | INFO | information | INFORMATION)
    echo 'INFO'
    ;;
  warn | WARN | warning | WARNING)
    echo 'WARN'
    ;;
  error | ERROR)
    echo 'ERROR'
    ;;
  fatal | FATAL)
    echo 'FATAL'
    ;;
  *) return 1 ;;
  esac
}

function logger::check_print_level() {
  local -r _log_level="${1:-}"
  case "${_log_level}" in
  trace | TRACE)
    [[ "${LOGGER_PRINT_TRACE:-true}" = 'true' ]] && return 0 || return 1
    ;;
  debug | DEBUG)
    [[ "${LOGGER_PRINT_DEGUB:-true}" = 'true' ]] && return 0 || return 1
    ;;
  info | INFO | information | INFORMATION)
    [[ "${LOGGER_PRINT_INFO:-true}" = 'true' ]] && return 0 || return 1
    ;;
  warn | WARN | warning | WARNING)
    [[ "${LOGGER_PRINT_WARN:-true}" = 'true' ]] && return 0 || return 1
    ;;
  error | ERROR)
    [[ "${LOGGER_PRINT_ERROR:-true}" = 'true' ]] && return 0 || return 1
    ;;
  fatal | FATAL)
    [[ "${LOGGER_PRINT_FATAL:-true}" = 'true' ]] && return 0 || return 1
    ;;
  *) return 1 ;;
  esac
}

function logger::log_json() {
  local -r _message="${1:-}"
  local -r _level="${2:-info}"

  local _logger_level=''
  _logger_level="$(logger::print_level "${_level}")"
  local -r _logger_level
  [[ -z "${_logger_level}" ]] && return 1

  if ! logger::check_print_level "${_level}"; then
    return 0
  fi

  local _datetime=''
  local _hostname=''
  local _target_triple=''
  _datetime="$(core::rfc_3339)"
  _hostname="$(core::hostname)"
  _target_triple="$(core::target_triple)"
  local -r _datetime
  local -r _hostname
  local -r _target_triple

  # json
  local -ra _log_json=(
    "{"
    "\"${LOGGER_HEADER_DATETIME:-datetime}\": \"${_datetime}\","
    "\"${LOGGER_HEADER_SERVER:-server}\": \"${_hostname}\","
    "\"${LOGGER_HEADER_TARGET_TRIPLE:-target_triple}\": \"${_target_triple}\","
    "\"${LOGGER_HEADER_LEVEL:-level}\": \"${_logger_level}\","
    "\"${LOGGER_HEADER_MESSAGE:-message}\": \"${_message}\""
    "}"
  )
  echo "${_log_json[*]}"
}

function logger::log_tsv() {
  local -r _message="${1:-}"
  local -r _level="${2:-info}"

  local _logger_level=''
  _logger_level="$(logger::print_level "${_level}")"
  local -r _logger_level
  [[ -z "${_logger_level}" ]] && return 1

  if ! logger::check_print_level "${_level}"; then
    return 0
  fi

  local _datetime=''
  local _hostname=''
  local _target_triple=''
  _datetime="$(core::rfc_3339)"
  _hostname="$(core::hostname)"
  _target_triple="$(core::target_triple)"
  local -r _datetime
  local -r _hostname
  local -r _target_triple

  # tsv
  local -ra _log_tsv=(
    "${_datetime}"
    "${_hostname}"
    "${_target_triple}"
    "${_logger_level}"
    "${_message}"
  )
  (IFS=$'\t'; echo "${_log_tsv[*]}")
}

function logger::log_csv() {
  local -r _message="${1:-}"
  local -r _level="${2:-info}"

  local _logger_level=''
  _logger_level="$(logger::print_level "${_level}")"
  local -r _logger_level
  [[ -z "${_logger_level}" ]] && return 1

  if ! logger::check_print_level "${_level}"; then
    return 0
  fi

  local _datetime=''
  local _hostname=''
  local _target_triple=''
  _datetime="$(core::rfc_3339)"
  _hostname="$(core::hostname)"
  _target_triple="$(core::target_triple)"
  local -r _datetime
  local -r _hostname
  local -r _target_triple

  # csv
  local -ra _log_csv=(
    "${_datetime}"
    "${_hostname}"
    "${_target_triple}"
    "${_logger_level}"
    "${_message}"
  )
  (IFS=','; echo "${_log_csv[*]}")
}

function logger::log() {
  local -r _message="${1:-}"
  local -r _level="${2:-info}"
  local -r _logger_format="${3:-${LOGGER_FORMAT:-json}}"

  case "${_logger_format}" in
  json)
    logger::log_json "${_message}" "${_level}"
    ;;
  tsv)
    logger::log_tsv "${_message}" "${_level}"
    ;;
  csv)
    logger::log_csv "${_message}" "${_level}"
    ;;
  *)
    return 1
    ;;
  esac
}

function logger::trace() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'trace' "${_logger_format}"
}

function logger::debug() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'debug' "${_logger_format}"
}

function logger::info() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'info' "${_logger_format}"
}

function logger::warn() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'warn' "${_logger_format}"
}

function logger::error() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'error' "${_logger_format}"
}

function logger::fatal() {
  local -r _message="${1:-}"
  local -r _logger_format="${2:-${LOGGER_FORMAT:-json}}"
  logger::log "${_message}" 'fatal' "${_logger_format}"
}

function logger::header_tsv() {

  local -ra _header_tsv=(
    "${LOGGER_HEADER_DATETIME}"
    "${LOGGER_HEADER_SERVER}"
    "${LOGGER_HEADER_TARGET_TRIPLE}"
    "${LOGGER_HEADER_LEVEL}"
    "${LOGGER_HEADER_MESSAGE}"
  )
  (IFS=$'\t'; echo "${_header_tsv[*]}")
}

function logger::header_csv() {
  local -ra _header_csv=(
    "${LOGGER_HEADER_DATETIME}"
    "${LOGGER_HEADER_SERVER}"
    "${LOGGER_HEADER_TARGET_TRIPLE}"
    "${LOGGER_HEADER_LEVEL}"
    "${LOGGER_HEADER_MESSAGE}"
  )
  (IFS=','; echo "${_header_csv[*]}")
}
