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

function cloud_init::set_install_act() {
  local -r _middleware_json="${1:-}"
  local -r _act_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_act_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url='https://raw.githubusercontent.com/nektos/act/master/install.sh'
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash -s -- -b /usr/local/bin v${_act_version}
EOS
}

function cloud_init::set_install_minikube() {
  local -r _middleware_json="${1:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"

  # cpu type
  case "${_cpu_type}" in
  xscale | arm)
    _cpu_type='arm'
    ;;
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _minikube_install_bin="minikube-linux-${_cpu_type}"
  local -r _script_url="https://storage.googleapis.com/minikube/releases/latest/${_minikube_install_bin}"
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfLO '${_script_url}'
- install ${_minikube_install_bin} /usr/local/bin/minikube && rm ${_minikube_install_bin}
EOS
}

function cloud_init::set_install_kind() {
  local -r _middleware_json="${1:-}"
  local -r _kind_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_kind_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _bin_url="https://kind.sigs.k8s.io/dl/v${_kind_version}/kind-linux-${_cpu_type}"
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_bin_url}' -o /usr/local/bin/kind
- chmod a+x /usr/local/bin/kind
EOS
}

function cloud_init::set_install_kubectl() {

  local -r _middleware_json="${1:-}"
  local -r _kubectl_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_kubectl_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac
  local -r _script_url="https://dl.k8s.io/release/v${_kubectl_version}/bin/linux/${_cpu_type}/kubectl"
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfLO '${_script_url}'
- install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
EOS
}

function cloud_init::set_install_tilt() {
  local -r _middleware_json="${1:-}"
  local -r _tilt_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_tilt_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url="https://github.com/tilt-dev/tilt/releases/download"
  local -r _tar_url="${_download_url}/v${_tilt_version}/tilt.${_tilt_version}.linux.${_cpu_type}.tar.gz"
cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_tar_url}' | tar -xzv tilt && mv tilt /usr/local/bin/tilt
EOS
}

function cloud_init::set_infisical() {
  local -r _middleware_json="${1:-}"
  local -r _infisical_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_infisical_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url="https://github.com/Infisical/infisical/releases/download"
  local -r _tar_url="${_download_url}/infisical-cli/v${_infisical_version}/infisical_${_infisical_version}_linux_${_cpu_type}.tar.gz"
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_tar_url}' | tar -xzv infisical && mv infisical /usr/local/bin/infisical
EOS
}

function cloud_init::set_install_ctlptl() {
  local -r _middleware_json="${1:-}"
  local -r _ctlptl_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_ctlptl_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url="https://github.com/tilt-dev/ctlptl/releases/download"
  local -r _tar_url="${_download_url}/v${_ctlptl_version}/ctlptl.${_ctlptl_version}.linux.${_cpu_type}.tar.gz"
cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_tar_url}' | tar -xzv -C /usr/local/bin ctlptl
EOS
}

function cloud_init::set_install_opentofu() {
  local -r _middleware_json="${1:-}"
  local -r _opentofu_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_opentofu_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _install_script='install-opentofu.sh'
  local -r _script_url="https://get.opentofu.org/${_install_script}"
cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -fsSL '${_script_url}' -o ${_install_script}
- chmod a+x ${_install_script}
- bash ${_install_script} --install-method standalone --opentofu-version ${_opentofu_version}
- rm -f ${_install_script}
EOS
}

function cloud_init::set_install_stripe_cli() {
  local -r _middleware_json="${1:-}"
  local -r _stripe_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_stripe_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type=''
  _cpu_type="$(uname -m)"
  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='aarch64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url='https://github.com/stripe/stripe-cli/releases/download'
  local -r _tar_url="${_download_url}/v${_stripe_version}/stripe_${_stripe_version}_linux_${_cpu_type}.tar.gz"
cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_tar_url}' | tar -xzv stripe && mv stripe /usr/local/bin/stripe
EOS
}

function cloud_init::set_install_radicle() {
  local -r _middleware_json="${1:-}"
  local -r _radicle_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  if [[ "${_radicle_version}" != 'latest' ]]; then
    validator::is_semantic_versioning "${_radicle_version}" >&2 || return 1
  fi
  validator::command_exists 'jq' >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("xz_utils")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required xz_utils in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url='https://radicle.xyz/install'
  local -r _radicle_path="/home/${_user}/.radicle"
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash -s -- --prefix=${_radicle_path} --version=${_radicle_version}"
EOS
}

function cloud_init::set_install_aws_cli_v2() {

  local -r _middleware_json="${1:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("unzip")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required unzip in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type
  _cpu_type="$(uname -m)"

  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='aarch64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _install_zip_url="https://awscli.amazonaws.com/awscli-exe-linux-${_cpu_type}.zip"
  cat - <<EOS | sed -e 's|^|  |'
- curl --proto '=https' --tlsv1.2 -sSfL '${_install_zip_url}' -o awscliv2.zip && unzip awscliv2.zip
- ./aws/install
EOS
}

function cloud_init::set_install_bats_core() {

  local -r _middleware_json="${1:-}"
  local -r _bats_version="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_bats_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("git")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required git in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _repository_url='https://github.com/bats-core/bats-core.git'
  cat - <<EOS | sed -e 's|^|  |'
- git clone -b v${_bats_version} --single-branch --depth=1 '${_repository_url}'
- cd bats-core && ./install.sh /usr/local && cd ../ && rm -rf bats-core
EOS
}

function cloud_init::set_install_uv() {

  local -r _middleware_json="${1:-}"
  local -r _uv_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_uv_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url="https://astral.sh/uv/${_uv_version}/install.sh"
cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash"
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

function cloud_init::set_install_mise() {

  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url='https://mise.run'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash"
- su - ${_user} -c "echo 'export PATH=~/.local/bin:~/.local/share/mise/shims:\\\$PATH' >> /home/${_user}/.profile"
EOS
}

function cloud_init::set_install_duckdb() {

  local -r _middleware_json="${1:-}"
  local -r _duckdb_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_duckdb_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("unzip")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required unzip in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type
  _cpu_type="$(uname -m)"

  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='aarch64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='amd64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url='https://github.com/duckdb/duckdb/releases/download'
  local -r _zip_url="${_download_url}/v${_duckdb_version}/duckdb_cli-linux-${_cpu_type}.zip"
  local -ra _curl_option=('--proto' '=https' '--tlsv1.2' '-sSfL' "${_zip_url}" '-o' 'duckdb.zip')
cat - <<EOS | sed -e 's|^|  |'
- curl ${_curl_option[*]} && unzip duckdb.zip && mv duckdb /usr/local/bin && rm duckdb.zip
EOS
}

function cloud_init::set_install_proto() {

  local -r _middleware_json="${1:-}"
  local -r _proto_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_proto_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r 'has("proto")' "${_middleware_json}")" = 'false' ]]; then
    logger::warn "no proto packages in middleware.json (${_middleware_json})" >&2
    return 0
  fi

  # dependency check
  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("git")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required git in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("unzip")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required unzip in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("gzip")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required gzip in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("xz_utils")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required xz_utils in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _script_url='https://moonrepo.dev/install/proto.sh'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL '${_script_url}' | bash -s -- ${_proto_version} --yes --no-profile"
- su - ${_user} -c "echo 'export PROTO_HOME=~/.proto' >> /home/${_user}/.bashrc"
- su - ${_user} -c "echo 'export PATH=~/.proto/shims:~/.proto/bin:\\\$PATH' >> /home/${_user}/.bashrc"
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

function cloud_init::set_install_pixi() {
  local -r _middleware_json="${1:-}"
  local -r _pixi_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_pixi_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "curl --proto '=https' --tlsv1.2 -sSfL https://pixi.sh/install.sh | PIXI_VERSION=v${_pixi_version} bash"
EOS
}

function cloud_init::set_install_sam() {

  local -r _middleware_json="${1:-}"
  local -r _sam_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_sam_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi
  if [[ "$(jq -r '.apt | has("unzip")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required unzip in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _cpu_type
  _cpu_type="$(uname -m)"

  # cpu type
  case "${_cpu_type}" in
  aarch64 | arm64)
    _cpu_type='arm64'
    ;;
  x86_64 | x86-64 | x64 | amd64)
    _cpu_type='x86_64'
    ;;
  *)
    logger::error "unsupported cpu type (${_cpu_type})" >&2
    return 1
    ;;
  esac

  local -r _download_url='https://github.com/aws/aws-sam-cli/releases/download'
  local -r _zip_url="${_download_url}/v${_sam_version}/aws-sam-cli-linux-${_cpu_type}.zip"
  local -ra _curl_option=('--proto' '=https' '--tlsv1.2' '-sSfL' "${_zip_url}" '-o' 'aws-sam-cli.zip')
cat - <<EOS | sed -e 's|^|  |'
- curl ${_curl_option[*]} && unzip aws-sam-cli.zip -d sam-installation
- ./sam-installation/install && rm aws-sam-cli.zip
EOS
}

function cloud_init::set_proto_install_bun() {
  local -r _middleware_json="${1:-}"
  local -r _bun_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_bun_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install bun ${_bun_version}"
EOS
}

function cloud_init::set_proto_install_deno() {
  local -r _middleware_json="${1:-}"
  local -r _deno_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_deno_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install deno ${_deno_version}"
EOS
}

function cloud_init::set_proto_install_go() {
  local -r _middleware_json="${1:-}"
  local -r _go_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_go_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install go ${_go_version}"
EOS
}

function cloud_init::set_proto_install_node() {
  local -r _middleware_json="${1:-}"
  local -r _node_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_node_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1

  # dependency check
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install node ${_node_version}"
EOS
}

function cloud_init::set_proto_install_npm() {
  local -r _middleware_json="${1:-}"
  local -r _npm_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_npm_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install npm ${_npm_version}"
EOS
}

function cloud_init::set_proto_install_pnpm() {
  local -r _middleware_json="${1:-}"
  local -r _pnpm_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_pnpm_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install pnpm ${_pnpm_version}"
EOS
}

function cloud_init::set_proto_install_rust() {
  local -r _middleware_json="${1:-}"
  local -r _rust_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_rust_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install rust ${_rust_version}"
EOS
}

function cloud_init::set_proto_install_yarn() {
  local -r _middleware_json="${1:-}"
  local -r _yarn_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_yarn_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto install yarn ${_yarn_version}"
EOS
}

function cloud_init::set_proto_install_act() {
  local -r _middleware_json="${1:-}"
  local -r _act_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_act_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/theomessin/proto-toml-plugins/master/act.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add act ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install act ${_act_version}"
EOS
}

function cloud_init::set_proto_install_actionlint() {
  local -r _middleware_json="${1:-}"
  local -r _actionlint_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_actionlint_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/actionlint/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add actionlint ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install actionlint ${_actionlint_version}"
EOS
}

function cloud_init::set_proto_install_argo() {
  local -r _middleware_json="${1:-}"
  local -r _argo_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_argo_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/argo/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add argo ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install argo ${_argo_version}"
EOS
}

function cloud_init::set_proto_install_argocd() {
  local -r _middleware_json="${1:-}"
  local -r _argocd_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_argocd_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/argocd/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add argocd ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install argocd ${_argocd_version}"
EOS
}

function cloud_init::set_proto_install_biome() {
  local -r _middleware_json="${1:-}"
  local -r _biome_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_biome_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/biome/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add biome ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install biome ${_biome_version}"
EOS
}

function cloud_init::set_proto_install_direnv() {
  local -r _middleware_json="${1:-}"
  local -r _direnv_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_direnv_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/direnv/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add direnv ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install direnv ${_direnv_version}"
EOS
}

function cloud_init::set_proto_install_dprint() {
  local -r _middleware_json="${1:-}"
  local -r _dprint_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_dprint_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/dprint/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add dprint ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install dprint ${_dprint_version}"
EOS
}

function cloud_init::set_proto_install_gh() {
  local -r _middleware_json="${1:-}"
  local -r _gh_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_gh_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/gh/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add gh ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install gh ${_gh_version}"
EOS
}

function cloud_init::set_proto_install_helm() {
  local -r _middleware_json="${1:-}"
  local -r _helm_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_helm_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/stk0vrfl0w/proto-toml-plugins/main/plugins/helm.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add helm ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install helm ${_helm_version}"
EOS
}

function cloud_init::set_proto_install_helmfile() {
  local -r _middleware_json="${1:-}"
  local -r _helmfile_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_helmfile_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/stk0vrfl0w/proto-toml-plugins/main/plugins/helmfile.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add helmfile ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install helmfile ${_helmfile_version}"
EOS
}

function cloud_init::set_proto_install_infisical() {
  local -r _middleware_json="${1:-}"
  local -r _infisical_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_infisical_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/infisical/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add infisical ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install infisical ${_infisical_version}"
EOS
}

function cloud_init::set_proto_install_jira_cli() {
  local -r _middleware_json="${1:-}"
  local -r _jira_cli_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_jira_cli_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/jira/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add jira ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install jira ${_jira_cli_version}"
EOS
}

function cloud_init::set_proto_install_jq() {
  local -r _middleware_json="${1:-}"
  local -r _jq_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_jq_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/jq/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add jq ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install jq ${_jq_version}"
EOS
}

function cloud_init::set_proto_install_k3d() {
  local -r _middleware_json="${1:-}"
  local -r _k3d_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_k3d_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/k3d/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add k3d ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install k3d ${_k3d_version}"
EOS
}

function cloud_init::set_proto_install_kubectl() {
  local -r _middleware_json="${1:-}"
  local -r _kubectl_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_kubectl_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/stk0vrfl0w/proto-toml-plugins/main/plugins/kubectl.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add kubectl ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install kubectl ${_kubectl_version}"
EOS
}

function cloud_init::set_proto_install_mise() {
  local -r _middleware_json="${1:-}"
  local -r _mise_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_mise_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/mise/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add mise ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install mise ${_mise_version}"
EOS
}

function cloud_init::set_proto_install_moon() {
  local -r _middleware_json="${1:-}"
  local -r _moon_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_moon_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/moonrepo/moon/master/proto-plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add moon ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install moon ${_moon_version}"
EOS
}

function cloud_init::set_proto_install_shellcheck(){
  local -r _middleware_json="${1:-}"
  local -r _shellcheck_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_shellcheck_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/shellcheck/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add shellcheck ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install shellcheck ${_shellcheck_version}"
EOS
}

function cloud_init::set_proto_install_shfmt(){
  local -r _middleware_json="${1:-}"
  local -r _shfmt_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_shfmt_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/shfmt/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add shfmt ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install shfmt ${_shfmt_version}"
EOS
}

function cloud_init::set_proto_install_sops(){
  local -r _middleware_json="${1:-}"
  local -r _sops_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_sops_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/stk0vrfl0w/proto-toml-plugins/main/plugins/sops.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add sops ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install sops ${_sops_version}"
EOS
}

function cloud_init::set_proto_install_tilt(){
  local -r _middleware_json="${1:-}"
  local -r _tilt_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_tilt_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/tilt/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add tilt ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install tilt ${_tilt_version}"
EOS
}

function cloud_init::set_proto_install_yq(){
  local -r _middleware_json="${1:-}"
  local -r _yq_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_yq_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/appthrust/proto-toml-plugins/main/yq/plugin.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add yq ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install yq ${_yq_version}"
EOS
}

function cloud_init::set_proto_install_zig(){
  local -r _middleware_json="${1:-}"
  local -r _zig_version="${2:-}"
  local -r _user="${3:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_zig_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local -r _toml_plugin='https://raw.githubusercontent.com/stk0vrfl0w/proto-toml-plugins/main/plugins/zig.toml'
  cat - <<EOS | sed -e 's|^|  |'
- su - ${_user} -c "~/.proto/bin/proto plugin add zig ${_toml_plugin}"
- su - ${_user} -c "~/.proto/bin/proto install zig ${_zig_version}"
EOS
}

function cloud_init::set_proto_install_packages() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"
  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  validator::command_exists 'tr' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    return 0
  fi

  local _version=''
  local _formatted_package=''
  while read -r _package; do
    _formatted_package="$(echo "${_package}" | tr -d '\r')"
    _version="$(jq -r --arg package "${_formatted_package}" '.proto[$package]' "${_middleware_json}")"
    [[ -z "${_version}" ]] && continue
    case "${_formatted_package}" in
    act)
      cloud_init::set_proto_install_act "${_middleware_json}" "${_version}" "${_user}"
      ;;
    actionlint)
      cloud_init::set_proto_install_actionlint "${_middleware_json}" "${_version}" "${_user}"
      ;;
    argo)
      cloud_init::set_proto_install_argo "${_middleware_json}" "${_version}" "${_user}"
      ;;
    argocd)
      cloud_init::set_proto_install_argocd "${_middleware_json}" "${_version}" "${_user}"
      ;;
    biome)
      cloud_init::set_proto_install_biome "${_middleware_json}" "${_version}" "${_user}"
      ;;
    direnv)
      cloud_init::set_proto_install_direnv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    dprint)
      cloud_init::set_proto_install_dprint "${_middleware_json}" "${_version}" "${_user}"
      ;;
    gh)
      cloud_init::set_proto_install_gh "${_middleware_json}" "${_version}" "${_user}"
      ;;
    helm)
      cloud_init::set_proto_install_helm "${_middleware_json}" "${_version}" "${_user}"
      ;;
    helmfile)
      cloud_init::set_proto_install_helmfile "${_middleware_json}" "${_version}" "${_user}"
      ;;
    infisical)
      cloud_init::set_proto_install_infisical "${_middleware_json}" "${_version}" "${_user}"
      ;;
    jira_cli)
      cloud_init::set_proto_install_jira_cli "${_middleware_json}" "${_version}" "${_user}"
      ;;
    jq)
      cloud_init::set_proto_install_jq "${_middleware_json}" "${_version}" "${_user}"
      ;;
    k3d)
      cloud_init::set_proto_install_k3d "${_middleware_json}" "${_version}" "${_user}"
      ;;
    kubectl)
      cloud_init::set_proto_install_kubectl "${_middleware_json}" "${_version}" "${_user}"
      ;;
    mise)
      cloud_init::set_proto_install_mise "${_middleware_json}" "${_version}" "${_user}"
      ;;
    moon)
      cloud_init::set_proto_install_moon "${_middleware_json}" "${_version}" "${_user}"
      ;;
    shellcheck)
      cloud_init::set_proto_install_shellcheck "${_middleware_json}" "${_version}" "${_user}"
      ;;
    shfmt)
      cloud_init::set_proto_install_shfmt "${_middleware_json}" "${_version}" "${_user}"
      ;;
    sops)
      cloud_init::set_proto_install_sops "${_middleware_json}" "${_version}" "${_user}"
      ;;
    tilt)
      cloud_init::set_proto_install_tilt "${_middleware_json}" "${_version}" "${_user}"
      ;;
    yq)
      cloud_init::set_proto_install_yq "${_middleware_json}" "${_version}" "${_user}"
      ;;
    zig)
      cloud_init::set_proto_install_zig "${_middleware_json}" "${_version}" "${_user}"
      ;;
    *)
      return 1
      ;;
    esac
  done < <(jq -r '.proto | to_entries[] | .key' "${_middleware_json}")
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
    act)
      cloud_init::set_install_act "${_middleware_json}" "${_version}"
      ;;
    minikube)
      cloud_init::set_install_minikube "${_middleware_json}"
      ;;
    kind)
      cloud_init::set_install_kind "${_middleware_json}" "${_version}"
      ;;
    kubectl)
      cloud_init::set_install_kubectl "${_middleware_json}" "${_version}"
      ;;
    aws_cli)
      cloud_init::set_install_aws_cli_v2 "${_middleware_json}"
      ;;
    tilt)
      cloud_init::set_install_tilt "${_middleware_json}" "${_version}"
      ;;
    infisical)
      cloud_init::set_infisical "${_middleware_json}" "${_version}"
      ;;
    ctlptl)
      cloud_init::set_install_ctlptl "${_middleware_json}" "${_version}"
      ;;
    opentofu)
      cloud_init::set_install_opentofu "${_middleware_json}" "${_version}"
      ;;
    stripe_cli)
      cloud_init::set_install_stripe_cli "${_middleware_json}" "${_version}" "${_user}"
      ;;
    radicle)
      cloud_init::set_install_radicle "${_middleware_json}" "${_version}" "${_user}"
      ;;
    bats_core)
      cloud_init::set_install_bats_core "${_middleware_json}" "${_version}"
      ;;
    proto)
      cloud_init::set_install_proto "${_middleware_json}" "${_version}" "${_user}"
      ;;
    mise)
      cloud_init::set_install_mise "${_middleware_json}" "${_user}"
      ;;
    scie_pants)
      cloud_init::set_install_scie_pants "${_middleware_json}" "${_version}" "${_user}"
      ;;
    duckdb)
      cloud_init::set_install_duckdb "${_middleware_json}" "${_version}" "${_user}"
      ;;
    uv)
      cloud_init::set_install_uv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    lltsv)
      cloud_init::set_install_lltsv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    pixi)
      cloud_init::set_install_pixi "${_middleware_json}" "${_version}" "${_user}"
      ;;
    sam)
      cloud_init::set_install_sam "${_middleware_json}" "${_version}" "${_user}"
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
$([[ -n "${_remote_mount_point}" ]] && cloud_init::set_mounted_repository_safe_config "${_user}" "${_remote_mount_point}")
$(cloud_init::set_vscode_extensions "${_user}" "${_vscode_extensions_json}")
$(cloud_init::set_bashrc "${_user}" "${_vscode_extensions_json}")
$(cloud_init::set_profile "${_user}")

runcmd:
$([[ -n "${_remote_mount_point}" ]] && cloud_init::set_mkdir_mount_point "${_remote_mount_point}" "${_user}")
$(cloud_init::set_install_packages "${_middleware_json}" "${_user}")
$(cloud_init::set_proto_install_packages "${_middleware_json}" "${_user}")
EOS
}
