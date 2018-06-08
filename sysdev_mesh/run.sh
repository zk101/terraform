#!/bin/bash

# Vars
FOLDER_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROG_ECHO=$(which echo)
PROG_GETOPT=$(which getopt)
PROG_JQ=$(which jq)
PROG_MKDIR=$(which mkdir)
PROG_MV=$(which mv)
PROG_RM=$(which rm)

# Base Functions
function exit_help {
	${PROG_ECHO} "${0}: Er00r: ${1}"
	${PROG_ECHO}
	${PROG_ECHO} "-a <action>"
	${PROG_ECHO}
	${PROG_ECHO} "e.g: ${0} -a action"
	${PROG_ECHO}
	exit 1
}

# Commandline Options
ARGV=`${PROG_GETOPT} -o a: -n "${0}" -- "$@"`

eval set -- "${ARGV}"
while true
do
	case "${1}" in
		-a) OPT_ACTION=${2} ; shift 2 ;;
		--) shift ; break ;;
		*) exit_help "GetOpt Broke!" ; exit 1 ;;
	esac
done

# BaseExec
function terraform_exec {
	FOLDER=${1}
	STATE=${2}
	CONFIG=""

	if [[ ! -z "${3}" ]]; then
		CONFIG="-var-file=./data/${3}"
	fi

	cd ${FOLDER_BASE}/${FOLDER}

	if [[ ! -d "${FOLDER_BASE}/${FOLDER}/.terraform" ]]; then
  	./run.sh init
		if [[ $? != 0 ]]; then
			exit_help "Terraform failed to initilise!"
		fi
	fi

	if [[ ! -d "${FOLDER_BASE}/${FOLDER}/state/${STATE}" ]]; then
		${PROG_MKDIR} -p ${FOLDER_BASE}/${FOLDER}/state/${STATE}
	fi

	if [[ "${OPT_ACTION}" =~ ^init$ ]]; then
		./run.sh ${OPT_ACTION}
	else
		./run.sh ${OPT_ACTION} -state ./state/${STATE}/terraform.tfstate ${CONFIG}
	fi

	if [[ $? != 0 ]]; then
		exit_help "Terraform apply failed!"
	fi
}

# SANITY
if [[ ! ${OPT_ACTION} ]]; then
	exit_help "Required options not set!"
fi

if [[ ! "${OPT_ACTION}" =~ ^(apply|destroy|init|plan|refresh)$ ]]; then
	exit_help "Action must either be apply, destroy, init, plan or refresh!"
fi

#
# Main
#

# Run this for all actions except destroy (destroy needs to run in reverse order)
if [[ "${OPT_ACTION}" =~ ^(apply|init|plan|refresh)$ ]]; then
	terraform_exec "global" "global"

	for CONFIG in $(ls -1 ${FOLDER_BASE}/vpc/data); do
		if [[ ! "${CONFIG}" =~ \.tfvars$ ]]; then
			continue
		fi

		terraform_exec "vpc" "${CONFIG%%\.*}" "${CONFIG}"
	done
fi

# Run this for destroy (destroy needs to run in reverse order)
if [[ "${OPT_ACTION}" =~ ^(destroy)$ ]]; then
	for CONFIG in $(ls -1 ${FOLDER_BASE}/vpc/data); do
		if [[ ! "${CONFIG}" =~ \.tfvars$ ]]; then
			continue
		fi

		terraform_exec "vpc" "${CONFIG%%\.*}" "${CONFIG}"
	done

	terraform_exec "global" "global"
fi

# EOF

