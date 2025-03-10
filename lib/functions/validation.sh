#!/usr/bin/env bash

################################################################################
################################################################################
########### Super-Linter Validation Functions @admiralawkbar ###################
################################################################################
################################################################################
########################## FUNCTION CALLS BELOW ################################
################################################################################
################################################################################
#### Function GetValidationInfo ################################################
function GetValidationInfo() {
  ############################################
  # Print headers for user provided env vars #
  ############################################
  info "--------------------------------------------"
  info "Gathering user validation information..."

  ###########################################
  # Skip validation if were running locally #
  ###########################################
  if [[ ${RUN_LOCAL} != "true" ]]; then
    ###############################
    # Convert string to lowercase #
    ###############################
    VALIDATE_ALL_CODEBASE="${VALIDATE_ALL_CODEBASE,,}"
    ######################################
    # Validate we should check all files #
    ######################################
    if [[ ${VALIDATE_ALL_CODEBASE} != "false" ]]; then
      # Set to true
      VALIDATE_ALL_CODEBASE="${DEFAULT_VALIDATE_ALL_CODEBASE}"
      info "- Validating ALL files in code base..."
    else
      # Its false
      info "- Only validating [new], or [edited] files in code base..."
    fi
  fi

  ######################
  # Create Print Array #
  ######################
  PRINT_ARRAY=()

  ################################
  # Convert strings to lowercase #
  ################################
  # Loop through all languages
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    # build the variable
    VALIDATE_LANGUAGE="VALIDATE_${LANGUAGE}"
    # Set the value of the var to lowercase
    eval "${VALIDATE_LANGUAGE}=${!VALIDATE_LANGUAGE,,}"
  done

  # Loop through language packs to turn on any linters in those packs.
  for PACK in "${LANGUAGE_PACKS[@]}"; do
    LANGUAGES="${PACK}[@]"
    # Build the RUN_*_TOOLS variable
    RUN_LANGUAGE_PACK="RUN_${PACK}"

    for LANGUAGE in "${!LANGUAGES}"; do
      # Build the VALIDATE_* variable
      VALIDATE_LANGUAGE="VALIDATE_${LANGUAGE}"
      SHOULD_VALIDATE_LANGUAGE="SHOULD_${VALIDATE_LANGUAGE}"
      if [[ -n "${!VALIDATE_LANGUAGE}" ]]; then
        # If variable is explicitly set, that will override any language pack settings.
        continue
      fi
      # Should run current linter if *any* language pack flips it to true.
      if [[ "${!SHOULD_VALIDATE_LANGUAGE}" != "true" ]]; then
        eval "${SHOULD_VALIDATE_LANGUAGE}='${!RUN_LANGUAGE_PACK}'"
      fi
    done
  done

  # Loop through all languages.
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    # build the variable
    VALIDATE_LANGUAGE="VALIDATE_${LANGUAGE}"
    SHOULD_VALIDATE_LANGUAGE="SHOULD_${VALIDATE_LANGUAGE}"
    if [ -n "${!VALIDATE_LANGUAGE}" ]; then
      # If variable was explicitly set, honor that.
      continue
    else
      # Else use language pack settings to determine whether it should run.
      eval "${VALIDATE_LANGUAGE}='${!SHOULD_VALIDATE_LANGUAGE:-false}'; export ${VALIDATE_LANGUAGE}"
    fi
  done

  #######################################
  # Print which linters we are enabling #
  #######################################
  # Loop through all languages
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    # build the variable
    VALIDATE_LANGUAGE="VALIDATE_${LANGUAGE}"
    if [[ ${!VALIDATE_LANGUAGE} == "true" ]]; then
      # We need to validate
      PRINT_ARRAY+=("- Validating [${LANGUAGE}] files in code base...")

      debug "Defining variables for ${LANGUAGE} linter..."

      ERRORS_VARIABLE_NAME="ERRORS_FOUND_${LANGUAGE}"
      debug "Setting ${ERRORS_VARIABLE_NAME} variable value to 0..."
      eval "${ERRORS_VARIABLE_NAME}=0"
      debug "Exporting ${ERRORS_VARIABLE_NAME} variable..."
      eval "export ${ERRORS_VARIABLE_NAME}"
    else
      # We are skipping the language
      PRINT_ARRAY+=("- Excluding [$LANGUAGE] files in code base...")
    fi
  done

  ##############################
  # Validate Ansible Directory #
  ##############################
  # No Value, need to default
  if [ -z "${ANSIBLE_DIRECTORY}" ]; then

    if [ "${TEST_CASE_RUN}" != "true" ]; then
      ANSIBLE_DIRECTORY="${DEFAULT_ANSIBLE_DIRECTORY}"
      debug "Setting Ansible directory to the default: ${DEFAULT_ANSIBLE_DIRECTORY}"
    else
      ANSIBLE_DIRECTORY="${DEFAULT_TEST_CASE_ANSIBLE_DIRECTORY}"
      debug "Setting Ansible directory to the default for test cases: ${DEFAULT_TEST_CASE_ANSIBLE_DIRECTORY}"
    fi
    debug "Setting Ansible directory to: ${ANSIBLE_DIRECTORY}"
  else
    # Check if first char is '/'
    if [[ ${ANSIBLE_DIRECTORY:0:1} == "/" ]]; then
      # Remove first char
      ANSIBLE_DIRECTORY="${ANSIBLE_DIRECTORY:1}"
    fi

    if [ -z "${ANSIBLE_DIRECTORY}" ] || [[ ${ANSIBLE_DIRECTORY} == "." ]]; then
      # Catches the case where ANSIBLE_DIRECTORY="/" or ANSIBLE_DIRECTORY="."
      TEMP_ANSIBLE_DIRECTORY="${GITHUB_WORKSPACE}"
    else
      # Need to give it full path
      TEMP_ANSIBLE_DIRECTORY="${GITHUB_WORKSPACE}/${ANSIBLE_DIRECTORY}"
    fi

    # Set the value
    ANSIBLE_DIRECTORY="${TEMP_ANSIBLE_DIRECTORY}"
    debug "Setting Ansible directory to: ${ANSIBLE_DIRECTORY}"
  fi

  ###############################
  # Get the disable errors flag #
  ###############################
  if [ -z "${DISABLE_ERRORS}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    DISABLE_ERRORS="${DEFAULT_DISABLE_ERRORS}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  DISABLE_ERRORS="${DISABLE_ERRORS,,}"

  ############################
  # Set to false if not true #
  ############################
  if [ "${DISABLE_ERRORS}" != "true" ]; then
    DISABLE_ERRORS="false"
  fi

  ############################
  # Get the run verbose flag #
  ############################
  if [ -z "${ACTIONS_RUNNER_DEBUG}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    ACTIONS_RUNNER_DEBUG="${DEFAULT_ACTIONS_RUNNER_DEBUG}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG,,}"

  ############################
  # Set to true if not false #
  ############################
  if [ "${ACTIONS_RUNNER_DEBUG}" != "false" ]; then
    ACTIONS_RUNNER_DEBUG="true"
  fi

  ###########################
  # Print the validate info #
  ###########################
  for LINE in "${PRINT_ARRAY[@]}"; do
    debug "${LINE}"
  done

  debug "--- DEBUG INFO ---"
  debug "---------------------------------------------"
  RUNNER=$(whoami)
  debug "Runner:[${RUNNER}]"
  PRINTENV=$(printenv | sort)
  debug "ENV:"
  debug "${PRINTENV}"
  debug "---------------------------------------------"
}
