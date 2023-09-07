#!/bin/bash

# Deploying XAP umbrella on EKS version 1.22

function print_duration() {
    start=$1
    end=$2
    time_diff=$(expr $end - $start)
    if [[ $time_diff -gt 60 ]]; then
        time_diff_m=$(expr $time_diff / 60)
        time_diff_s=$(expr $time_diff % 60)
        echo "${time_diff_m}m:${time_diff_s}s"
    else
        echo "${time_diff}s"
    fi
}

PARENT_DIR=$(realpath "$(dirname $(realpath $0))/..")
YAMLS="${PARENT_DIR}/yaml"
SCRIPTS="${PARENT_DIR}/scripts"
VERSION="16.3.0"

clear -x
printf '=%.0s' {1..57}
printf "\n              Gigaspaces DIH Installation\n"
printf "                     version: $VERSION\n"
printf '=%.0s' {1..57}
printf "\n\n"

source ${PARENT_DIR}/setAWSEnv.sh

# Load Balancers Annotations
cluster_name=$(cat ${PARENT_DIR}/clusterName.txt)
sed -i \
-e "s/Owner=[^,]*/Owner=${cluster_name}/" \
-e "s/Project=[^,]*/Project=${cluster_name}/" \
-e "s/Name=[^,]*/Name=${cluster_name}-ingress-LB/" ${YAMLS}/ingress-controller-tcp.yaml

# deploy ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx
echo -e "\n>> Deploying Ingress Controller ...\n"
LB_SVC="ingress-nginx-controller"
ingress_query=$(kubectl get deployments $LB_SVC --no-headers 2>&1 | awk '{print $1}')
if [[ $ingress_query == $LB_SVC ]]; then
    echo "$LB_SVC already deployed!"
    LB_ADDRESS=$(kubectl get svc $LB_SVC --no-headers | awk '{print $4}')
    echo ; echo "Load Balancer URL: http://$LB_ADDRESS"
else
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -f ${YAMLS}/ingress-controller-tcp.yaml
    # wait until ingress load balancer is ready
    start_time=$(date "+%s")
    echo ; echo -n "Waiting for Ingress Load Balancer to be ready "

    count=0 ; timeout=30
    while [[ $count -lt $timeout ]]; do
        ((count++))
        echo -n "."
        LB_ADDRESS=$(kubectl get svc $LB_SVC --no-headers | awk '{print $4}')
        [[ $LB_ADDRESS != "" ]] && break || sleep 1
    done
    sleep 1
    count=0 ; timeout=30
    while [[ $count -lt $timeout ]]; do
        ((count++))
        echo -n "."
        [[ $(kubectl get pod | grep $LB_SVC | awk '{print $3}') == "Running" ]] && break || sleep 1
    done
    sleep 1
    LB_SVC="ingress-nginx-controller-admission"
    count=0 ; timeout=30
    while [[ $count -lt $timeout ]]; do
        ((count++))
        echo -n "."
        LB_ADMISSION_ADDRESS=$(kubectl get svc $LB_SVC --no-headers | awk '{print $3}')
        [[ $LB_ADMISSION_ADDRESS != "" ]] && break || sleep 1
    done
    end_time=$(date "+%s")
    echo -e "\n>> Ingress Load Balancer is ready after $(print_duration $start_time $end_time)"
    echo -e ">> Load Balancer URL: http://$LB_ADDRESS\n"
fi

# deploy DIH grid
kubectl create secret docker-registry myregistrysecret --docker-server=https://index.docker.io/v1/ --docker-username=dihcustomers --docker-password=dckr_pat_NYcQySRyhRFZ6eUQAwLsYm314QA --docker-email=dih-customers@gigaspaces.com
kubectl create secret generic datastore-credentials --from-literal=username='system' --from-literal=password='admin11'
echo
helm repo add dih https://s3.amazonaws.com/resources.gigaspaces.com/helm-charts-dih
helm repo update
echo -e "\n>> Deploying DIH (estimated time: 5-10 minutes) ...\n"
start_time=$(date "+%s")
helm install dih dih/dih --version $VERSION
# folllow grid managers until deployed
echo -e "\n\n"; echo -n ">> Waiting for DIH deployment to complete "
while true; do
    is_ready=true
    echo -n "."
    for p in {0..2}; do
        the_pod="xap-manager-$p"
        if [[ $(kubectl get pod $the_pod | grep $the_pod | awk '{print $3}') != "Running" ]]; then
            is_ready=false
            break
        fi
    done
    $is_ready && break || sleep 3
done
end_time=$(date "+%s")
echo -e "\n>> DIH deployment completed after $(print_duration $start_time $end_time)\n"

# deploy the space
helm install space dih/xap-pu --version $VERSION
echo

# deploy a feeder
helm install space-feeder dih/xap-pu --version=$VERSION -f ${YAMLS}/space-feeder.yaml
echo

# show ui urls
echo -e "\n\n:: OPS Manager ::"
echo "http://${LB_ADDRESS}:8090"
echo ":: Spacedeck ::"
echo "http://${LB_ADDRESS}:3000"
echo ":: Grafana ::"
echo "http://${LB_ADDRESS}:3030"
echo
echo -e "Deployment complete!\n"

