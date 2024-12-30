setup() {

  export REPOSITORY_ROOT=''
  REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"

  export REPOSITORY_NAME=''
  REPOSITORY_NAME="$(basename "${REPOSITORY_ROOT}")"
  load "${REPOSITORY_ROOT}/workspaces/multipass/lib/core.sh"
}

teardown() {
  echo
}

@test 'core::monorepo_root with success' {

  run core::monorepo_root
  (( status == 0 )) || false
  [[ "${output}" = "${REPOSITORY_ROOT}" ]] || false
}

@test 'core::monorepo_name with success' {

  run core::monorepo_name
  (( status == 0 )) || false
  [[ "${output}" = "${REPOSITORY_NAME}" ]] || false
}

@test 'core::rfc_3339 with success' {

  run core::rfc_3339
  (( status == 0 )) || false
  [[ "${output}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[\+\-][0-9]{2}:[0-9]{2}$ ]] || false
}

@test 'core::hostname with success' {

  run core::hostname
  (( status == 0 )) || false
  [[ "${output}" =~ ^[a-zA-Z0-9\.\_\-]+$ ]] || false
}

@test 'core::target_triple with success' {

  run core::target_triple
  (( status == 0 )) || false
  [[ "${output}" =~ ^[_a-z0-9]+[-][-a-z0-9]+$ ]] || false
}
