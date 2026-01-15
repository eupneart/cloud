# Cloud
Cloud configurations for EupneArt in Kubernates.

For semplicity reasons it has been chosen to use [k3s](https://k3s.io).
It is easy to install and start with, it is lightweight, it doesn't give all the network problems we had with Minikube.

## Index
- [k3s cluster](#k3s-cluster)
  - [Fresh initialization](#fresh-initialization)
  - [Usuful commands](#usuful-commands)
- [Testing new features](#testing-new-features)
  - [Local testing](#local-testing)
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

However before merging you have to test locally first, see the next section for more information.

To test instead in the cluster it is suggested to copy-paste the GitHub Action to trigger the docker registry delivery from each commit in your branch. For the moment neither versioning nor different environments are in places, so no further action is needed.

To be sure that the latest image is taken, check that the service chart has `imagePullPolicy: Always` and refresh apps from ArgoCD UI or with `kubectl rollout restart deployment/<service-name>`.

### Local testing
For local testing of the cluster or some resources in the cluster [Rancher](https://rancherdesktop.io) can be used (and suggested).
Once your local cluster is setup you can do `helm install` of whatever resource you'd like.

It is raccomanded to use the override `values-local.yaml` along with the basic `values.yaml`, and update it if needed for faster local testing.
For example:
```
helm upgrade -i api-gateway applications/api-gateway -f applications/api-gateway/values-local.yaml
```

To get the logs from a deployment you can use:
```
kubectl logs deployment/api-gateway -f
```

#### Image service
Specifically, for the image-service you need to provide the MinIO service as nodeport and set `MINIO_EXTERNAL_URL` to `http://<node-ip>:<nodePort>`. You can override the default one in `applications/image-service/values-local.yaml`.

The node ip and node port can be retrieved with the following commands:
```
kubectl get nodes -o wide
kubectl get svc image-service-minio -n default -o jsonpath='{.spec.ports[0].nodePort}'
```

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
From remote create an ssh tunnel `ssh -L 8090:127.0.0.1:31071 eupneart@nuc.eupneart.com -p 1872`and then go to [localhost:8090](http://localhost:8090).

ArgoCD is set in place to automatically sync new changes in the cluster.

### Installation
```
kubectl create ns argocd
wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O install.yaml
kubectl apply -n argocd -f install.yaml
```

Check if everything is fine:
```
kubectl get all -n argocd
```
Retrieve the pw for the login:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

By default ArgoCD svc can be accessed only from port-forwarding:
```
kubectl port-forward service/argocd-server 8090:80 -n argocd
```

The service has been modified as a `NodePort` with:
```
kubectl -n argocd edit svc argocd-server
```


## MinIO UI
To accesso to the MinIO UI from the local network go to: `http://192.168.1.200:9001` and access with the credentials in the `minio-image-config-map.yaml` and `minio-image-secret.yaml`.

Some useful documentation on how to use MinIO with Kubernates and how to secure it can be found [here](https://min.io/docs/minio/kubernetes/upstream/index.html).


## Dashboard
The web ui dashboard is available with a port forward:
```
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

at: `https://localhost:8443`. 
To connect follow [this guide](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md). A sample user with administrative privileges will be created, but in PRD it should be changed with a proper

## Troubleshooting
### Network errors
It can came handy to have a pod for injection inside the cluster:
```
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
apk add curl
curl -v http://frontend-service.default:8080
```

### Installation issue
The Dashboard has been installed follwing the official [documentation](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) with the following commands:

```
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

However `kubernetes-dashboard-kong` pod was stacked in a CrashLoopBackOff as follow:

```
Defaulted container "proxy" out of: proxy, clear-stale-pid (init)
Error: could not prepare Kong prefix at /kong_prefix: nginx configuration is invalid (exit code 1):
nginx: [warn] the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /kong_prefix/nginx.conf:7
nginx: the configuration file /kong_prefix/nginx.conf syntax is ok
nginx: [emerg] bind() to [::1]:8444 failed (99: Cannot assign requested address)
nginx: configuration file /kong_prefix/nginx.conf test failed
```

To solve this issue, the deployment has been modified:

```
kubectl -n kubernetes-dashboard edit deployment kubernetes-dashboard-kong
```

Changing the env variable `KONG_PROXY_LISTEN` from `0.0.0.0:8443 http2 ssl, [::]:8443 http2 ssl` to `0.0.0.0:8443 http2 ssl, 0.0.0.0:8443 http2 ssl`.


## TODOs
The following are possible ideas to implement:
- Add config map and inject as an env variable for the api-gateway cors configuration (maybe for the moment even mapping)
- Create 127.0.0.1/charts/image-service.yaml for being able to do ```kubectl apply -f 127.0.0.1/charts/image-service.yaml``` as for ```https://k8s.io/examples/admin/dns/dnsutils.yamlc```. Use the github static page to do it.