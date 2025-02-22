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

function devcontainer::install_aws_cli_v2() {
  local -r _middleware_json="${1:-}"
  local -r _aws_cli_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_aws_cli_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
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

  cd "${_home}" || return 1
  local -r _install_zip_url="https://awscli.amazonaws.com/awscli-exe-linux-${_cpu_type}.zip"
  curl --proto '=https' --tlsv1.2 -sSfL "${_install_zip_url}" -o awscliv2.zip
  unzip awscliv2.zip
  ./aws/install
}

function devcontainer::install_bats_core() {
  local -r _middleware_json="${1:-}"
  local -r _bats_core_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_bats_core_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("git")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  mkdir -p "${_home}/bin"
  git clone -b "v${_bats_core_version}" --single-branch --depth=1 'https://github.com/bats-core/bats-core.git'
  cd "${_home}/bats-core" || return 1
  sudo bash ./install.sh /usr/local
  cd "${_home}" || return 1
  rm -rf "bats-core" || :
}

function devcontainer::install_proto() {
  local -r _middleware_json="${1:-}"
  local -r _proto_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"
  local -r _proto_url='https://moonrepo.dev/install/proto.sh'

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_proto_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

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

  cd "${_home}" || return 1
  curl --proto '=https' --tlsv1.2 -sSfL "${_proto_url}" | bash -s -- "${_proto_version}" --yes --no-profile
  echo "export PROTO_HOME=${_home}/.proto" >> "${_home}/.bashrc"
  echo "export PATH=${_home}/.proto/shims:${_home}/.proto/bin:\$PATH" >> "${_home}/.bashrc"
}

function devcontainer::install_radicle() {
  local -r _middleware_json="${1:-}"
  local -r _radicle_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"
  local -r _radicle_url='https://radicle.xyz/install'

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_radicle_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  curl --proto '=https' --tlsv1.2 -sSfL "${_radicle_url}" \
    | bash -s -- --prefix="${_home}/.radicle" --version="${_radicle_version}"
}

function devcontainer::install_kind() {
  local -r _middleware_json="${1:-}"
  local -r _kind_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

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

  cd "${_home}" || return 1
  local -r _bin_url="https://kind.sigs.k8s.io/dl/v${_kind_version}/kind-linux-${_cpu_type}"
  curl --proto '=https' --tlsv1.2 -sSfL "${_bin_url}" -o "${_home}/kind"
  chmod a+x "${_home}/kind"
  sudo mv "${_home}/kind" /usr/local/bin/kind
}

function devcontainer::install_ctlptl() {
  local -r _middleware_json="${1:-}"
  local -r _ctlptl_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

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

  cd "${_home}" || return 1
  local -r _download_url="https://github.com/tilt-dev/ctlptl/releases/download"
  local -r _tar_url="${_download_url}/v${_ctlptl_version}/ctlptl.${_ctlptl_version}.linux.${_cpu_type}.tar.gz"
  curl --proto '=https' --tlsv1.2 -sSfL "${_tar_url}" | sudo tar -xzv -C /usr/local/bin ctlptl
}

function devcontainer::install_opentofu() {
  local -r _middleware_json="${1:-}"
  local -r _opentofu_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"
  local -r _opentofu_installer='install-opentofu.sh'
  local -r _opentofu_url="https://get.opentofu.org/${_opentofu_installer}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_opentofu_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  curl --proto '=https' --tlsv1.2 -fsSL "${_opentofu_url}" -o "${_opentofu_installer}"
  chmod a+x install-opentofu.sh
  bash install-opentofu.sh --install-method standalone --opentofu-version "${_opentofu_version}"
  rm -f "${_opentofu_installer}"
}

function devcontainer::install_stripe_cli() {
  local -r _middleware_json="${1:-}"
  local -r _stripe_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_stripe_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
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

  cd "${_home}" || return 1
  local -r _download_url='https://github.com/stripe/stripe-cli/releases/download'
  local -r _tar_url="${_download_url}/v${_stripe_version}/stripe_${_stripe_version}_linux_${_cpu_type}.tar.gz"
  curl --proto '=https' --tlsv1.2 -sSfL "${_tar_url}" | tar -xzv stripe
  sudo mv stripe /usr/local/bin/stripe
}

function devcontainer::install_duckdb() {

  local -r _middleware_json="${1:-}"
  local -r _duckdb_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

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

  cd "${_home}" || return 1
  local -r _download_url='https://github.com/duckdb/duckdb/releases/download'
  local -r _zip_url="${_download_url}/v${_duckdb_version}/duckdb_cli-linux-${_cpu_type}.zip"
  curl --proto '=https' --tlsv1.2 -sSfL "${_zip_url}" -o "${_home}/duckdb.zip"
  unzip "${_home}/duckdb.zip"
  sudo mv "${_home}/duckdb" /usr/local/bin
  rm "${_home}/duckdb.zip"
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

function devcontainer::install_pixi() {
  local -r _middleware_json="${1:-}"
  local -r _pixi_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_pixi_version}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if [[ "$(jq -r '.apt | has("curl")' "${_middleware_json}")" = 'false' ]]; then
    logger::error "required curl in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  curl --proto '=https' --tlsv1.2 -sSfL https://pixi.sh/install.sh | PIXI_VERSION="v${_pixi_version}" bash
}

function devcontainer::install_sam() {

  local -r _middleware_json="${1:-}"
  local -r _sam_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

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

  cd "${_home}" || return 1
  local -r _download_url='https://github.com/aws/aws-sam-cli/releases/download'
  local -r _zip_url="${_download_url}/v${_sam_version}/aws-sam-cli-linux-${_cpu_type}.zip"
  curl --proto '=https' --tlsv1.2 -sSfL "${_zip_url}" -o "${_home}/aws-sam-cli.zip"
  unzip "${_home}/aws-sam-cli.zip" -d "${_home}/sam-installation"
  sudo "${_home}/sam-installation/install"
  rm "${_home}/aws-sam-cli.zip"
}

function devcontainer::proto_install_bun() {
  local -r _middleware_json="${1:-}"
  local -r _bun_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_bun_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  ~/.proto/bin/proto install bun "${_bun_version}"
}

function devcontainer::proto_install_deno() {
  local -r _middleware_json="${1:-}"
  local -r _deno_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_deno_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  ~/.proto/bin/proto install deno "${_deno_version}"
}

function devcontainer::proto_install_go() {
  local -r _middleware_json="${1:-}"
  local -r _go_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_go_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1

  # dependency check
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  ~/.proto/bin/proto install go "${_go_version}"
}

function devcontainer::proto_install_node() {
  local -r _middleware_json="${1:-}"
  local -r _node_version="${2:-}"
  local -r _user="${3:-}"
  local -r _home="/home/${_user}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::is_semantic_versioning "${_node_version}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1

  # dependency check
  validator::command_exists 'jq' >&2 || return 1
  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  cd "${_home}" || return 1
  ~/.proto/bin/proto install node "${_node_version}"
}

function devcontainer::proto_install_npm() {
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

  ~/.proto/bin/proto install npm "${_npm_version}"
}

function devcontainer::proto_install_pnpm() {
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

  ~/.proto/bin/proto install pnpm "${_pnpm_version}"
}

function devcontainer::set_proto_install_rust() {
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

  ~/.proto/bin/proto install rust "${_rust_version}"
}

function devcontainer::proto_install_yarn() {
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

  ~/.proto/bin/proto install yarn "${_yarn_version}"
}

function devcontainer::proto_install_act() {
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
  ~/.proto/bin/proto plugin add act "${_toml_plugin}"
  ~/.proto/bin/proto install act "${_act_version}"
}

function devcontainer::proto_install_actionlint() {
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
  ~/.proto/bin/proto plugin add actionlint "${_toml_plugin}"
  ~/.proto/bin/proto install actionlint "${_actionlint_version}"
}

function devcontainer::proto_install_argo() {
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
  ~/.proto/bin/proto plugin add argo "${_toml_plugin}"
  ~/.proto/bin/proto install argo "${_argo_version}"
}

function devcontainer::proto_install_argocd() {
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
  ~/.proto/bin/proto plugin add argocd "${_toml_plugin}"
  ~/.proto/bin/proto install argocd "${_argocd_version}"
}

function devcontainer::proto_install_biome() {
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
  ~/.proto/bin/proto plugin add biome "${_toml_plugin}"
  ~/.proto/bin/proto install biome "${_biome_version}"
}

function devcontainer::proto_install_direnv() {
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
  ~/.proto/bin/proto plugin add direnv "${_toml_plugin}"
  ~/.proto/bin/proto install direnv "${_direnv_version}"
}

function devcontainer::proto_install_dprint() {
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
  ~/.proto/bin/proto plugin add dprint "${_toml_plugin}"
  ~/.proto/bin/proto install dprint "${_dprint_version}"
}

function devcontainer::proto_install_gh() {
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
  ~/.proto/bin/proto plugin add gh "${_toml_plugin}"
  ~/.proto/bin/proto install gh "${_gh_version}"
}

function devcontainer::proto_install_helm() {
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
  ~/.proto/bin/proto plugin add helm "${_toml_plugin}"
  ~/.proto/bin/proto install helm "${_helm_version}"
}

function devcontainer::proto_install_helmfile() {
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
  ~/.proto/bin/proto plugin add helmfile "${_toml_plugin}"
  ~/.proto/bin/proto install helmfile "${_helmfile_version}"
}

function devcontainer::proto_install_infisical() {
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
  ~/.proto/bin/proto plugin add infisical "${_toml_plugin}"
  ~/.proto/bin/proto install infisical "${_infisical_version}"
}

function devcontainer::proto_install_jira_cli() {
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
  ~/.proto/bin/proto plugin add jira "${_toml_plugin}"
  ~/.proto/bin/proto install jira "${_jira_cli_version}"
}

function devcontainer::proto_install_jq() {
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
  ~/.proto/bin/proto plugin add jq "${_toml_plugin}"
  ~/.proto/bin/proto install jq "${_jq_version}"
}

function devcontainer::proto_install_k3d() {
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
  ~/.proto/bin/proto plugin add k3d "${_toml_plugin}"
  ~/.proto/bin/proto install k3d "${_k3d_version}"
}

function devcontainer::proto_install_kubectl() {
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
  ~/.proto/bin/proto plugin add kubectl "${_toml_plugin}"
  ~/.proto/bin/proto install kubectl "${_kubectl_version}"
}

function devcontainer::proto_install_mise() {
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
  ~/.proto/bin/proto plugin add mise "${_toml_plugin}"
  ~/.proto/bin/proto install mise "${_mise_version}"
}

function devcontainer::proto_install_moon() {
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
  ~/.proto/bin/proto plugin add moon "${_toml_plugin}"
  ~/.proto/bin/proto install moon "${_moon_version}"
}

function devcontainer::proto_install_shellcheck(){
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
  ~/.proto/bin/proto plugin add shellcheck "${_toml_plugin}"
  ~/.proto/bin/proto install shellcheck "${_shellcheck_version}"
}

function devcontainer::proto_install_shfmt(){
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
  ~/.proto/bin/proto plugin add shfmt "${_toml_plugin}"
  ~/.proto/bin/proto install shfmt "${_shfmt_version}"
}

function devcontainer::proto_install_sops(){
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
  ~/.proto/bin/proto plugin add sops "${_toml_plugin}"
  ~/.proto/bin/proto install sops "${_sops_version}"
}

function devcontainer::proto_install_tilt(){
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
  ~/.proto/bin/proto plugin add tilt "${_toml_plugin}"
  ~/.proto/bin/proto install tilt "${_tilt_version}"
}

function devcontainer::proto_install_yq(){
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
  ~/.proto/bin/proto plugin add yq "${_toml_plugin}"
  ~/.proto/bin/proto install yq "${_yq_version}"
}

function devcontainer::proto_install_zig(){
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
  ~/.proto/bin/proto plugin add zig "${_toml_plugin}"
  ~/.proto/bin/proto install zig "${_zig_version}"
}

function devcontainer::proto_install_packages() {
  local -r _middleware_json="${1:-}"
  local -r _user="${2:-}"

  validator::json_file_exists "${_middleware_json}" >&2 || return 1
  validator::has_value "${_user}" >&2 || return 1
  validator::command_exists 'jq' >&2 || return 1
  validator::command_exists 'tr' >&2 || return 1

  if ! jq -r '.runcmd | has("proto")' "${_middleware_json}" | grep -q 'true'; then
    logger::error "required proto in middleware.json (${_middleware_json})" >&2
    return 1
  fi

  local _version=''
  local _formatted_package=''
  while read -r _package; do
    _formatted_package="$(echo "${_package}" | tr -d '\r')"
    _version="$(jq -r --arg package "${_formatted_package}" '.proto[$package]' "${_middleware_json}")"
    [[ -z "${_version}" ]] && continue
    case "${_formatted_package}" in
    act)
      devcontainer::proto_install_act "${_middleware_json}" "${_version}" "${_user}"
      ;;
    actionlint)
      devcontainer::proto_install_actionlint "${_middleware_json}" "${_version}" "${_user}"
      ;;
    argo)
      devcontainer::proto_install_argo "${_middleware_json}" "${_version}" "${_user}"
      ;;
    argocd)
      devcontainer::proto_install_argocd "${_middleware_json}" "${_version}" "${_user}"
      ;;
    biome)
      devcontainer::proto_install_biome "${_middleware_json}" "${_version}" "${_user}"
      ;;
    direnv)
      devcontainer::proto_install_direnv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    dprint)
      devcontainer::proto_install_dprint "${_middleware_json}" "${_version}" "${_user}"
      ;;
    gh)
      devcontainer::proto_install_gh "${_middleware_json}" "${_version}" "${_user}"
      ;;
    helm)
      devcontainer::proto_install_helm "${_middleware_json}" "${_version}" "${_user}"
      ;;
    helmfile)
      devcontainer::proto_install_helmfile "${_middleware_json}" "${_version}" "${_user}"
      ;;
    infisical)
      devcontainer::proto_install_infisical "${_middleware_json}" "${_version}" "${_user}"
      ;;
    jira_cli)
      devcontainer::proto_install_jira_cli "${_middleware_json}" "${_version}" "${_user}"
      ;;
    jq)
      devcontainer::proto_install_jq "${_middleware_json}" "${_version}" "${_user}"
      ;;
    k3d)
      devcontainer::proto_install_k3d "${_middleware_json}" "${_version}" "${_user}"
      ;;
    kubectl)
      devcontainer::proto_install_kubectl "${_middleware_json}" "${_version}" "${_user}"
      ;;
    mise)
      devcontainer::proto_install_mise "${_middleware_json}" "${_version}" "${_user}"
      ;;
    moon)
      devcontainer::proto_install_moon "${_middleware_json}" "${_version}" "${_user}"
      ;;
    shellcheck)
      devcontainer::proto_install_shellcheck "${_middleware_json}" "${_version}" "${_user}"
      ;;
    shfmt)
      devcontainer::proto_install_shfmt "${_middleware_json}" "${_version}" "${_user}"
      ;;
    sops)
      devcontainer::proto_install_sops "${_middleware_json}" "${_version}" "${_user}"
      ;;
    tilt)
      devcontainer::proto_install_tilt "${_middleware_json}" "${_version}" "${_user}"
      ;;
    yq)
      devcontainer::proto_install_yq "${_middleware_json}" "${_version}" "${_user}"
      ;;
    zig)
      devcontainer::proto_install_zig "${_middleware_json}" "${_version}" "${_user}"
      ;;
    *)
      return 1
      ;;
    esac
  done < <(jq -r '.proto | to_entries[] | .key' "${_middleware_json}")
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
    kind)
      devcontainer::install_kind "${_middleware_json}" "${_version}" "${_user}"
      ;;
    aws_cli)
      devcontainer::install_aws_cli_v2 "${_middleware_json}" "${_version}" "${_user}"
      ;;
    opentofu)
      devcontainer::install_opentofu "${_middleware_json}" "${_version}" "${_user}"
      ;;
    ctlptl)
      devcontainer::install_ctlptl "${_middleware_json}" "${_version}" "${_user}"
      ;;
    stripe_cli)
      devcontainer::install_stripe_cli "${_middleware_json}" "${_version}" "${_user}"
      ;;
    radicle)
      devcontainer::install_radicle "${_middleware_json}" "${_version}" "${_user}"
      ;;
    bats_core)
      devcontainer::install_bats_core "${_middleware_json}" "${_version}" "${_user}"
      ;;
    proto)
      devcontainer::install_proto "${_middleware_json}" "${_version}" "${_user}"
      ;;
    duckdb)
      devcontainer::install_duckdb "${_middleware_json}" "${_version}" "${_user}"
      ;;
    lltsv)
      devcontainer::install_lltsv "${_middleware_json}" "${_version}" "${_user}"
      ;;
    pixi)
      devcontainer::install_pixi "${_middleware_json}" "${_version}" "${_user}"
      ;;
    sam)
      devcontainer::install_sam "${_middleware_json}" "${_version}" "${_user}"
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
