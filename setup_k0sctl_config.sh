#!/usr/bin/env bash

set -eu

cat ./k0sctl_head.yaml

# Generate k0sctl controller host configs
for IP in $CONTROLLER_IPS; do
    cat <<EOF
  - role: controller
    installFlags:
    - --debug
    ssh:
      address: ${IP}
      user: root
      port: ${SSH_PORT}
      keyPath: ${SSH_IDENTITY}
EOF
    done

    # Generate k0sctl woker host configs
    for IP in $WORKER_IPS; do
        cat <<EOF
  - role: worker
    installFlags:
    - --debug
    ssh:
      address: ${IP}
      user: root
      port: ${SSH_PORT}
      keyPath: ${SSH_IDENTITY}
EOF
done

cat ./k0sctl_tail.yaml
