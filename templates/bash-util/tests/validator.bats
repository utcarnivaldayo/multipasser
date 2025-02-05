#!/usr/bin/env bats

setup() {

  export JSON_FILE="./fixtures/exists.json"
  export YAML_FILE="./fixtures/compose.yml"
  export TSV_FILE="./fixtures/exists.tsv"
  export CSV_FILE="./fixtures/exists.csv"

  load "../lib/core.sh"
  load "../lib/logger.sh"
  load "../lib/validator.sh"
}

teardown() {
  echo
}

@test 'validator::has_value with value' {

  run validator::has_value 'hoge'

  (( status == 0 )) || false
  [[ "${output}" == '' ]] || false
}

@test 'validator::has_value with empty' {

  command -v jq &>/dev/null || false
  run validator::has_value ''

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::has_value with warn level' {

  command -v jq &>/dev/null || false
  run validator::has_value '' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::has_value with warn level and csv format' {

  run validator::has_value '' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_alphanumeric with correct value' {

  run validator::is_alphanumeric 'aAzZ09'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_alphanumeric with incorrect value' {

  command -v jq &>/dev/null || false
  run validator::is_alphanumeric 'aAzZ09-'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_alphanumeric with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_alphanumeric 'aAzZ09-' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_alphanumeric with warn level and csv format' {

  run validator::is_alphanumeric 'aAzZ09-' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_alphabetic with correct value' {

  run validator::is_alphabetic 'aAzZ'

    (( status == 0 )) || false
    [[ "${output}" = '' ]] || false
}

@test 'validator::is_alphabetic with incorrect value' {

  command -v jq &>/dev/null || false
  run validator::is_alphabetic 'aAzZ09'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}


@test 'validator::is_alphabetic with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_alphabetic 'aAzZ09' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_alphabetic with warn level and csv format' {

  command -v jq &>/dev/null || false
  run validator::is_alphabetic 'aAzZ09' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_lower_kebab_case with correct value' {

  run validator::is_lower_kebab_case 'command-a-z-0-9'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_lower_kebab_case with prefix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_lower_kebab_case '-command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_kebab_case with sufix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_lower_kebab_case 'command-'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_kebab_case with prefix numeric' {

  command -v jq &>/dev/null || false
  run validator::is_lower_kebab_case '0command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_kebab_case with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_lower_kebab_case '-command' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_lower_kebab_case with warn level and csv format' {

  run validator::is_lower_kebab_case '-command' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_lower_snake_case with correct value' {

  run validator::is_lower_snake_case 'command_a_z_0_9'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_lower_snake_case with prefix underscore' {

  command -v jq &>/dev/null || false
  run validator::is_lower_snake_case '_command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_snake_case with sufix underscore' {

  command -v jq &>/dev/null || false
  run validator::is_lower_snake_case 'command_'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_snake_case with prefix numeric' {

  command -v jq &>/dev/null || false
  run validator::is_lower_snake_case '0command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_lower_snake_case with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_lower_snake_case '_command' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_lower_snake_case with warn level and csv format' {

  run validator::is_lower_snake_case '_command' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_upper_snake_case with correct value' {

  run validator::is_upper_snake_case 'COMMAND_A_Z_0_9'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_upper_snake_case with prefix underscore' {

  command -v jq &>/dev/null || false
  run validator::is_upper_snake_case '_COMMAND'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_upper_snake_case with sufix underscore' {

  command -v jq &>/dev/null || false
  run validator::is_upper_snake_case 'COMMAND_'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_upper_snake_case with prefix numeric' {

  command -v jq &>/dev/null || false
  run validator::is_upper_snake_case '0COMMAND'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_upper_snake_case with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_upper_snake_case '_COMMAND' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_upper_snake_case with warn level and csv format' {

  run validator::is_upper_snake_case '_COMMAND' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_rfc_1123 with correct value' {

  run validator::is_rfc_1123 'command-a-z-0-9'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_rfc_1123 with prefix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_rfc_1123 '-command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_rfc_1123 with sufix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_rfc_1123 'command-'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_rfc_1123 with prefix numeric' {

  run validator::is_rfc_1123 '0command'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_rfc_1123 with sufix numeric' {

  run validator::is_rfc_1123 'command0'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_rfc_1123 with 63 characters' {

  local -r _value='a123456789-0123456789-0123456789-0123456789-0123456789-01234567'
  run validator::is_rfc_1123 "${_value}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_rfc_1123 with 64 characters' {

  local -r _value='a123456789-0123456789-0123456789-0123456789-0123456789-012345678'
  run validator::is_rfc_1123 "${_value}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_rfc_1123 with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_rfc_1123 '-command' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_rfc_1123 with warn level and csv format' {

  run validator::is_rfc_1123 '-command' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_semantic_versioning with single digit' {

  run validator::is_semantic_versioning '1.2.3'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_semantic_versioning with multi digit' {

  run validator::is_semantic_versioning '11.22.33'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_semantic_versioning with alphabet' {

  command -v jq &>/dev/null || false
  run validator::is_semantic_versioning '1.y.z'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_interger with zero' {

  run validator::is_interger '0'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with positive single digit' {

  run validator::is_interger '1'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with negative single digit' {

  command -v jq &>/dev/null || false
  run validator::is_interger '-1'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with positive multi digit' {

  run validator::is_interger '1234567890'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with negative multi digit' {

  run validator::is_interger '-1234567890'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with positive zero' {

  command -v jq &>/dev/null || false
  run validator::is_interger '+0'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_interger with negative zero' {

  run validator::is_interger '-0'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_interger with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_interger 'hoge' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_interger with warn level and csv format' {

  run validator::is_interger 'hoge' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_positive_integer with zero' {

  run validator::is_positive_integer '0'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_positive_integer with positive single digit' {

  run validator::is_positive_integer '1'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_positive_integer with positive multi digit' {

  run validator::is_positive_integer '1234567890'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_positive_integer with positive zero' {

  command -v jq &>/dev/null || false
  run validator::is_positive_integer '+0'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_positive_integer with negative zero' {

  command -v jq &>/dev/null || false
  run validator::is_positive_integer '-0'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_positive_integer with negative single digit' {

  command -v jq &>/dev/null || false
  run validator::is_positive_integer '-1'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_positive_integer with negative multi digit' {

  command -v jq &>/dev/null || false
  run validator::is_positive_integer '-1234567890'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_positive_integer with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_positive_integer 'hoge' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_positive_integer with warn level and csv format' {

  run validator::is_positive_integer 'hoge' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_negative_integer with zero' {

  command -v jq &>/dev/null || false
  run validator::is_negative_integer '0'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_negative_integer with positive single digit' {

  command -v jq &>/dev/null || false
  run validator::is_negative_integer '1'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_negative_integer with positive multi digit' {

  command -v jq &>/dev/null || false
  run validator::is_negative_integer '1234567890'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_negative_integer with positive zero' {

  command -v jq &>/dev/null || false
  run validator::is_negative_integer '+0'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_negative_integer with negative zero' {

  run validator::is_negative_integer '-0'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_negative_integer with negative single digit' {

  run validator::is_negative_integer '-1'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_negative_integer with negative multi digit' {

  run validator::is_negative_integer '-1234567890'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::path_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  run validator::path_exists "${_file_path}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::path_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  run validator::path_exists "${_directory_path}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::path_exists with no exists path' {

  command -v jq &>/dev/null || false
  run validator::path_exists '/hoge/fuga'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::path_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::path_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::path_exists with warn level and csv format' {

  run validator::path_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::directory_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  command -v jq &>/dev/null || false
  run validator::directory_exists "${_file_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::directory_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  run validator::directory_exists "${_directory_path}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::directory_exists with no exists path' {

  command -v jq &>/dev/null || false
  run validator::directory_exists '/hoge/fuga'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::directory_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::directory_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::directory_exists with warn level and csv format' {

  run validator::directory_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::file_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  run validator::file_exists "${_file_path}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::file_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  command -v jq &>/dev/null || false
  run validator::file_exists "${_directory_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::file_exists with no exists path' {

  command -v jq &>/dev/null || false
  run validator::file_exists '/hoge/fuga'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::file_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::file_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::file_exists with warn level and csv format' {

  run validator::file_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::json_file_exists with json file' {

  run validator::json_file_exists "${JSON_FILE}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::json_file_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  command -v jq &>/dev/null || false
  run validator::json_file_exists "${_file_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::json_file_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  command -v jq &>/dev/null || false
  run validator::json_file_exists "${_directory_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::json_file_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::json_file_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::json_file_exists with warn level and csv format' {

  run validator::json_file_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::yaml_file_exists with yaml file' {

  run validator::yaml_file_exists "${YAML_FILE}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::yaml_file_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  command -v jq &>/dev/null || false
  run validator::yaml_file_exists "${_file_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::yaml_file_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  command -v jq &>/dev/null || false
  run validator::yaml_file_exists "${_directory_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::yaml_file_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::yaml_file_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::yaml_file_exists with warn level and csv format' {

  run validator::yaml_file_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::tsv_file_exists with tsv file' {

  command -v jq &>/dev/null || false
  run validator::tsv_file_exists "${YAML_FILE}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::tsv_file_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  run validator::tsv_file_exists "${_file_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::tsv_file_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  command -v jq &>/dev/null || false
  run validator::tsv_file_exists "${_directory_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::tsv_file_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::tsv_file_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::tsv_file_exists with warn level and csv format' {

  run validator::tsv_file_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::csv_file_exists with csv file' {

  run validator::csv_file_exists "${CSV_FILE}"

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::csv_file_exists with command path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  command -v jq &>/dev/null || false
  run validator::csv_file_exists "${_file_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::csv_file_exists with directory path' {

  local _file_path=''
  _file_path="$(command -v ls)"
  local -r _file_path

  local _directory_path=''
  _directory_path="$(dirname "${_file_path}")"
  local -r _directory_path

  command -v jq &>/dev/null || false
  run validator::csv_file_exists "${_directory_path}"

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::csv_file_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::csv_file_exists '/hoge/fuga' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::csv_file_exists with warn level and csv format' {

  run validator::csv_file_exists '/hoge/fuga' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::command_exists with command' {

  run validator::command_exists 'ls'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::command_exists with no exists command' {

  command -v jq &>/dev/null || false
  run validator::command_exists 'hoge'

  (( status == 1)) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::command_exists with warn level' {

  command -v jq &>/dev/null || false
  run validator::command_exists 'hoge' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::command_exists with warn level and csv format' {

  run validator::command_exists 'hoge' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< ${output})" = 'WARN' ]] || false
}

@test 'validator::is_command_name with correct value' {

  run validator::is_command_name '/usr/bin/command-a-z-0-9'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_command_name with prefix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_command_name '/usr/bin/-command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_command_name with sufix hyphen' {

  command -v jq &>/dev/null || false
  run validator::is_command_name '/usr/bin/command-'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_command_name with prefix numeric' {

  command -v jq &>/dev/null || false
  run validator::is_command_name '/usr/bin/0command'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}

@test 'validator::is_command_name with warn level' {

  command -v jq &>/dev/null || false
  run validator::is_command_name '/usr/bin/-command' 'warn'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_command_name with warn level and csv format' {

  run validator::is_command_name '/usr/bin/-command' 'warn' 'csv'

  (( status == 1 )) || false
  [[ "$(cut -d ',' -f 4 <<< "${output}")" = 'WARN' ]] || false
}

@test 'validator::is_ipv4 with correct value' {

  run validator::is_ipv4 '192.168.10.1'

  (( status == 0 )) || false
  [[ "${output}" = '' ]] || false
}

@test 'validator::is_ipv4 with incorrect value' {

  command -v jq &>/dev/null || false
  run validator::is_ipv4 '192.168.10.256'

  (( status == 1 )) || false
  [[ "$(jq -rc '.level' <<< "${output}")" = 'ERROR' ]] || false
}
