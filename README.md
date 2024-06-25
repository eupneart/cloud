# Cloud
Cloud configurations for MAYArt.ai deployment in Kubernates.

For semplicity reasons it has been chosen to use [k3s](https://k3s.io).
It is easy to install and start with, it is lightweight, it doesn't give all the network problems we had with Minikube.


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

To restart the cluster:
```
sudo systemctl restart k3s
```

### Upload new images
The commands below are used to activate the resources in the cluster and put the images with the tag in the docker registry.

First create the `.tar` from your image in your local:
```
docker save -o user-service.tar user-service
docker save -o api-gateway.tar api-gateway:v0.1.0
```

Then copy the tar in the server:
```
scp user-service.tar mayart@192.168.1.200:~/mayart/images/user-service-v1.0.0.tar
scp api-gateway.tar mayart@192.168.1.200:~/mayart/images/api-gateway-v0.1.0.tar
```

Finally you can load the images in docker:
```
docker load -i mayart/images/api-gateway-v0.1.0.tar
docker load -i mayart/images/user-service-v1.0.0.tar
docker load -i mayart/images/frontend-v1.0.0.tar

# tag images as in the charts
docker tag api-gateway api-gateway:v0.1.0
docker tag user-service user-service:v1.0.0
```

### Upload new charts
Copy the charts from the cloud repository:
```
scp -r cloud/charts mayart@192.168.1.200:~/mayart/
```

```
# apply charts
kubectl apply -f mayart/charts/api-gateway/
kubectl apply -f mayart/charts/user-service/
kubectl apply -f mayart/charts/frontend/
kubectl apply -f mayart/charts/image-service/
```

### Usuful commands
Check k3s configuration:
```
k3s check-config
```

### Injections to API gateway
You can simply inject to the API Gateway with Postman or similar and using the IP adress: `http://192.168.1.200:80`.

Pay attention to use the correct REST API endpoint. For example for user-service: `http://192.168.1.200:80/api/v1/users`.


## Configuration files
To load the charts in the nuc server:
```
cloud$ scp -r charts mayart@192.168.1.200:~/mayart/
```
Look to [docker registry chapter](#docker-registry-wip) for more info.

### Secrets
In the secret the values must be base64 hashed, for that:
```
echo -n '<YOUR_NEW_PASSWORD>' | base64
```


## ArgoCD
To access to ArgoCD instance go to: `http://192.168.1.200:30276` and access with `admin` and the password retrieved with:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Minio UI
To accesso to the MinioUI go to: `http://192.168.1.200:32061` and access with the credentials in the `minio-image-config-map.yaml` and `minio-image-secret.yaml`.

Pay attention that at the moment at each minio pod restart, te web ui port changes, thus the above link may not work.
To fix it retrieve the logs from minio pod:
```
kubectl logs <minio-pod-name>
```
and then take the webpage port and change it in the minio service accordingly.

## TODO
- Add config map and inject as an env variable for the api-gateway cors configuration (maybe for the moment even mapping)