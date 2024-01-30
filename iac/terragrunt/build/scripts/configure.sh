#!/bin/bash

set -e

function exit_with_msg {
  echo "${1}"
  exit 1
}

while [ $# -gt 0 ]; do
  case "${1}" in
    -a|--approvers)
      APPROVERS="${2}"
      shift
      ;;
    -e|--environment)
      ENVIRONMENT="${2}"
      shift
      ;;
    -i|--account-id)
      ACCOUNT_ID="${2}"
      shift
      ;;
    -h|--help)
      echo "Usage:"
      echo "$0 \\"
      echo "  [-h|--help]"
      echo "  [-r|--regions <primaryregion>[,<secondaryregion>]]"
      echo "  -a|--approvers <approver_arn>"
      echo "  -e|--environment <environment_name>"
      echo "  -i|--account-id <account_id>"
      exit 0
      ;;
    -r|--regions)
      REG_PRIMARY=`awk -F',' '{print $1}' <<< ${2}`
      REG_SECONDARY=`awk -F',' '{print $2}' <<< ${2}`
      shift
      ;;
    *)
      exit_with_msg "Error: Invalid argument '${1}'."
  esac
  shift
done

PREFIX=$(cat aws.yaml | grep ^prefix | awk -F '[: #"]+' '{print $2}')
[[ -z ${REG_PRIMARY} ]] && REG_PRIMARY=$(cat reg-primary/region.yaml | grep ^region | awk -F '[: #"]+' '{print $2}')
[[ -z ${REG_SECONDARY} ]] && REG_SECONDARY=$(cat reg-secondary/region.yaml | grep ^region | awk -F '[: #"]+' '{print $2}')

[[ -z ${APPROVERS} ]] && exit_with_msg "-a|--approvers is a required parameter. Exiting."
[[ -z ${ENVIRONMENT} ]] && exit_with_msg "-e|--environment is a required parameter. Exiting."
[[ -z ${ACCOUNT_ID} ]] && exit_with_msg "-i|--account-id is a required parameter. Exiting."
[[ -z ${PREFIX} ]] && exit_with_msg "Can't locate deployment prefix. Exiting."
[[ -z ${REG_PRIMARY} ]] && exit_with_msg "Can't locate primary region configuration. Exiting."
[[ -z ${REG_SECONDARY} ]] && exit_with_msg "Can't locate secondary region configuration. Exiting."

echo "Approvers: ${APPROVERS}"
echo "Environment: ${ENVIRONMENT}"
echo "Account ID: ${ACCOUNT_ID}"
echo "Name Prefix: ${PREFIX}"
echo "Primary Region: ${REG_PRIMARY}"
echo "Secondary Region: ${REG_SECONDARY}"

cp templates/env.tpl env.yaml

sed -i -e "s|APPROVERS_ARN|${APPROVERS}|g" env.yaml
sed -i -e "s:ENVIRONMENT:${ENVIRONMENT}:g" env.yaml
sed -i -e "s:ACCOUNT_ID:${ACCOUNT_ID}:g" env.yaml
sed -i -e "s:PREFIX:${PREFIX}:g" env.yaml
sed -i -e "s:REG_PRIMARY:${REG_PRIMARY}:g" env.yaml
sed -i -e "s:REG_SECONDARY:${REG_SECONDARY}:g" env.yaml

cp templates/region.tpl reg-primary/region.yaml
cp templates/region.tpl reg-secondary/region.yaml

sed -i -e "s:REGION:\"${REG_PRIMARY}\":g" reg-primary/region.yaml
sed -i -e "s:REGION:\"${REG_SECONDARY}\":g" reg-secondary/region.yaml
