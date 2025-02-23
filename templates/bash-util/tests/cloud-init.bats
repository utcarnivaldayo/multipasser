#!/usr/bin/env bats

setup() {

  load "../lib/core.sh"
  load "../lib/logger.sh"
  load "../lib/validator.sh"
  load "../lib/cloud-init.sh"

  export HOSTNAME='server'
  export USER_NAME='hoge'
  export USER_PASSWORD='fuga'
  export SSH_AUTHORIZED_KEYS='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD'
  export REMOTE_MOUNT_POINT="/home/${USER_NAME}/mount-point"
  export MIDDLEWARE_JSON="./fixtures/middleware.json"
  export NO_MIDDLEWARE_JSON="./fixtures/no-middleware.json"
  export VSCODE_EXTENSIONS_JSON="./fixtures/extensions.json"
  export BACKUP_SUFFIX='.backup'
}

teardown() {
  echo
}

@test 'cloud_init::build_cloud_init with correct args' {

  local -a _build_cloud_init=()
  _build_cloud_init+=("${HOSTNAME}")
  _build_cloud_init+=("${USER_NAME}")
  _build_cloud_init+=("${USER_PASSWORD}")
  _build_cloud_init+=("${SSH_AUTHORIZED_KEYS}")
  _build_cloud_init+=("${MIDDLEWARE_JSON}")
  _build_cloud_init+=("${VSCODE_EXTENSIONS_JSON}")
  _build_cloud_init+=("${REMOTE_MOUNT_POINT}")
  local -ra _build_cloud_init

  command -v yq &>/dev/null || false
  run cloud_init::build_cloud_init "${_build_cloud_init[@]}"

  (( status == 0 )) || false
  yq . <<< "${output}" &>/dev/null || false
}

@test 'cloud_init::set_hostname with hoge' {

  command -v yq &>/dev/null || false
  run cloud_init::set_hostname "${HOSTNAME}"

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'hostname: server' ]] || false
}

@test 'cloud_init::set_hostname with empty' {

  command -v jq &>/dev/null || false
  run cloud_init::set_hostname ''

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_locale with ja_jp.utf-8' {

  local -r _locale='ja_JP.UTF-8'

  command -v yq &>/dev/null || false
  run cloud_init::set_locale "${_locale}"

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = "locale: ${_locale}" ]] || false
}

@test 'cloud_init::set_locale with en_us.utf-8' {

  local -r _locale='en_US.UTF-8'

  command -v yq &>/dev/null || false
  run cloud_init::set_locale "${_locale}"

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = "locale: ${_locale}" ]] || false
}

@test 'cloud_init::set_locale with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_locale 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_timezone with asia/tokyo' {

  local -r _timezone='Asia/Tokyo'

  command -v yq &>/dev/null || false
  run cloud_init::set_timezone "${_timezone}"

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = "timezone: ${_timezone}" ]] || false
}

@test 'cloud_init::set_timezone with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_timezone 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_ssh_pwauth with yes' {

  command -v yq &>/dev/null || false
  run cloud_init::set_ssh_pwauth 'yes'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'ssh_pwauth: yes' ]] || false
}

@test 'cloud_init::set_ssh_pwauth with no' {

  command -v yq &>/dev/null || false
  run cloud_init::set_ssh_pwauth 'no'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'ssh_pwauth: no' ]] || false
}

@test 'cloud_init::set_ssh_pwauth with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_ssh_pwauth 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_package_update with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_package_update 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_package_update with true' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_update 'true'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_update: true' ]] || false
}

@test 'cloud_init::set_package_update with false' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_update 'false'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_update: false' ]] || false
}

@test 'cloud_init::set_package_upgrade with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_package_upgrade 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_package_upgrade with true' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_upgrade 'true'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_upgrade: true' ]] || false
}

@test 'cloud_init::set_package_upgrade with false' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_upgrade 'false'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_upgrade: false' ]] || false
}

@test 'cloud_init::set_package_reboot_if_requred with true' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_reboot_if_requred 'true'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_reboot_if_requred: true' ]] || false
}

@test 'cloud_init::set_package_reboot_if_requred with false' {

  command -v yq &>/dev/null || false
  run cloud_init::set_package_reboot_if_requred 'false'

  (( status == 0 )) || false
  [[ "$(yq . <<< "${output}")" = 'package_reboot_if_requred: false' ]] || false
}

@test 'cloud_init::set_package_reboot_if_requred with hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_package_reboot_if_requred 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_apt_packages with no-middleware.json' {

  command -v jq &>/dev/null || false
  run cloud_init::set_apt_packages "${NO_MIDDLEWARE_JSON}"

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_apt_packages with middleware.json' {

  command -v yq &>/dev/null || false
  run cloud_init::set_apt_packages "${MIDDLEWARE_JSON}"

  (( status == 0 )) || false
  [[ "$(yq .packages <<< "${output}")" != '' ]] || false
}

@test 'cloud_init::set_snap_packages with no-middleware.json' {

  command -v jq &>/dev/null || false
  run cloud_init::set_snap_packages "${NO_MIDDLEWARE_JSON}"

  (( status == 1)) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_snap_packages with packages.json' {

  command -v yq &>/dev/null || false
  run cloud_init::set_snap_packages "${MIDDLEWARE_JSON}"

  (( status == 0 )) || false
  [[ "$(yq .snap <<< "${output}")" != '' ]] || false
}

@test 'cloud_init::set_user with lock password hoge' {

  command -v jq &>/dev/null || false
  run cloud_init::set_user "${USER_NAME}" 'hoge' "${SSH_AUTHORIZED_KEYS}"

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_use with lock password true' {

  command -v yq &>/dev/null || false
  run cloud_init::set_user "${USER_NAME}" 'true' "${SSH_AUTHORIZED_KEYS}"

  (( status == 0 )) || false
  [[ "$(yq .users <<< "${output}")" != '' ]] || false
}

@test 'cloud_init::set_use with lock password false' {

  command -v yq &>/dev/null || false
  run cloud_init::set_user "${USER_NAME}" 'false' "${SSH_AUTHORIZED_KEYS}"

  (( status == 0 )) || false
  [[ -n "$(yq .users <<< "${output}")" ]] || false
}

@test 'cloud_init::set_chpasswd with expire not bool' {

  command -v jq &>/dev/null || false
  run cloud_init::set_chpasswd "${USER_NAME}" "${USER_PASSWORD}" 'hoge'

  (( status == 1 )) || false
  [[ "$(jq -r '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'cloud_init::set_chpasswd with expire true' {

  command -v yq &>/dev/null || false
  run cloud_init::set_chpasswd "${USER_NAME}" "${USER_PASSWORD}" 'true'

  (( status == 0 )) || false
  [[ -n "$(yq '.chpasswd' <<< "${output}")" ]] || false
}

@test 'cloud_init::set_chpasswd with expire false' {

  command -v yq &>/dev/null || false
  run cloud_init::set_chpasswd "${USER_NAME}" "${USER_PASSWORD}" 'false'

  (( status == 0 )) || false
  [[ -n "$(yq '.chpasswd' <<< "${output}")" ]] || false
}

@test 'cloud_init::set_mounted_repository_safe_config with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_mounted_repository_safe_config "${USER_NAME}" "${REMOTE_MOUNT_POINT}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_bashrc with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_bashrc "${USER_NAME}" "${VSCODE_EXTENSIONS_JSON}"
  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_bashrc_initialize_vscode_extensions with correct args' {

  run cloud_init::set_bashrc_initialize_vscode_extensions "${USER_NAME}" "${VSCODE_EXTENSIONS_JSON}"

  (( status == 0 )) || false
  [[ -n "${output}" ]] || false
}

@test 'cloud_init::set_profile with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_profile "${USER_NAME}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_vscode_extensions with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_vscode_extensions "${USER_NAME}" "${VSCODE_EXTENSIONS_JSON}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_mkdir_mount_point with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_mkdir_mount_point "${REMOTE_MOUNT_POINT}" "${USER_NAME}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_install_docker with correct args' {

  local -r _version='1.0.0'
  run cloud_init::set_install_docker "${MIDDLEWARE_JSON}" "${_version}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_install_act with correct args' {

  local -r _version='1.0.0'

  command -v yq &>/dev/null || false
  run cloud_init::set_install_act "${MIDDLEWARE_JSON}" "${_version}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_install_minikube with correct args' {

  command -v yq &>/dev/null || false
  run cloud_init::set_install_minikube "${MIDDLEWARE_JSON}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}

@test 'cloud_init::set_install_kubectl with correct args' {

  local -r _version='1.0.0'

  command -v yq &>/dev/null || false
  run cloud_init::set_install_kubectl "${MIDDLEWARE_JSON}" "${_version}"

  (( status == 0 )) || false
  [[ -n "$(yq .[0] <<< "${output}")" ]] || false
}
