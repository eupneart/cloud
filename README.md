# Cloud
Cloud configurations for MAYArt.ai deployment in Kubernates.

For semplicity reasons it has been chosen to use [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download).
It is easy to install and start with, and it comes with multiple addons to like dashboard, registry and dns.

## Usuful commands
### Minikube
Start minikube
```
minikube start
```

Pause Kubernetes without impacting deployed applications:
```
minikube pause
```

Unpause a paused instance:
```
minikube unpause
```

Halt the cluster:
```
minikube stop
```

Browse the catalog of easily installed Kubernetes services:
```
minikube addons list
```

Install a new addon:
```
minikube addons enable <addon_name>
```

## Kuberantes dashboard
The Kuberantes dashboard is a practical UI to see al the resources in our cluster. You can find more information about it in the [official guide](https://minikube.sigs.k8s.io/docs/handbook/dashboard/).

To access the Minikube dashboard from another machine on the same local network, we've to use an ssh tunnel.

1 - First, after connecting to the server with ssh, make sure the Minikube dashboard is running and note the local URL it provides.
Example:
```
$ minikube dashboard --url
🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
http://127.0.0.1:36937/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

2 - Open another terminal window and set up SSH tunneling:
```
ssh -L 8001:127.0.0.1:<PORT> mayart@<SERVER_IP>

# Example
ssh -L 8001:127.0.0.1:36937 mayart@192.168.1.200
```

3 - Access the dashboard by navigating to the provided link:
```
http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

### What's next
In the future it may be considered to create an Ingress to easily access the dashboard.

First enable the addon:
```
minikube addons enable ingress
```

Then create an ingress resource to expose the dashboard service. Create a file named dashboard-ingress.yaml with the following content:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: <your-domain-or-ip>
    http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: kubernetes-dashboard
            port:
              number: 80
```
Replace <your-domain-or-ip> with the IP address of your Ubuntu server or a domain name pointing to it.

Apply the ingress resource in the cluster:
```
kubectl apply -f dashboard-ingress.yaml
```

You can finally open a web browser on your local machine and navigate to http://<your-domain-or-ip>. This should bring up the Minikube dashboard.
