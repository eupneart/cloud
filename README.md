# Cloud
Cloud configurations for MAYArt.ai deployment in Kubernates.

For semplicity reasons it has been chosen to use [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download).
It is easy to install and start with, and it comes with multiple addons to like dashboard, registry and dns.


## Minikube cluster
### Fresh start
To initiate the cluster run:
```
minikube start --driver=docker --listen-address=0.0.0.0
```

The commands below are used to activate the resources in the cluster and put the images with the tag in the minikube docker registry:
```
# apply charts
kubectl apply -f mayart/charts/api-gateway/
kubectl apply -f mayart/charts/user-service/

# use minikube docker env
eval $(minikube docker-env)

# load images in docker
docker load -i mayart/images/api-gateway-v0.1.0.tar
docker load -i mayart/images/user-service-v1.0.0.tar

# tag images as in the charts
docker tag api-gateway api-gateway:v0.1.0
docker tag user-service user-service:v1.0.0
```

### Usuful commands
Start minikube (if already initiated):
```
minikube start
```

Create the alias:
```
alias kubectl="minikube kubectl --"
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

Delete the cluster:
```
minikube delete
```

Browse the catalog of easily installed Kubernetes services:
```
minikube addons list
```

Install a new addon:
```
minikube addons enable <addon_name>
```

### Injections to API gateway (remote local connection)
After ssh to the server, activate the port forwarding:
```
kubectl port-forward --address 0.0.0.0 service/api-gateway 8080:80
```

Now you can inject to the minikube cluster with the ip `http://192.168.1.200:8080`.

#### Injections to API gateway (from nuc server)
Open ssh
```
minikube tunnel
```

In another window
```
$ kubectl get services
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
api-gateway    LoadBalancer   10.96.241.130    10.96.241.130   80:30918/TCP   20h
```

Then you can:
```
curl http://10.96.241.130:80/api/v1/users
```

Or for POST requests:
```
curl -X POST http://10.96.241.130:80/api/v1/use-H 'Content-Type: application/json' "email@test","password": "aVeryStrongPW"}' -H 'Content-Type: application/json'
```


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


## Docker registry [WIP]
For the moment, we wont't use the registry for an easier approach. The images are sent to the server with scp and loaded there in the docker instance.

1 - First, build your Docker image locally.

```
docker build -t my-microservice:latest .
```

2 - Save the Docker image as a tar file, transfer it to your server, and load it into Minikube.

```
docker save my-microservice:latest -o my-microservice.tar
scp my-microservice.tar user@localServerIp:~/my-microservice.tar

# Example
docker save user-service:latest -o user-service-v0.tar
scp user-service-v0.tar mayart@192.168.1.200:~/mayart/images/user-service-v0.tar
```

3 - SSH into your server and load the image into Minikube:
```
docker load -i ~/my-microservice.tar

# Example
docker load < mayart/images/user-service-v0.tar
```

#### Please remember to use `~/mayart/images` folder

### What's next
We have a private registry inside our cluster to store our images, thanks to the addon `registry`. 
The official documentation can be found [here](https://minikube.sigs.k8s.io/docs/handbook/registry/).
Try to use it or install another thanks to a docker image.

When enabled, the registry addon exposes its port 80 on the minikube’s virtual machine. You can confirm this by:
```
$ kubectl get service --namespace kube-system
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
kube-dns         ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   65m
metrics-server   ClusterIP   10.97.89.40      <none>        443/TCP                  55m
registry         ClusterIP   10.103.141.203   <none>        80/TCP,443/TCP           44m
```

In order to make docker accept pushing images to this registry, we have to redirect port 5000 on the docker virtual machine over to port 5000 on the minikube machine.

In order to make docker accept pushing images to this registry, we have to redirect port 5000 on the docker virtual machine over to port 80 on the minikube registry service. Unfortunately, the docker vm cannot directly see the IP address of the minikube vm. To fix this, you will have to add one more level of redirection.

Use kubectl port-forward to map your local workstation to the minikube vm
```
kubectl port-forward --namespace kube-system service/registry 5000:80
```
2 - Open another terminal window and set up SSH tunneling:
```
ssh -L 8001:127.0.0.1:<PORT> mayart@<SERVER_IP>

# Example
ssh -L 5000:127.0.0.1:5000 mayart@192.168.1.200
```

In order to make docker accept pushing images to this registry, we have to redirect port 5000 on the docker virtual machine over to port 80 on the minikube registry service. Unfortunately, the docker vm cannot directly see the IP address of the minikube vm. To fix this, you will have to add one more level of redirection.

Use kubectl port-forward to map your local workstation to the minikube vm
```
kubectl port-forward --namespace kube-system service/registry 5000:80
```

Now it’s possible to push images to the minikube registry (to be tested yet):
```
docker tag my/image localhost:5000/myimage
docker push localhost:5000/myimage
```