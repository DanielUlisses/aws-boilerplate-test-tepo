#!/bin/bash

set -e

declare -A ENVIRONMENT_PARAMS

function exit_with_msg {
  echo "${1}"
  exit 1
}

function validate_environment_params {
  local ENVIRONMENT="${1}"
  local REQUIRED_PARAMS=()
  echo "Validating environment '${ENVIRONMENT}'..."

  for PARAM in "${REQUIRED_PARAMS[@]}"; do
    [ -z "${ENVIRONMENT_PARAMS["${PARAM}-${ENVIRONMENT}"]}" ] && exit_with_msg "Error: Missing '${PARAM}' parameter for environment '${ENVIRONMENT}'."
  done
    [ -z "${ENVIRONMENT_PARAMS["tag-pattern-${ENVIRONMENT}"]}" ] || CONDITION="if: github.ref_type == 'tag' && contains(github.ref_name, '${TAG_PATTERN}')"
}

while [ $# -gt 0 ]; do
  case "${1}" in
    -c|--clean)
      CLEAN="${2}"
      shift 2
      ;;
    -e|--environments)
      ENVIRONMENTS+=("${2}")
      shift 2
        while [ "${1}" != "--" ] && [ $# -gt 0 ]; do
          case "${1}" in
            --tag-pattern-*)
              ENVIRONMENT_PARAMS["${1#--}"]="${2}"
              shift 2
              ;;
            *)
              break
          esac
        done
      if [ "${1}" == "--" ]; then
        shift
      fi
      ;;
    -g|--go-version)
      GO_VERSION="${2}"
      shift 2
      ;;
    -h|--help)
      echo "Usage:"
      echo "$0 \\"
      echo "  [-c|--clean <true|false>]"
      echo "  [-g|--go-version <go_version>]"
      echo "  [-h|--help]"
      echo "  [-tf|--terraform-version <terraform_version>]"
      echo "  [-tg|--terragrunt-version <terragrunt_version>]"
      echo "  -e|--environments <environment_name> [-- <environment_params>]"
      echo "Environment parameters:"
      echo "  --tag-pattern-<environment_name>: Tag pattern for conditional <environment_name>."
      exit 0
      ;;
    -tf|--terraform-version)
      TF_VERSION="${2}"
      shift 2
      ;;
    -tg|--terragrunt-version)
      TG_VERSION="${2}"
      shift 2
      ;;
    *)
      echo "Error: Invalid argument '${1}'."
      shift
  esac
done

PREFIX=$(cat aws.yaml | grep ^prefix | awk -F '[: #"]+' '{print $2}')

[[ -z ${ENVIRONMENTS} ]] && exit_with_msg "-e|--environments is a required parameter. Exiting."
[[ -z ${CLEAN} ]] && CLEAN='false'
[[ -z ${GO_VERSION} ]] && GO_VERSION='1.19.4'
[[ -z ${TF_VERSION} ]] && TF_VERSION='1.3.9'
[[ -z ${TG_VERSION} ]] && TG_VERSION='0.45.4'

echo "Setup Deployment containers"
echo "Go Version: ${GO_VERSION}"
echo "Terraform Version: ${TF_VERSION}"
echo "Terragrunt Version: ${TG_VERSION}"
echo ""

if [ "${CLEAN}" == "true" ]; then
  echo "Cleaning up existing environments..."
  cp templates/actions.yaml actions.yaml

fi

for ENVIRONMENT in "${ENVIRONMENTS[@]}"; do
  echo ""
  validate_environment_params "${ENVIRONMENT}"
  TAG_PATTERN=${ENVIRONMENT_PARAMS["tag-pattern-${ENVIRONMENT}"]}
  [[ -z ${TAG_PATTERN} ]] || CONDITION="if: github.ref_type == 'tag' && contains(github.ref_name, '${TAG_PATTERN}')"

  echo "Environment: ${ENVIRONMENT}"
  echo "Prefix: ${PREFIX}"
  # Create a copy of the environment for each -e parameter
  echo "Creating environment '${ENVIRONMENT}'..."
  # Deployment Pipelines
  cp -r templates/config-deploy-job.yaml config-deploy-job-${ENVIRONMENT}.yaml
  sed -i -e "s:ENVIRONMENT:${ENVIRONMENT}:g" config-deploy-job-${ENVIRONMENT}.yaml
  sed -i -e "s:GO_VERSION:${GO_VERSION}:g" config-deploy-job-${ENVIRONMENT}.yaml
  sed -i -e "s:TF_VERSION:${TF_VERSION}:g" config-deploy-job-${ENVIRONMENT}.yaml
  sed -i -e "s:TG_VERSION:${TG_VERSION}:g" config-deploy-job-${ENVIRONMENT}.yaml
  [[ -z ${TAG_PATTERN} ]] && sed -i "/CONDITION/d" config-deploy-job-${ENVIRONMENT}.yaml || sed -i -e "s|CONDITION|${CONDITION}|g" config-deploy-job-${ENVIRONMENT}.yaml
  cat config-deploy-job-${ENVIRONMENT}.yaml >> actions.yaml

done
