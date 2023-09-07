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
helm uninstall space-feeder

# delete space
helm uninstall space

# delete dih
helm uninstall dih

# delete ingress controller
$uninstall_ingress && helm uninstall ingress-nginx

while true; do
    num_pods=$(kubectl get pods -o name | grep -v ingress-nginx | wc -l)
    if [[ $num_pods -eq 0 ]]; then
        echo -e "\nDIH uninstall complete!\n"
        exit
    fi
done
exit
