function akg
    set domain $argv[1]
    set tier $argv[2]
    set region $argv[3]
    echo ""
    echo ---------------------------------------------------------------------------------------------------------------------------
    echo "REMEMBER TO CHANGE SUBSCRIPTION: SNADBOX CONTRIIBUTOR FOR TEST AND SANDBOX, LIVE CONTRIBUTOR FOR LIVE"
    echo ---------------------------------------------------------------------------------------------------------------------------
    echo ""
    rm $HOME/.kube/$domain-$tier-$region.yaml
    az account set --subscription $domain-$tier
    az aks get-credentials --resource-group $domain-$tier-$region --name k8s-$domain-$tier-$region --file $HOME/.kube/$domain-$tier-$region.yaml
    kubelogin convert-kubeconfig -l interactive --client-id 80faf920-1908-4b52-b5ef-a8e7bedfc67a --tenant-id 4aa4b472-3d96-4c3a-82b6-d1afe264a7a6 --kubeconfig $HOME/.kube/$domain-$tier-$region.yaml
    kubectl --kubeconfig $HOME/.kube/$domain-$tier-$region.yaml config rename-context k8s-$domain-$tier-$region $domain-$tier-$region
    kubie ctx $domain-$tier-$region
end
