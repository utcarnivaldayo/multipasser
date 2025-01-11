#!/usr/bin/env bats

setup() {
  load "../lib/core.sh"
  load "../lib/logger.sh"
}

teardown() {
  echo
}

@test 'logger::print_level with lower trace' {

  logger::set_default_config
  run logger::print_level 'trace'
  (( status == 0 )) || false
  [[ "${output}" = 'TRACE' ]] || false
}

@test 'logger::print_level with upper trace' {

  logger::set_default_config
  run logger::print_level 'TRACE'
  (( status == 0 )) || false
  [[ "${output}" = 'TRACE' ]] || false
}

@test 'logger::print_levelwith lower debug' {

  logger::set_default_config
  run logger::print_level 'debug'
  (( status == 0 )) || false
  [[ "${output}" = 'DEBUG' ]] || false
}

@test 'logger::print_level with upper debug' {

  logger::set_default_config
  run logger::print_level 'DEBUG'
  (( status == 0 )) || false
  [[ "${output}" = 'DEBUG' ]] || false
}

@test 'logger::print_level with lower info' {

  logger::set_default_config
  run logger::print_level 'info'
  (( status == 0 )) || false
  [[ "${output}" = 'INFO' ]] || false
}

@test 'logger::print_level with upper info' {

  logger::set_default_config
  run logger::print_level 'INFO'
  (( status == 0 )) || false
  [[ "${output}" = 'INFO' ]] || false
}

@test 'logger::print_level with lower information' {

  logger::set_default_config
  run logger::print_level 'information'
  (( status == 0 )) || false
  [[ "${output}" = 'INFO' ]] || false
}

@test 'logger::print_level with upper information' {

  logger::set_default_config
  run logger::print_level 'INFORMATION'
  (( status == 0 )) || false
  [[ "${output}" = 'INFO' ]] || false
}

@test 'logger::print_level with lower warn' {

  logger::set_default_config
  run logger::print_level 'warn'
  (( status == 0 )) || false
  [[ "${output}" = 'WARN' ]] || false
}

@test 'logger::print_levelwith upper warn' {

  logger::set_default_config
  run logger::print_level 'WARN'
  (( status == 0 )) || false
  [[ "${output}" = 'WARN' ]] || false
}

@test 'logger::print_level with lower warning' {

  logger::set_default_config
  run logger::print_level 'warning'
  (( status == 0 )) || false
  [[ "${output}" = 'WARN' ]] || false
}

@test 'logger::print_level with upper warning' {

  logger::set_default_config
  run logger::print_level 'WARNING'
  (( status == 0 )) || false
  [[ "${output}" = 'WARN' ]] || false
}

@test 'logger::print_level with lower error' {

  logger::set_default_config
  run logger::print_level 'error'
  (( status == 0 )) || false
  [[ "${output}" = 'ERROR' ]] || false
}

@test 'logger::print_level with upper error' {

  logger::set_default_config
  run logger::print_level 'ERROR'
  (( status == 0 )) || false
  [[ "${output}" = 'ERROR' ]] || false
}


@test 'logger::print_level with lower fatal' {

  logger::set_default_config
  run logger::print_level 'fatal'
  (( status == 0 )) || false
  [[ "${output}" = 'FATAL' ]] || false
}

@test 'logger::print_level with upper fatal' {

  logger::set_default_config
  run logger::print_level 'FATAL'
  (( status == 0 )) || false
  [[ "${output}" = 'FATAL' ]] || false
}

@test 'logger::print_level with unexpected level' {

  logger::set_default_config
  run logger::print_level 'hoge'
  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::log_json 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'INFO' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::log_json with plane message and error level' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::log_json 'hoge' 'error'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::log_json with plane message and unexpected level' {

  logger::set_default_config

  run logger::log_json 'hoge' 'fuga'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with print trace off' {

  logger::set_default_config
  LOGGER_PRINT_TRACE='false'

  run logger::log_json 'hoge' 'trace'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with print info off' {

  logger::set_default_config
  LOGGER_PRINT_INFO='false'

  run logger::log_json 'hoge' 'info'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with print warn off' {

  logger::set_default_config
  LOGGER_PRINT_WARN='false'

  run logger::log_json 'hoge' 'warn'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with print error off' {

  logger::set_default_config
  LOGGER_PRINT_ERROR='false'

  run logger::log_json 'hoge' 'error'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_json with print fatal off' {

  logger::set_default_config
  LOGGER_PRINT_FATAL='false'

  run logger::log_json 'hoge' 'fatal'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_tsv with plane message' {

  logger::set_default_config

  run logger::log_tsv 'hoge'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'INFO' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log_tsv with plane message and error level' {

  logger::set_default_config

  run logger::log_tsv 'hoge' 'error'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log_tsv with plane message and unexpected level' {

  logger::set_default_config
  run logger::log_tsv 'hoge' 'fuga'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log_csv with plane message' {

  logger::set_default_config

  run logger::log_csv 'hoge'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'INFO' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log_csv with plane message and error level' {

  logger::set_default_config

  run logger::log_csv 'hoge' 'error'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log_csv with plane message and unexpected level' {

  logger::set_default_config

  run logger::log_csv 'hoge' 'fuga'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::log 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'INFO' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::log with plane message and error level' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::log 'hoge' 'error'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}


@test 'logger::log with plane message and unexpected level' {

  logger::set_default_config

  run logger::log 'hoge' 'fuga'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log with tsv format' {

  logger::set_default_config

  run logger::log 'hoge' 'error' 'tsv'

  (( status == 0)) || false
  [[ "$(cut -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log with csv format' {

  logger::set_default_config

  run logger::log 'hoge' 'error' 'csv'

  (( status == 0)) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::log with unexpected format' {

  logger::set_default_config

  run logger::log 'message' 'error' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::log with unexpected format and error level' {

  logger::set_default_config

  run logger::log 'message' 'fuga' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::trace with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false
  run logger::trace 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'TRACE' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::trace with tsv format' {

  logger::set_default_config
  run logger::trace 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'TRACE' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::trace with csv format' {

  logger::set_default_config
  run logger::trace 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'TRACE' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::trace with unexpected format' {

  logger::set_default_config
  run logger::trace 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::debug with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::debug 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'DEBUG' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::debug with tsv format' {

  logger::set_default_config

  run logger::debug 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'DEBUG' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::debug with csv format' {

  logger::set_default_config

  run logger::debug 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'DEBUG' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::debug with unexpected format' {

  logger::set_default_config

  run logger::debug 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::info with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::info 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'INFO' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::info with tsv format' {

  logger::set_default_config

  run logger::info 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'INFO' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::info with csv format' {

  logger::set_default_config

  run logger::info 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'INFO' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::info with unexpected format' {

  logger::set_default_config

  run logger::info 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::warn with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::warn 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::warn with tsv format' {

  logger::set_default_config

  run logger::warn 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'WARN' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::warn with csv format' {

  logger::set_default_config

  run logger::warn 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::warn with unexpected format' {

  logger::set_default_config

  run logger::warn 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::error with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::error 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::error with tsv format' {

  logger::set_default_config

  run logger::error 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::error with csv format' {

  logger::set_default_config

  run logger::error 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'ERROR' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::error with unexpected format' {

  logger::set_default_config

  run logger::error 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::fatal with plane message' {

  logger::set_default_config
  command -v 'jq' &>/dev/null || false

  run logger::fatal 'hoge'

  (( status == 0 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'FATAL' ]] || false
  [[ "$(jq -rc '.message' <<< "${output}")" = 'hoge' ]] || false
}

@test 'logger::fatal with tsv format' {

  logger::set_default_config

  run logger::fatal 'hoge' 'tsv'

  (( status == 0 )) || false
  [[ "$(cut -f 4 <<< ${output})" = 'FATAL' ]] || false
  [[ "$(cut -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::fatal with csv format' {

  logger::set_default_config

  run logger::fatal 'hoge' 'csv'

  (( status == 0 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'FATAL' ]] || false
  [[ "$(cut -d ',' -f 5 <<< ${output})" = 'hoge' ]] || false
}

@test 'logger::fatal with unexpected format' {

  logger::set_default_config
  run logger::fatal 'hoge' 'hoge'

  (( status == 1 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'logger::header_tsv' {

  logger::set_default_config
  local -r _expected_header='datetime\tserver\ttarget_triple\tlevel\tmessage'
  run logger::header_tsv
  (( status == 0 )) || false
  [[ "${output}" = "$(echo -e "${_expected_header}")" ]] || false
}

@test 'logger::header_csv' {

  logger::set_default_config
  local -r _expected_header='datetime,server,target_triple,level,message'

  run logger::header_csv

  (( status == 0 )) || false
  [[ "${output}" = "$(echo "${_expected_header}")" ]] || false
}
