#!/usr/bin/env bash

function core::monorepo_root() {
  if ! command -v git &>/dev/null; then
    return 1
  fi
  [[ "$(git rev-parse --is-inside-work-tree 2>&1)" != 'true' ]] && return 1

  if command -v cygpath &>/dev/null; then
    local _monorepo_root_win_path=''
    _monorepo_root_win_path="$(git rev-parse --show-superproject-working-tree --show-toplevel | head -n 1)"
    cygpath -u "${_monorepo_root_win_path}"
  else
    git rev-parse --show-superproject-working-tree --show-toplevel | head -n 1
  fi
}

function core::monorepo_name() {

  if ! command -v basename &>/dev/null; then
    return 1
  fi
  basename "$(core::monorepo_root)"
}

function core::rfc_3339() {

  if ! command -v 'date' &>/dev/null; then
    return 1
  fi
  if ! command -v 'sed' &>/dev/null; then
    return 1
  fi

  local _datetime=''
  _datetime="$(date '+%Y-%m-%dT%H:%M:%S')"
  local -r _datetime

  local _time_zone=''
  _time_zone="$(date '+%z' | sed -e 's|^\(\+..\)|\1:|')"
  local -r _time_zone

  [[ -z "${_datetime}" ]] && return 1
  [[ -z "${_time_zone}" ]] && return 1

  echo "${_datetime}${_time_zone}"
}

function core::hostname() {

  if ! command -v 'uname' &>/dev/null; then
    return 1
  fi
  uname -n
}

function core::target_triple() {

  # NOTE: rust installer inspired
  if ! command -v 'uname' &>/dev/null; then
    return 1
  fi

  local _os_type
  local _cpu_type
  local _clib_type
  _os_type="$(uname -s)"
  _cpu_type="$(uname -m)"
  _clib_type='gnu'

  if [[ "${_os_type}" = 'Linux' ]]; then

    local _os_system
    _os_system="$(uname -o)"
    [[ "${_os_system}" = 'Android' ]] && _os_type='Android'

    if ldd --version 2>&1 | grep -q 'musl'; then
      _clib_type='musl'
    fi
  fi

  if [[ "${_os_type}" = 'Darwin' ]] && [[ "${_cpu_type}" = 'i386' ]]; then
    if sysctl hw.optional.x86_64 2> /dev/null || : | grep -q ': 1'; then
      _cpu_type=x86_64
    fi
  fi

  if [[ "${_os_type}" = 'Darwin' ]] && [[ "${_cpu_type}" = 'x86_64' ]]; then
    if sysctl 'hw.optional.arm64' 2> /dev/null || : | grep -q ': 1'; then
      _cpu_type=arm64
    fi
  fi

  # os type
  case "${_os_type}" in
  Android)
    _os_type='linux-android'
    ;;
  Linux)
    _os_type="unknown-linux-${_clib_type}"
    ;;
  Darwin)
    _os_type='apple-darwin'
    ;;
  MINGW* | MSYS* | CYGWIN* | Windows_NT)
    _os_type='pc-windows-msvc'
    ;;
  *)
    _os_type='unknown-unknown'
    ;;
  esac

  # cpu type
  case "${_cpu_type}" in
  i386 | i486 | i686 | i786 | x86)
    _cputype=i686
    ;;
  xscale | arm)
    _cpu_type='arm'
    [[ "${_os_type}" = 'linux-android' ]] && _os_type='linux-androideabi'
    ;;
  armv6l)
    _cpu_type=arm
    [[ "${_os_type}" = "linux-android" ]] && _os_type=linux-androideabi || _os_type="${_os_type}eabihf"
    ;;
  armv7l | armv8l)
    _cpu_type=armv7
    [[ "${_os_type}" = "linux-android" ]] && _os_type=linux-androideabi || _os_type="${_os_type}eabihf"
    ;;
  aarch64 | arm64)
    _cpu_type='aarch64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    _cpu_type='unknown'
    ;;
  esac
  echo "${_cpu_type}-${_os_type}"
}
