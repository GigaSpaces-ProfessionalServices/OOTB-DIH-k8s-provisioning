#!/bin/bash

# destroy eks cluster

PARENT_DIR=$(realpath "$(dirname $(realpath $0))/..")
SCRIPTS="${PARENT_DIR}/scripts"
CLUSTER_NAME=$(cat $PARENT_DIR/clusterName.txt)
source ${PARENT_DIR}/setAWSEnv.sh

if [[ $(aws eks list-clusters | grep -q $CLUSTER_NAME ; echo $?) -ne 0 ]]; then
    echo -e "\nEKS cluster '$CLUSTER_NAME' does not exist. nothing to destroy.\n"
    exit
fi

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
