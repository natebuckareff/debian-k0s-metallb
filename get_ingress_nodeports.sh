#!/usr/bin/env bash

kubectl get -n ingress-nginx svc ingress-nginx-controller -o=json \
    | jq '.spec.ports[] | { appProtocol: .appProtocol, nodePort: .nodePort }'
