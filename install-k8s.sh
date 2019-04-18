#!/usr/bin/env bash
###########
# 安裝 Lab(k8s) 課程環境
###

# 確認使用的是 root user
checkRootUser() {
  if [ `whoami | grep ^root$ | wc -l` -eq 0 ];then
    echo "[ERROR] 請使用 root 執行"
    echo "        請先執行以下指令，切換為 root 後再重試 "
    echo "------------------------------------------"
    echo "sudo su"
    echo "------------------------------------------"
    exit
  fi
}

# 確認 gcloud 指令已經 login
checkGcloudLogin() {
  if [ `gcloud config get-value core/account | grep 'compute@developer.gserviceaccount.com' | wc -l` -eq 1 ]; then
    echo "[ERROR] gcloud 指令尚未登入"
    echo "        請先執行以下指令，登入 gcloud 後再重試 "
    echo "------------------------------------------"
    echo "gcloud auth login"
    echo "------------------------------------------"
    exit
  fi
}

# 設定參數
initParameter() {
  echo "參數設定確認中..."
  
  GOOGLE_PROJECT_ID=$(gcloud config get-value project)
  
  # GOOGLE_PROJECT_ID
  if [ -z $GOOGLE_PROJECT_ID  ]; then
    # GOOGLE_PROJECT_ID=systex-lab-$(cat /proc/sys/kernel/random/uuid | cut -b -6)
    echo "  未定義 GOOGLE_PROJECT_ID." 
    exit
  else
    echo "  系統參數 GOOGLE_PROJECT_ID  已設定...........(GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID)" 
  fi
  
  # GOOGLE_ZONE
  if [ -z $GOOGLE_ZONE  ]; then
    GOOGLE_ZONE=asia-east1-a
    echo "  未定義 GOOGLE_ZONE.         使用預設值.......(GOOGLE_ZONE=$GOOGLE_ZONE)"
  else
    echo "  系統參數 GOOGLE_ZONE        已設定...........(GOOGLE_ZONE=$GOOGLE_ZONE)" 
  fi
  
  # GOOGLE_GKE_NAME
  if [ -z $GOOGLE_GKE_NAME  ]; then
    GOOGLE_GKE_NAME=devops-hands-on-k8s
    echo "  未定義 GOOGLE_GKE_NAME.     使用預設值.......(GOOGLE_GKE_NAME=$GOOGLE_GKE_NAME)"
  else
    echo "  系統參數 GOOGLE_GKE_NAME    已設定...........(GOOGLE_GKE_NAME=$GOOGLE_GKE_NAME)" 
  fi

  # GOOGLE_GKE_MACHINE
  if [ -z $GOOGLE_GKE_MACHINE  ]; then
    GOOGLE_GKE_MACHINE=n1-standard-2
    echo "  未定義 GOOGLE_GKE_MACHINE.  使用預設值.......(GOOGLE_GKE_MACHINE=$GOOGLE_GKE_MACHINE)"
  fi

  # GOOGLE_GCE_IMAGE
  if [ -z $GOOGLE_GKE_VERSION  ]; then
    GOOGLE_GKE_VERSION=1.11.8-gke.6
    echo "  未定義 GOOGLE_GKE_VERSION.  使用預設值.......(GOOGLE_GKE_VERSION=$GOOGLE_GKE_VERSION)"
  fi

  read -p "確認開始安裝(Y/n)?" yn
  case $yn in
      [Nn]* ) echo "動作取消 "; exit;;
  esac  
}

# 安裝 kubectl 指令
installKubectl() {
  echo "正在安裝 kubectl 指令..."
  printf "  安裝 kubectl 套件中......"
  yum -y install kubectl > /dev/null 2>&1 && echo "完成"
}


createK8S() {
  echo "正在建立GKE..."
  
  printf "  啟用 Container API..."
  gcloud services enable container.googleapis.com

  printf "  開始建立 GKE($GOOGLE_GKE_NAME)..."
  gcloud container clusters create $GOOGLE_GKE_NAME \
      --machine-type=$GOOGLE_GKE_MACHINE \
      --region=$GOOGLE_ZONE \
      --num-nodes=1 \
      --cluster-version=$GOOGLE_GKE_VERSION 

  printf "  正在設定授權..."
  kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

}


#checkRootUser
#checkGcloudLogin
initParameter
#installKubectl
createK8S

cat <<EOF
----------------------------------------
環境安裝完成
----------
GKE 叢集名稱: $GOOGLE_PROJECT_ID
GKE 地區    : $GOOGLE_ZONE
GKE 版本    : $GOOGLE_GKE_VERSION
----------------------------------------
EOF
