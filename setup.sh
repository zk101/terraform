#!/bin/bash

# Vars
FOLDER_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROG_CAT=$(which cat)
PROG_CHMOD=$(which chmod)
PROG_ECHO=$(which echo)
PROG_GETOPT=$(which getopt)
PROG_MKDIR=$(which mkdir)
PROG_TOUCH=$(which touch)

FILES=(main.tf outputs.tf variables.tf README.md)
MODULES_FOLDER="modules"

# Base Functions
function exit_help {
	${PROG_ECHO} "${0}: Er00r: ${1}"
	${PROG_ECHO}
	${PROG_ECHO} "-m <module_name>"
	${PROG_ECHO} "-p <project_name>"
	${PROG_ECHO} "-t <terraform_name>"
	${PROG_ECHO}
	${PROG_ECHO} "e.g: ${0} -p project_name -t terraform_name [-m module_name]"
	${PROG_ECHO}
	exit 1
}

# Commandline Options
ARGV=`${PROG_GETOPT} -o m:p:t: -n "${0}" -- "$@"`

eval set -- "${ARGV}"
while true
do
	case "${1}" in
		-m) OPT_MODULE=${2} ; shift 2 ;;
		-p) OPT_PROJECT=${2} ; shift 2 ;;
		-t) OPT_TERRAFORM=${2} ; shift 2 ;;
		--) shift ; break ;;
		*) exit_help "GetOpt Broke!" ; exit 1 ;;
	esac
done

# SANITY
if [[ ! ${OPT_PROJECT} || ! ${OPT_TERRAFORM} ]]; then
	exit_help "Required options not set!"
fi

if [[ ! "${OPT_TERRAFORM}" =~ ^[0-9a-zA-Z_-]+$ ]]; then
	exit_help "Project name must consist of a-z, 0-9, A-Z characters only!"
fi

if [[ ! "${OPT_PROJECT}" =~ ^[0-9a-zA-Z_-]+$ ]]; then
	exit_help "Project name must consist of a-z, 0-9, A-Z characters only!"
fi

if [[ ${OPT_MODULE} ]]; then
	if [[ ! "${OPT_MODULE}" =~ ^[0-9a-zA-Z_-]+$ ]]; then
		exit_help "Module name must consist of a-z, 0-9, A-Z characters only!"
	fi
fi

# Main
if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}" ]]; then
	${PROG_ECHO} "Creating ${OPT_PROJECT}"
	${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}
fi

if [[ ! -f "${FOLDER_BASE}/${OPT_PROJECT}/README.md" ]]; then
	${PROG_ECHO} "Creating ${OPT_PROJECT}/README.md"
	${PROG_ECHO} "# Project - ${OPT_PROJECT}" > ${FOLDER_BASE}/${OPT_PROJECT}/README.md
fi

if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}" ]]; then
	${PROG_ECHO} "Creating ${OPT_TERRAFORM}"
	${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}
fi

if [[ ! -f "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/run.sh" ]]; then
	${PROG_ECHO} "Creating ${OPT_TERRAFORM}/run.sh"
	${PROG_CAT} << EOF > ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/run.sh
#!/bin/bash

PROG_TERRAFORM=\$(which terraform)
if [[ -z "\${PROG_TERRAFORM}" ]]; then
  exit 1
fi

TF_VAR_homedir=\${HOME} \${PROG_TERRAFORM} "\${@}"

# EOF
EOF
	${PROG_CHMOD} +x ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/run.sh
fi

if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/data" ]]; then
	${PROG_ECHO} "Creating ${OPT_TERRAFORM}/data"
	${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/data
	${PROG_TOUCH} ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/data/.gitignore
fi

if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/state" ]]; then
	${PROG_ECHO} "Creating ${OPT_TERRAFORM}/state"
	${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/state
	${PROG_TOUCH} ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/state/.gitignore
fi

for FILE in ${FILES[@]}; do
	if [[ ! -f "${OPT_PROJECT}/${OPT_TERRAFORM}/${FILE}" ]]; then
		${PROG_ECHO} "Creating ${OPT_PROJECT}/${OPT_TERRAFORM}/${FILE}"
		${PROG_TOUCH} ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${FILE}
	fi

	if [[ "${FILE}" =~ ^README.md$ ]]; then
		${PROG_ECHO} "# Terraform Project - ${OPT_TERRAFORM}" > ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${FILE}
	fi
done

if [[ ${OPT_MODULE} ]]; then
	if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}" ]]; then
		${PROG_ECHO} "Creating ${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}"
		${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}
	fi

	if [[ ! -d "${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}" ]]; then
		${PROG_ECHO} "Creating ${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}"
		${PROG_MKDIR} -p ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}
	fi

	for FILE in ${FILES[@]}; do
		if [[ ! -f "${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}/${FILE}" ]]; then
			${PROG_ECHO} "Creating ${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}/${FILE}"
			${PROG_TOUCH} ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}/${FILE}
		fi

		if [[ "${FILE}" =~ ^README.md$ ]]; then
			${PROG_ECHO} "# Terraform Module - ${OPT_MODULE}" > ${FOLDER_BASE}/${OPT_PROJECT}/${OPT_TERRAFORM}/${MODULES_FOLDER}/${OPT_MODULE}/${FILE}
		fi
	done
fi

# EOF
