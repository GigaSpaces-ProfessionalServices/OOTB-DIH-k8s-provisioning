#!/bin/bash

# destry eks cluster

PARENT_DIR=$(realpath "$(dirname $(realpath $0))/..")
SCRIPTS="${PARENT_DIR}/scripts"

source ${PARENT_DIR}/setAWSEnv.sh

while true; do
    echo ; read -r -p "Do you want to destroy your EKS lab ?[yes/no] " response
    case "${response,,}" in
        yes)
            ${SCRIPTS}/uninstall-dih-umbrella.sh
            cd ${PARENT_DIR}/terraform
            terraform plan -destroy -out destroy.out
            terraform apply "destroy.out"
            cd -
            exit
            ;;
        no)
            echo "Aborted."
            exit
            ;;
        *)
            echo "invalid response. please enter 'yes' or 'no'"
            continue
    esac
done
