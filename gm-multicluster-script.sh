#!/bin/bash

# install argocd on mgmt, cluster1, and cluster2
cd argocd
./install-argocd.sh mgmt
./install-argocd.sh cluster1
./install-argocd.sh cluster2

# install gloo-mesh on mgmt
# figure out SED license stuff
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-ee-helm.yaml --context mgmt

../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10 mgmt

# register clusters
./scripts/meshctl-register.sh mgmt cluster1
./scripts/meshctl-register.sh mgmt cluster2

# install istio on cluster1 and cluster2
cd ../istio
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context cluster1
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context cluster2

../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 cluster1
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 cluster2

kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster1-1-10-4.yaml --context cluster1
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster2-1-10-4.yaml --context cluster2

../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster1
../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster2

# deploy gloo-mesh dataplane addons
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster1
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster2

../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 cluster1
../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 cluster2

# deploy gloo-mesh controlplane addons (accesspolicy)
kubectl apply -f argo/gloo-mesh-controlplane-addons.yaml --context mgmt

# create virtualmesh
kubectl apply -f argo/gloo-mesh-virtualmesh.yaml --context mgmt