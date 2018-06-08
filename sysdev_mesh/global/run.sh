#!/bin/bash

PROG_TERRAFORM=$(which terraform)
if [[ -z "${PROG_TERRAFORM}" ]]; then
  exit 1
fi

TF_VAR_homedir=${HOME} ${PROG_TERRAFORM} "${@}"

# EOF
