#!/bin/bash

clear -x
echo "### Uninstalling Gigaspaces DIH ###"
echo "==================================="
read -r -p "Do you want to uninstall the ingress controller? [y/N] " response
case "${response,,}" in
    y*) uninstall_ingress=true ;;
    *) uninstall_ingress=false
esac

# delete feeder
SVC="space-feeder"
if [[ $(helm ls | grep $SVC | wc -l) -eq 1 ]]; then
    helm uninstall $SVC
else
    echo "no deployment for '${SVC}' found. nothing to do"
fi

# delete space
SVC="space"
if [[ $(helm ls | grep $SVC | wc -l) -eq 1 ]]; then
    helm uninstall $SVC
else
    echo "no deployment for '${SVC}' found. nothing to do"
fi


# delete dih
SVC="dih"
if [[ $(helm ls | grep $SVC | wc -l) -eq 1 ]]; then
    helm uninstall $SVC
else
    echo "no deployment for '${SVC}' found. nothing to do"
fi

# delete ingress controller
$uninstall_ingress && {
    SVC="ingress-nginx"
    if [[ $(helm ls | grep $SVC | wc -l) -eq 1 ]]; then
        helm uninstall $SVC
    else
        echo "no deployment for '${SVC}' found. nothing to do"
    fi
}

# poll kubectl to verify all pods are gone
while true; do
    num_pods=$(kubectl get pods -o name | grep -v ingress-nginx | wc -l)
    if [[ $num_pods -eq 0 ]]; then
        echo -e "\nDIH uninstall complete!\n"
        exit
    fi
done
exit
