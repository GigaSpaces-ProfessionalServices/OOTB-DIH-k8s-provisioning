#!/bin/bash

PARENT_DIR=$(realpath "$(dirname $(realpath $0))/..")
YAMLS="${PARENT_DIR}/yaml"
SCRIPTS="${PARENT_DIR}/scripts"

# Configure aws and kubectl
source ${PARENT_DIR}/setAWSEnv.sh

aws eks update-kubeconfig --name $(cat ${PARENT_DIR}/clusterName.txt)
kubectl get svc
echo
echo
echo "If you need to reconfig your kubectl to connect your cluster, please run:"
echo "source ${PARENT_DIR}/setAWSEnv.sh"
echo "aws eks update-kubeconfig --name $(cat ${PARENT_DIR}/clusterName.txt)"
echo
echo "Test it by running: kubectl get svc"
echo -e ">> Your cluster name is stored in clusterName.txt\n"

