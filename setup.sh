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
set +e
./setup_k0sctl_config.sh | tee ./k0sctl.yaml | k0sctl apply --config -
set -e

# Get and merge kubeconfig
k0sctl kubeconfig > kubeconfig
export KUBECONFIG="./kubeconfig"
kubectl config view --flatten > ~/.kube/config

wait_for() {
    echo "Waiting for $1"
    shift
    while true; do
        kubectl wait $@
        if [[ $? = 0 ]]; then
            break
        fi
    done
}

wait_for 'kube-dns' \
    --namespace kube-system \
    --for=condition=ready pod -l k8s-app=kube-dns \
    --timeout 300s

wait_for 'kube-proxy' \
    --namespace kube-system \
    --for=condition=ready pod -l k8s-app=kube-proxy \
    --timeout 300s

wait_for 'kube-router' \
    --namespace kube-system \
    --for=condition=ready pod -l k8s-app=kube-router \
    --timeout 300s

wait_for 'metrics-server' \
    --namespace kube-system \
    --for=condition=ready pod -l k8s-app=metrics-server \
    --timeout 300s

echo "Installing ingress-nginx"

kubectl apply -f \
  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

wait_for 'ingress controller' \
    --namespace ingress-nginx \
    --for=condition=ready pod \
    -l app.kubernetes.io/instance=ingress-nginx \
    -l app.kubernetes.io/component=controller \
    --timeout 300s
