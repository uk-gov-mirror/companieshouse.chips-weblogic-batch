#!/bin/bash

PROGNAME="$(basename $0)"

cd /apps/oracle/authcode-doc1-process

KEEP_HOME=${HOME}
source /apps/oracle/env.variables
HOME=${KEEP_HOME}

envsubst < /apps/oracle/.msmtprc.template > /apps/oracle/.msmtprc
source /apps/oracle/scripts/alert_functions

LOGS_DIR=../logs/authcode-doc1-process
mkdir -p ${LOGS_DIR}
LOG_FILE="${LOGS_DIR}/${HOSTNAME}-authcode-doc1-process-$(date +'%Y-%m-%d').log"
source /apps/oracle/scripts/logging_functions

exec >> "${LOG_FILE}" 2>&1

INPUT_OUTPUT_FLAG="${1}"
INPUT_OUTPUT_PATTERN="^(INPUT|OUTPUT)$"

[[ ! "${INPUT_OUTPUT_FLAG}" =~ $INPUT_OUTPUT_PATTERN ]] && exit 1

if [[ "${INPUT_OUTPUT_FLAG}" == "INPUT" ]]; then
    if [[ -f "${AUTHCODE_INPUT%/}/AUTHCODE.txt" ]]; then
        mv "${AUTHCODE_INPUT%/}/AUTHCODE.txt" ${AFP_INPUT%/}/AUTHCODE.txt
    else
        email_csi_xmatters_create_incident_f "${ENVIRONMENT_LABEL} - ${PROGNAME}" "AUTHCODE INPUT: Move failed!"
        exit 1
    fi
fi

if [[ "${INPUT_OUTPUT_FLAG}" == "OUTPUT" ]]; then
    shopt -s nullglob
    AUTHCODE_OUTPUT=( "${AFP_OUTPUT%/}"/*-AUTHCODE.dat.afp )
    case ${#AUTHCODE_OUTPUT[@]} in
        0) email_csi_xmatters_create_incident_f "${ENVIRONMENT_LABEL} - ${PROGNAME}" "AUTHCODE OUTPUT: Move failed!" && exit 1
           ;;
        1) mv -v -- "${AUTHCODE_OUTPUT[0]}" "${LETTER_OUTPUT_FILES_PATH}"
           ;;
        *) email_csi_xmatters_create_incident_f "${ENVIRONMENT_LABEL} - ${PROGNAME}" "AUTHCODE OUTPUT: Move failed!" && exit 1
           ;;
    esac
fi