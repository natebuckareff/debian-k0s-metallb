#!/usr/bin/env bash

set -eu

export CONTROLLER_IPS="192.168.0.200"
export WORKER_IPS="192.168.0.201 192.168.0.202"
export LB_IP_POOL="192.168.0.203-192.168.0.254"
export SSH_PORT=22
export SSH_IDENTITY="~/.ssh/id_ed25519"

# Wait for nodes to come online
for IP in $CONTROLLER_IPS $WORKER_IPS; do
    while true; do
        echo "Waiting for $IP..."
        sleep 1
        if ssh "root@$IP" "echo Ready: $IP"; then
            break
        fi
    done
done

# Setup networking on nodes
./setup_network.sh

# Install k0s
./setup_k0sctl_config.sh | tee ./k0sctl.yaml | k0sctl apply --config -

# Get and merge kubeconfig
k0sctl kubeconfig > kubeconfig
export KUBECONFIG="./kubeconfig"
kubectl config view --flatten > ~/.kube/config

# Setup load balancer address pool
export LB_IP_POOL
envsubst < ./metallb-l2-pool.yaml | kubectl apply -f -

## Before installing the ingress controller, test that the load balancer was setup
#kubectl apply -f test-load-balancer-service.yaml
#kubectl wait --for=condition=ready svc test-load-balancer
#kubectl delete -f test-load-balancer-service.yaml

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
