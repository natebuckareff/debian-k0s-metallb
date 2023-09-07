PoC:
- Setup 4 nodes running Debian with static IPs 192.168.0.200-203/24
- Setup SSH access to root on each node
- Install Kubernetes using k0s on nodes 192.168.0.200-202
- Install ingress-nginx with the baremetal provider (to setup NodePorts)
- Install HAProxy on node 192.168.0.203
- Proxy HAProxy backends to worker nodes on HTTP and HTTPS nodeports
- Setup "TLS passthrough" for HTTPS HAProxy backends

If running on bare metal:
- Install ingress-nginx with cloud provider instead (counter intuitive right?)
- Install MetalLB and setup L2 pool (replaces HAProxy)

For testing:
- Create self-signed TLS certificate and key using mkcert
- Create TLS secret
- Reference TLS secret in ingress resources

TODO(https):
- Install cert-manager
- Use letsencrypt staging for testing
- Follow: https://cert-manager.io/docs/tutorials/acme/nginx-ingress/

TODO(storage):
- Install local volume static provisioner
- Follow: https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/getting-started.md 

TODO(HA control plane):
- Setup HA control plane using HAProxy (different instance)
- Follow: https://docs.k0sproject.io/v1.23.6+k0s.2/high-availability/
