# Cloud
Cloud configurations for EupneArt in Kubernates.

For semplicity reasons it has been chosen to use [k3s](https://k3s.io).
It is easy to install and start with, it is lightweight, it doesn't give all the network problems we had with Minikube.

## Index
- [k3s cluster](#k3s-cluster)
  - [Fresh initialization](#fresh-initialization)
  - [Usuful commands](#usuful-commands)
- [Testing new features](#testing-new-features)
  - [Injections to API gateway](#injections-to-api-gateway)
  - [Frontend usage](#frontend-usage)
- [ArgoCD](#argocd)
- [MinIO UI](#minio-ui)
- [TODOs](#todos)


## K3s cluster
### Fresh initialization
To install the k3s cluster run:
```
curl -sfL https://get.k3s.io | sh -s - --docker

export KUBECONFIG="~/.kube/config:/etc/rancher/k3s/k3s.yaml"
# or (based on where it is saved)
export KUBECONFIG=~/k3s.yaml

sudo chmod ugo+r /etc/rancher/k3s/k3s.yaml
kubectl get node
```
This will allow the k3s cluster to use the local Docker daemon for pulling images.

To restart the cluster (be cautious with this since it may cause data loss):
```
sudo systemctl restart k3s
```

### Usuful commands
Check k3s configuration:
```
k3s check-config
```

The secret values must be base64, for that use the following:
```
echo -n '<YOUR_NEW_PASSWORD>' | base64
```

For debugging network problems between pods and service could be helpfull to use this command:
```
kubectl exec -it <profile-service-pod> -- netstat -tlnp
```

To enter in a pod terminal, use the following:
```
kubectl exec -it <pod-name> -- /bin/sh
```

## Testing new features
At the moment in each service we have a CI pipeline that automatically deploy in the docker registry new images at each new merge in the main branch.

However to test, it is suggested to copy-paste the GitHub Action to trigger the docker registry delivery from each commit in your branch. For the moment neither versioning nor different environments are in places, so no further action is needed.

To be sure that the latest image is taken, check that the service chart has `imagePullPolicy: Always` and refresh apps from ArgoCD UI or with `kubectl rollout restart deployment/<service-name>`.

### Injections to API gateway
You can simply inject to the API Gateway with Postman or similar and using the IP adress: `http://192.168.1.200:<api-gateway-svc-port>`.
Take the port from the service with `kubectl get svc | grep api-gateway`.
Example:
```
kubectl get svc | grep api-gateway
api-gateway         LoadBalancer   10.43.78.123    <pending>     80:30743/TCP                    9m19s
http://192.168.1.200:30743
```

Pay attention to use the correct REST API endpoint. For example for user-service: `http://192.168.1.200:80/api/v1/users`.

### Frontend usage
To connect to the web UI simply go to `http://192.168.1.200:<frontend-svc-port>` from the local network.
Take the port from the service with `kubectl get svc | grep frontend`.
Example:
```
kubectl get svc | grep frontend
frontend-service    NodePort       10.43.31.87     <none>        80:30414/TCP                    27m
http://192.168.1.200:30414
```

## Helm
To test locally the charts generated with a given value file and generating the files in a directory, run:
```
helm template my-release ./applications/profile-service --values /applications/profile-service/values.yaml --output-dir output-dir
helm template my-release ./applications/image-service --values applications/image-service/values.yaml --output-dir output-dir
```

## ArgoCD
To access to ArgoCD instance go to: `http://192.168.1.200:30276` and access with `admin` and the password.

ArgoCD is set in place to automatically sync new changes in the cluster.


## MinIO UI
To accesso to the MinIO UI from the local network go to: `http://192.168.1.200:9001` and access with the credentials in the `minio-image-config-map.yaml` and `minio-image-secret.yaml`.

Some useful documentation on how to use MinIO with Kubernates and how to secure it can be found [here](https://min.io/docs/minio/kubernetes/upstream/index.html).


## TODOs
The following are possible ideas to implement:
- Add config map and inject as an env variable for the api-gateway cors configuration (maybe for the moment even mapping)
- Create 127.0.0.1/charts/image-service.yaml for being able to do ```kubectl apply -f 127.0.0.1/charts/image-service.yaml``` as for ```https://k8s.io/examples/admin/dns/dnsutils.yamlc```. Use the github static page to do it.