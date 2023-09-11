#!/bin/bash

# Uninstall Gigaspaces DIH

function uninstall_service() {
    if [[ $(helm ls -q | grep -e "^$1$" | wc -l) -eq 1 ]]; then
        helm uninstall $1
    else
        echo "no deployment for '$1' found. nothing to do"
    fi
}

SERVICES="space-feeder space dih ingress-nginx"

clear -x
echo "### Uninstalling Gigaspaces DIH ###"
echo "==================================="
read -r -p "Do you want to uninstall the ingress controller? [y/N] " response
case "${response,,}" in
    y*) uninstall_ingress=true ;;
    *) uninstall_ingress=false
esac

# delete services
for s in $SERVICES; do
    if [[ $s == "ingress-nginx" ]] && ! $uninstall_ingress ; then
        continue
    fi
    uninstall_service $s
done

# poll kubectl to verify all pods are gone
while true; do
    num_pods=$(kubectl get pods -o name | grep -v ingress-nginx | wc -l)
    if [[ $num_pods -eq 0 ]]; then
        echo -e "\nDIH uninstall complete!\n"
        exit
    fi
done

exit
