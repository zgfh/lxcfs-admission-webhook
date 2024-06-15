#!/bin/bash
KUBECONFIG=/root/.kube/config
kubectl apply -f deployment/lxcfs-daemonset.yaml 

kubectl delete secret lxcfs-admission-webhook-certs
kube-webhook-certgen --kubeconfig $KUBECONFIG create --namespace default --host lxcfs-admission-webhook-svc.default.svc  --secret-name lxcfs-admission-webhook-certs --key-name key.pem --cert-name cert.pem 
kubectl get secret lxcfs-admission-webhook-certs

kubectl delete -f deployment/deployment.yaml
kubectl create -f deployment/deployment.yaml
kubectl apply -f deployment/service.yaml
export CA_BUNDLE=$(kubectl get secrets lxcfs-admission-webhook-certs -o jsonpath='{.data.ca}' | tr -d '\n')

export CA_BUNDLE=""

cat ./deployment/mutatingwebhook.yaml | sed -e "s@\${CA_BUNDLE}@${CA_BUNDLE}@g" > ./deployment/mutatingwebhook-ca-bundle.yaml
kubectl apply -f deployment/mutatingwebhook-ca-bundle.yaml
#kube-webhook-certgen --kubeconfig /root/.kube/dev.d.run.worker01.config patch --namespace default --secret-name lxcfs-admission-webhook-certs --webhook-name mutating-lxcfs-admission-webhook-cfg