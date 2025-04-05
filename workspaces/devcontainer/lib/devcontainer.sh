#!/usr/bin/env bash

function devcontainer::add_bashrc_gitignore_io() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("git")' "${_middleware_json}")" = 'false' ]]; then
    logger::warn "not found git in middleware.json (${_middleware_json})" >&2
    return 0
  fi

  local -r _home="/home/${_user}"
  local -r _gitignore_io_api_url='https://www.toptal.com/developers/gitignore/api'
  cat - <<EOS >>"${_home}/.bashrc"
function gi() { curl -sL '${_gitignore_io_api_url}/\$@' ; }
EOS
}

function devcontainer::add_bashrc_direnv_hook() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("direnv")' "${_middleware_json}")" = 'false' ]] \
    && [[ "$(jq -r '.proto | has("direnv")' "${_middleware_json}")" = 'false' ]]; then
    logger::warn "not found direnv in middleware.json (${_middleware_json})" >&2
    return 0
  fi

  local -r _home="/home/${_user}"
  cat <<EOS >>"${_home}/.bashrc"
if command -v direnv &> /dev/null; then
  eval "\$(direnv hook bash)"
fi
EOS
}

function devcontainer::install_apt_get_packages() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  [[ "${_user}" = 'root' ]] && logger::error 'root user is not allowed' >&2 && return 1

  local -a _apt_packages=()
  local _formatted_package=''
  while read -r _package; do
    _formatted_package="$(echo "${_package}" | tr -d '\r' | tr '_' '-')"
    _apt_packages+=("${_formatted_package}")
  done < <(jq -r '.apt | to_entries[] | .key' "${_middleware_json}")

  sudo apt-get -y update
  sudo apt-get install --no-install-recommends -y "${_apt_packages[@]}"
}

function devcontainer::install_lltsv() {
  local -r _middleware_json="${1:-}"
  local -r _lltsv_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_lltsv_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type
  _cpu_type="$(uname -m)"

  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  cd "${_home}" || return 1
  local -r _download_url='https://github.com/sonots/lltsv/releases/download'
  local -r _tar_url="${_download_url}/v${_lltsv_version}/lltsv_linux_${_cpu_type}"
  curl --proto '=https' --tlsv1.2 -sSfL "${_tar_url}" -o /usr/local/bin/lltsv
  sudo chmod a+x /usr/local/bin/lltsv
}

function cloud_init::set_install_devbox() {
  local -r _middleware_json="${1:-}"
  local -r _devbox_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  if [[ "${_devbox_version}" != 'latest' ]]; then
    validator::is_semantic_versioning "${_devbox_version}" >&2 || return 1
  fi
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  cd "${_home}" || return 1
  curl --proto '=https' --tlsv1.2 -sSfL https://get.jetify.com/devbox | bash -s -- -f
}

function devcontainer::install_packages() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  validator::command_exists 'tr' >&2 || return 1

  local _version=''
  local _formatted_package=''
  while read -r _package; do
    _formatted_package="$(echo "${_package}" | tr -d '\r')"
    _version="$(jq -r --arg package "${_formatted_package}" '.runcmd[$package]' "${_middleware_json}")"
    [[ -z "${_version}" ]] && continue
    case "${_formatted_package}" in
    lltsv)
      devcontainer::install_lltsv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    docker)
      # NOTE: docker は devcontainer features でインストールされるため、手動インストールしない
      logger::warn 'docker is already installed by devcontainer features.'
      ;;
    *)
      return 1
      ;;
    esac
  done < <(jq -r '.runcmd | to_entries[] | .key' "${_middleware_json}")
}
