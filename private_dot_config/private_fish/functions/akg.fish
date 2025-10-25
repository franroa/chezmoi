function akg
    set domain $argv[1]
    set tier $argv[2]
    set region $argv[3]
    rm $HOME/.kube/$domain-$tier-$region.yaml
    az account set --subscription $domain-$tier
    az aks get-credentials --resource-group $domain-$tier-$region --name k8s-$domain-$tier-$region --file $HOME/.kube/$domain-$tier-$region.yaml
    kubelogin convert-kubeconfig -l azurecli
    kubectl --kubeconfig $HOME/.kube/$domain-$tier-$region.yaml config rename-context k8s-$domain-$tier-$region $domain-$tier-$region
    kubie ctx $domain-$tier-$region
end
