#!/bin/bash

# Vars
FOLDER_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROG_CAT=$(which cat)
PROG_ECHO=$(which echo)
PROG_GETOPT=$(which getopt)
PROG_KOPS=$(which kops)
PROG_JQ=$(which jq)

S3_BUCKET="s3://kops-state-sysdev-mesh"

DEBUG=0

# Base Functions
function exit_help {
	${PROG_ECHO} "${0}: Er00r: ${1}"
	${PROG_ECHO}
	${PROG_ECHO} "-a <action>"
	${PROG_ECHO} "-d # Sets debug on"
	${PROG_ECHO} "-s <state>"
	${PROG_ECHO}
	${PROG_ECHO} "e.g: ${0} -a action -s state"
	${PROG_ECHO}
	exit 1
}

# Commandline Options
ARGV=`${PROG_GETOPT} -o a:ds: -n "${0}" -- "$@"`

eval set -- "${ARGV}"
while true
do
	case "${1}" in
		-a) OPT_ACTION=${2} ; shift 2 ;;
		-d) DEBUG=1 ; shift ;;
		-s) OPT_STATE=${2} ; shift 2 ;;
		--) shift ; break ;;
		*) exit_help "GetOpt Broke!" ; exit 1 ;;
	esac
done

# SANITY
if [[ ! ${OPT_ACTION} || ! ${OPT_STATE} ]]; then
	exit_help "Required options not set!"
fi

if [[ ! "${OPT_ACTION}" =~ ^(create|delete|update)$ ]]; then
	exit_help "Action must either be create, delete, or update!"
fi

if [[ ! -f "${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate" ]]; then
	echo "${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate"
	exit_help "State not found!"
fi

#
# Main
#
VPC_ID=$(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_vpc") | .primary.id' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate)
VPC_CIDR=$(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_vpc") | .primary.attributes.cidr_block' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate)
ROUTE_TABLE_IDS=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_route_table") | .primary.id' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
ROUTE_TABLE_NAMES=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_route_table") | .primary.attributes."tags.Name"' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
SUBNET_IDS=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_subnet") | .primary.id' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
SUBNET_NAMES=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_subnet") | .primary.attributes."tags.Name"' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
ROUTE53_ID=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_route53_zone") | select(.primary.attributes.vpc_id) | .primary.id' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
ZONE_NAMES=($(${PROG_JQ} '.modules[].resources[] | select(.type == "aws_subnet") | .primary.attributes.availability_zone' ${FOLDER_BASE}/vpc/state/${OPT_STATE}/terraform.tfstate))
ZONE_NAMES=($(echo "${ZONE_NAMES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

for (( i=0; i<${#SUBNET_NAMES[@]}; i++ )); do
	if [[ ! "${SUBNET_NAMES[$i]//\"/}" =~ ^subnet_app ]]; then
		continue
	fi

	SUBNETS+="${SUBNET_NAMES[$i]//\"/},"
done

for (( i=0; i<${#ZONE_NAMES[@]}; i++ )); do
	ZONES+="${ZONE_NAMES[$i]//\"/},"
done

# DEBUG
if [[ "${DEBUG}" == 1 ]]; then
	${PROG_ECHO} "Region: ${OPT_STATE}"
	${PROG_ECHO} "VPC ID: ${VPC_ID//\"/}"
	${PROG_ECHO} "VPC CIDR: ${VPC_CIDR//\"/}"
	${PROG_ECHO} "ROUTE53 ID: ${ROUTE53_ID//\"/}"
	${PROG_ECHO} "SUBNETS: ${SUBNETS%,}"
	${PROG_ECHO} "ZONES: ${ZONES%,}"
	${PROG_ECHO}
	for (( i=0; i<${#ROUTE_TABLE_NAMES[@]}; i++ )); do
		${PROG_ECHO} "Route Table: ${ROUTE_TABLE_NAMES[$i]//\"/} (${ROUTE_TABLE_IDS[$i]//\"/})"
	done
	${PROG_ECHO}
	for (( i=0; i<${#SUBNET_NAMES[@]}; i++ )); do
		${PROG_ECHO} "Subnet: ${SUBNET_NAMES[$i]//\"/} (${SUBNET_IDS[$i]//\"/})"
	done
	${PROG_ECHO}
	for (( i=0; i<${#ZONE_NAMES[@]}; i++ )); do
		${PROG_ECHO} "Zone: ${ZONE_NAMES[$i]//\"/}"
	done
	${PROG_ECHO}
	${PROG_CAT} << EOF
${PROG_KOPS} create secret --state=${S3_BUCKET} --name kubernetes.${OPT_STATE}.sysdev-mesh.exos.fm sshpublickey admin -i ${FOLDER_BASE}/admin_rsa.pub

${PROG_KOPS} create cluster \\
	--cloud=aws \\
	--name=kube.${OPT_STATE}.sysdev-mesh.exos.fm \\
	--dns-zone=${ROUTE53_ID} \\
	--dns=private \\
	--api-loadbalancer-type=internal \\
	--state=${S3_BUCKET} \\
	--node-count=3 \\
	--master-zones=${ZONES%,} \\
	--zones=${ZONES%,} \\
	--subnets=${SUBNETS} \\
	--utility-subnets=${SUBNETS} \\
	--vpc=${VPC_ID} \\
	--network-cidr=${VPC_CIDR} \\
	--node-size=t2.micro \\
	--master-size=t2.micro \\
	--topology=private \\
	--networking kube-router

${PROG_KOPS} update cluster --state=${S3_BUCKET} --name kube.${OPT_STATE}.sysdev-mesh.exos.fm --yes

${PROG_KOPS} delete cluster --state=${S3_BUCKET} --name kube.${OPT_STATE}.sysdev-mesh.exos.fm --yes
EOF
	${PROG_ECHO}
	exit 0
fi

if [[ "${OPT_ACTION}" =~ ^create$ ]]; then
	${PROG_KOPS} create secret --state=${S3_BUCKET} --name kubernetes.${OPT_STATE}.sysdev-mesh.exos.fm sshpublickey admin -i ~/.ssh/id_rsa.pub

	${PROG_KOPS} create cluster \
		--cloud=aws \
		--name=kube.${OPT_STATE}.sysdev-mesh.exos.fm \
		--dns-zone=${ROUTE53_ID} \
		--dns=private \
		--api-loadbalancer-type=internal \
		--state=${S3_BUCKET} \
		--node-count=3 \
		--master-zones=${ZONES%,} \
		--zones=${ZONES%,} \
		--subnets=${SUBNETS} \
		--utility-subnets=${SUBNETS} \
		--vpc=${VPC_ID} \
		--network-cidr=${VPC_CIDR} \
		--node-size=t2.micro \
		--master-size=t2.micro \
		--topology=private \
		--networking kube-router
fi

if [[ "${OPT_ACTION}" =~ ^delete$ ]]; then
	${PROG_KOPS} delete cluster --state=${S3_BUCKET} --name kube.${OPT_STATE}.sysdev-mesh.exos.fm --yes
fi

if [[ "${OPT_ACTION}" =~ ^update$ ]]; then
	${PROG_KOPS} update cluster --state=${S3_BUCKET} --name kube.${OPT_STATE}.sysdev-mesh.exos.fm --yes
fi

# EOF
