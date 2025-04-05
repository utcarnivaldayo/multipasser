#!/usr/bin/env bash

function cloud_init::set_hostname() {
  local -r _hostname="${1:-}"
  validator::has_value "${_hostname}" >&2 || return 1
  echo "hostname: ${_hostname}"
}

function cloud_init::set_locale() {
  local -r _locale="${1:-}"
  case "${_locale}" in
  en_US.UTF-8) ;;
  ja_JP.UTF-8) ;;
  *)
    logger::error "invalid locale (${_locale})" >&2
    return 1
    ;;
  esac
  echo "locale: ${_locale}"
}

function cloud_init::set_timezone() {
  local -r _timezone="${1:-}"
  case "${_timezone}" in
  Asia/Tokyo) ;;
  *)
    logger::error "invalid timezone (${_timezone})" >&2
    return 1
    ;;
  esac
  echo "timezone: ${_timezone}"
}

function cloud_init::set_ssh_pwauth() {
  local -r _ssh_pwauth="${1:-}"
  case "${_ssh_pwauth}" in
  yes | no) ;;
  *)
    logger::error "required yes or no (${_ssh_pwauth})" >&2
    return 1
    ;;
  esac
  echo "ssh_pwauth: ${_ssh_pwauth}"
}

function cloud_init::set_package_update() {
  local -r _package_update="${1:-}"
  case "${_package_update}" in
  true | false) ;;
  *)
    logger::error "required true or false (${_package_update})" >&2
    return 1
    ;;
  esac
  echo "package_update: ${_package_update}"
}

function cloud_init::set_package_upgrade() {
  local -r _package_upgrade="${1:-}"
  case "${_package_upgrade}" in
  true | false) ;;
  *)
    logger::error "required true or false (${_package_upgrade})" >&2
    return 1
    ;;
  esac
  echo "package_upgrade: ${_package_upgrade}"
}

function cloud_init::set_package_reboot_if_requred() {
  local -r _package_reboot_if_requred="${1:-}"
  case "${_package_reboot_if_requred}" in
  true | false) ;;
  *)
    logger::error "required true or false (${_package_reboot_if_requred})" >&2
    return 1
    ;;
  esac
  echo "package_reboot_if_requred: ${_package_reboot_if_requred}"
}

function cloud_init::set_apt_packages() {
  local -r _middleware_json="${1:-}"
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1
  validator::command_exists 'tr' >&2 || return 1

  if [[ "$(jq -r 'has("apt")' "${_middleware_json}")" = 'false' ]]; then
    logger::warn "no apt packages in middleware.json (${_middleware_json})" >&2
    return 0
  fi

  echo "packages:"
  jq -r '.apt | to_entries[] | select(.value == "latest" or .value == "") | [.key] | @tsv' "${_middleware_json}" \
    | tr '_' '-' \
    | sed -e 's|^|  - |'
  jq -rc '.apt | to_entries[] | select(.value != "latest") | [.key, .value]' "${_middleware_json}" \
    | tr '_' '-' \
    | sed -e 's|"||g' -e 's|^|  - |'
}

function cloud_init::set_snap_packages() {
  local -r _middleware_json="${1:-}"
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  validator::command_exists 'sed' >&2 || return 1

  if [[ "$(jq -r 'has("snap")' "${_middleware_json}")" = 'false' ]]; then
    logger::warn "no snap packages in middleware.json (${_middleware_json})" >&2
    return 0
  fi

  cat - <<EOS
snap:
  commands:
EOS
  jq -r '.snap | to_entries | map("snap install \(.key) --classic --channel=\(.value)") | .[]' "${_middleware_json}" \
    | tr '_' '-' \
    | sed -e 's|^|    - |'
}

function cloud_init::set_user() {
  local -r _user="${1:-}"
  local -r _lock_passwd="${2:-}"
  local -r _ssh_authorized_keys="${3:-}"
  validator::has_value "${_user}" >&2 || return 1
  validator::has_value "${_ssh_authorized_keys}" >&2 || return 1
  case "${_lock_passwd}" in
  true | false) ;;
  *)
    logger::error "required true or false (${_lock_passwd})" >&2
    return 1
    ;;
  esac
  cat - <<EOS
users:
  - name: ${_user}
    lock_passwd: ${_lock_passwd}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh-authorized-keys:
      - ${_ssh_authorized_keys}
    groups:
      - docker
EOS
}

function cloud_init::set_chpasswd() {
  local -r _user="${1:-}"
  local -r _password="${2:-}"
  local -r _expire="${3:-}"
  validator::has_value "${_user}" >&2 || return 1
  validator::has_value "${_password}" >&2 || return 1
  case "${_expire}" in
  true | false) ;;
  *)
    logger::error "required true or false (${_expire})" >&2
    return 1
    ;;
  esac
  cat - <<EOS
chpasswd:
  list: |
    ${_user}:${_password}
  expire: ${_expire}
EOS
}

function cloud_init::set_mounted_repository_safe_config() {
  local -r _user="${1:-}"
  local -r _mount_point="${2:-}"

  validator::has_value "${_user}" >&2 || return 1
  validator::has_value "${_mount_point}" >&2 || return 1

  cat - <<EOS | sed -e 's|^|  |'
- path: /home/${_user}/.gitconfig
  owner: ${_user}:${_user}
  append: true
  defer: true
  content: |
    [safe]
      directory = ${_mount_point}
EOS
}

function cloud_init::set_bashrc_initialize_vscode_extensions() {
  local -r _user="${1:-}"
  local -r _vscode_extensions_json="${2:-}"
  local -r _init_vscode_extensions="/home/${_user}/init-vscode-extensions"

  validator::has_value "${_user}" >&2 || return 1
  validator::json_file_exists "${_vscode_extensions_json}" >&2 || return 1
  validator::command_exists 'basename' >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  local _remote_vscode_extensions_json=''
  _remote_vscode_extensions_json="/home/${_user}/$(basename "${_vscode_extensions_json}")"

  cat - <<EOS | sed -e 's|^|    |'
function install_extensions() { jq -r '.recommendations[]' '${_remote_vscode_extensions_json}' | xargs -I {} code --install-extension {} --force; }
if [[ -d '${_init_vscode_extensions}' ]] && [[ -e "\$(command -v code)" ]] && [[ -f '${_remote_vscode_extensions_json}' ]]; then
  rm -rf '${_init_vscode_extensions}'
  install_extensions
fi
[[ "\${TERM_PROGRAM}" != 'vscode' ]] && rm -rf '${_init_vscode_extensions}'
EOS
}

function cloud_init::set_bashrc_gitignore_io() {

  local -r _gitignore_io_api_url='https://www.toptal.com/developers/gitignore/api'
  cat - <<EOS | sed -e 's|^|    |'
function gi() { curl -sL '${_gitignore_io_api_url}/\$@' ; }
EOS
}

function cloud_init::set_bashrc() {
  local -r _user="${1:-}"
  local -r _vscode_extensions_json="${2:-}"

  validator::has_value "${_user}" >&2 || return 1
  validator::json_file_exists "${_vscode_extensions_json}" >&2 || return 1

  cat - <<EOS | sed -e 's|^|  |'
- path: /home/${_user}/.bashrc
  owner: ${_user}:${_user}
  append: true
  defer: true
  content: |
$(cloud_init::set_bashrc_initialize_vscode_extensions "${_user}" "${_vscode_extensions_json}")
$(cloud_init::set_bashrc_gitignore_io)
    if command -v direnv &> /dev/null; then
      eval "\$(direnv hook bash)"
    fi
EOS
}

function cloud_init::set_profile_mkdir_init_vscode_extensions() {
  local -r _user="${1:-}"
  local -r _init_vscode_extensions="/home/${_user}/init-vscode-extensions"
  cat - <<EOS | sed -e 's|^|    |'
mkdir -p '${_init_vscode_extensions}'
EOS
}

function cloud_init::set_profile() {
  local -r _user="${1:-}"
  [[ -z "${_user}" ]] && return 1

  cat - <<EOS | sed -e 's|^|  |'
- path: /home/${_user}/.profile
  owner: ${_user}:${_user}
  append: true
  defer: true
  content: |
$(cloud_init::set_profile_mkdir_init_vscode_extensions "${_user}")
EOS
}

function cloud_init::set_vscode_extensions() {
  local -r _user="${1:-}"
  local -r _vscode_extensions_json="${2:-}"

  validator::has_value "${_user}" >&2 || return 1
  validator::json_file_exists "${_vscode_extensions_json}" >&2 || return 1

  local _remote_vscode_extensions_json=''
  _remote_vscode_extensions_json="$(basename "${_vscode_extensions_json}")"
  local -r _remote_vscode_extensions_json

  cat - <<EOS | sed -e 's|^|  |'
- path: /home/${_user}/${_remote_vscode_extensions_json}
  owner: ${_user}:${_user}
  append: true
  defer: true
  content: |
$(sed -e 's|^|    |' "${_vscode_extensions_json}")
EOS
}

function cloud_init::set_mkdir_mount_point() {
  local -r _mount_point="${1:-}"
  local -r _user="${2:-}"
  validator::has_value "${_mount_point}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c 'mkdir ${_mount_point}'
EOS
}

function cloud_init::set_install_docker() {
  local -r _middleware_json="${1:-}"
  local -r _docker_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_docker_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url='https://get.docker.com'
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash -s -- --version ${_docker_version}
EOS
}

function cloud_init::set_install_scie_pants() {

  local -r _middleware_json="${1:-}"
  local -r _scie_pants_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_scie_pants_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url="https://static.pantsbuild.org/setup/get-pants.sh"
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash -s -- -V ${_scie_pants_version}"
- su - ${_user} -c 'echo "export PATH=~/.local/bin:\\\$PATH" >> /home/${_user}/.profile'
EOS
}

function cloud_init::set_install_lltsv() {
  local -r _middleware_json="${1:-}"
  local -r _lltsv_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_lltsv_version}" >&2 || return 1
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
    # NOTE: apple silicon は未対応
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


  local -r _download_url='https://github.com/sonots/lltsv/releases/download'
  local -r _tar_url="${_download_url}/v${_lltsv_version}/lltsv_linux_${_cpu_type}"
cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_tar_url}' -o /usr/local/bin/lltsv
- chmod a+x /usr/local/bin/lltsv
EOS
}

function cloud_init::set_install_devbox() {
  local -r _middleware_json="${1:-}"
  local -r _devbox_version="${2:-}"
  local -r _user="${3:-}"

  if [[ "${_devbox_version}" != 'latest' ]]; then
    validator::is_semantic_versioning "${_devbox_version}" >&2 || return 1
  fi
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL https://get.jetify.com/devbox | bash -s -- -f"
EOS
}

function cloud_init::set_install_packages() {
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
    docker)
      cloud_init::set_install_docker "${_middleware_json}" "${_version}"
      ;;
    scie_pants)
      cloud_init::set_install_scie_pants "${_middleware_json}" "${_version}" "${_user}"
      ;;
    lltsv)
      cloud_init::set_install_lltsv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    devbox)
      cloud_init::set_install_devbox "${_middleware_json}" "${_version}" "${_user}"
      ;;
    *)
      return 1
      ;;
    esac
  done < <(jq -r '.runcmd | to_entries[] | .key' "${_middleware_json}")
}

function cloud_init::build_cloud_init() {
  local -r _hostname="${1:-}"
  local -r _user="${2:-}"
  local -r _password="${3:-}"
  local -r _ssh_authorized_keys="${4:-}"
  local -r _middleware_json="${5:-}"
  local -r _vscode_extensions_json="${6:-}"
  local -r _remote_mount_point="${7:-}"

  validator::has_value "${_hostname}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::has_value "${_password}" >&2 || return 1
  validator::has_value "${_ssh_authorized_keys}" >&2 || return 1
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::json_file_exists "${_vscode_extensions_json}" >&2 || return 1

  cat - <<EOS
#cloud-config
$(cloud_init::set_hostname "${_hostname}")
$(cloud_init::set_locale 'en_US.UTF-8')
$(cloud_init::set_timezone 'Asia/Tokyo')
$(cloud_init::set_ssh_pwauth 'no')
$(cloud_init::set_package_update 'true')
$(cloud_init::set_package_upgrade 'true')
$(cloud_init::set_package_reboot_if_requred 'true')

$(cloud_init::set_apt_packages "${_middleware_json}")
$(cloud_init::set_snap_packages "${_middleware_json}")

$(cloud_init::set_user "${_user}" 'true' "${_ssh_authorized_keys}")
$(cloud_init::set_chpasswd "${_user}" "${_password}" 'false')

write_files:
$(cloud_init::set_vscode_extensions "${_user}" "${_vscode_extensions_json}")
$(cloud_init::set_bashrc "${_user}" "${_vscode_extensions_json}")
$(cloud_init::set_profile "${_user}")
$([[ -n "${_remote_mount_point}" ]] && cloud_init::set_mounted_repository_safe_config "${_user}" "${_remote_mount_point}")

runcmd:
$(cloud_init::set_install_packages "${_middleware_json}" "${_user}")
$([[ -n "${_remote_mount_point}" ]] && cloud_init::set_mkdir_mount_point "${_remote_mount_point}" "${_user}")
EOS
}
