#!/bin/sh
###
# MicroK8s + Rancher installer
##

# 輸入您的 email 
EMAIL=

# 如果您的環境不是在 GCP 請自行調整以下變數
EXTERNAL_IP=$(curl -s 169.254.169.254/computeMetadata/v1beta1/instance/network-interfaces/0/access-configs/0/external-ip)

sudo snap install microk8s --channel=1.18 --classic
sudo microk8s.enable dns dashboard storage ingress helm3 rbac 

sudo sh -c 'echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver'
sudo systemctl restart snap.microk8s.daemon-apiserver.service

sudo microk8s.helm3 repo add jetstack https://charts.jetstack.io
sudo microk8s.kubectl create namespace cert-manager
sudo microk8s.kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
sudo microk8s.helm3 install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.15.1 --set installCRDs=true

echo "等待 cert-manager 服務啟動 ..."
sleep 3
sudo microk8s.kubectl wait --for=condition=ready --timeout=120s pods -l app=cert-manager -n cert-manager
sudo microk8s.kubectl wait --for=condition=ready --timeout=120s pods -l app=cainjector -n cert-manager
sudo microk8s.kubectl wait --for=condition=ready --timeout=120s pods -l app=webhook -n cert-manager
sleep 3

sudo microk8s.helm3 repo add rancher-stable https://releases.rancher.com/server-charts/stable
sudo microk8s.kubectl create namespace cattle-system
sudo microk8s.helm3 install rancher rancher-stable/rancher  --namespace cattle-system --set replicas=1 --set hostname=rancher.${EXTERNAL_IP}.nip.io --set ingress.tls.source=letsEncrypt --set letsEncrypt.email=${EMAIL}

echo "等待 Rancher 服務啟動 ..."
sleep 3
sudo microk8s.kubectl wait --for=condition=ready --timeout=120s pods -l app=rancher -n cattle-system
sleep 3

echo "系統參數設定中 ... "

sudo microk8s.kubectl patch $(sudo microk8s.kubectl get user.management.cattle.io -l authz.management.cattle.io/bootstrapping=admin-user -o name) --type='json' -p '[{"op":"replace","path":"/mustChangePassword","value":false},{"op":"replace","path":"/password","value":"$2a$10$7BhfjPOlS.KyLj81XMLWkO/ZH7JqeB1xeBmJzygZCHbD7Xni9Exy2"}]'

sudo microk8s.enable metrics-server
sudo git clone https://github.com/abola/2day_catalogs.git
sudo microk8s.kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
#sudo microk8s.kubectl annotate daemonset nginx-ingress-microk8s-controller -n ingress prometheus.io/port=10254 prometheus.io/scrape=true
sudo microk8s.kubectl create ns flagger
sudo microk8s.helm3 install flagger -n flagger --set=externalIp=${EXTERNAL_IP} ./2day_catalogs/charts/flagger-server/0.27.0/
#sudo microk8s.kubectl patch daemonset nginx-ingress-microk8s-controller -n ingress --type='json' -p='[{"op": "add", "path": "/spec/template/metadata/annotations/prometheus.io~1port", "value": "10254"}]'
#sudo microk8s.kubectl patch daemonset nginx-ingress-microk8s-controller -n ingress --type='json' -p='[{"op": "add", "path": "/spec/template/metadata/annotations/prometheus.io~1scrape", "value": "true"}]'
sudo microk8s.kubectl patch daemonset nginx-ingress-microk8s-controller -n ingress --patch "$(curl -s https://raw.githubusercontent.com/abola/2day_example_python/master/patch/nginx-ingress.yaml)"
sudo microk8s.kubectl patch daemonset nginx-ingress-microk8s-controller -n ingress --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 10254}}]'
sleep 5
sudo microk8s.kubectl wait --for=condition=ready pods -l name=nginx-ingress-microk8s -n ingress

echo "----------------------------------------"
echo "安裝完成"
echo "現在您可以開啟 https://rancher.${EXTERNAL_IP}.nip.io"
echo "----------------------------------------"
