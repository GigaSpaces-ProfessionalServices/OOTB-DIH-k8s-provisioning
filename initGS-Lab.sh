#!/bin/bash

# setup EKS cluster

PARENT_DIR=$(realpath "$(dirname $(realpath $0))")
SCRIPTS="${PARENT_DIR}/scripts"

clear -x
printf '=%.0s' {1..47}
printf "\n              EKS Cluster Setup\n"
printf '=%.0s' {1..47}
printf "\n\n"

# Set AWS CSM-LAB credentials
echo -e ">> Testing AWS credentials ...\n"

source $PARENT_DIR/setAWSEnv.sh

awscreds=$(aws sts get-caller-identity)
if [[ $(echo "${awscreds}" | grep Arn | wc -l) -eq 0 ]]; then
    echo "Please edit the setAWSEnv.sh file and run again."
    exit
fi 
echo ${awscreds} | jq   # json_reformat
echo
while true; do
    read -r -p "Continue with the above AWS crdentailes? [y/n] " response
    case "${response,,}" in
        n*)
            echo "Aborted."
            exit
            ;;
        y*) break ;;
    esac
done

read -p 'Please enter a project name (e.g: GSTM-375-James): ' replaceName
if [[ -z "${replaceName}" ]]; then
    echo "Project name cannot be empty, aborted."
    exit
fi

echo -e "\n>> Starting EKS cluster provisioning..."
mkdir -p tmp
cp $PARENT_DIR/terraform/primary_site/project_configuration.tmp $PARENT_DIR/terraform/primary_site/project_configuration.tf

# Update the project name for this deployment
sed -i "s/replaceName/${replaceName}/g" $PARENT_DIR/terraform/primary_site/project_configuration.tf
sed -i "s/replaceOwner/${replaceName}/g" $PARENT_DIR/terraform/primary_site/project_configuration.tf
cd $PARENT_DIR/terraform
terraform init -backend-config="key=OOTB-DIH-k8s-provisioning/Terraform-State-files/${replaceName}.tfstate"
tf_ready=$(terraform plan -out create.out | grep "run the following command to apply" | wc -l)
if [[ $tf_ready -eq 0 ]]; then
    echo "Terraform preparation has failed, please check the errors."
    exit
fi

terraform apply "create.out"
cd -
echo "TF-CSM-LAB-$replaceName" > $PARENT_DIR/clusterName.txt
$SCRIPTS/config_kubectl_to_eks.sh

exit
