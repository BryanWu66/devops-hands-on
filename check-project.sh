#!/usr/bin/env bash
###########
# check 安裝 Lab(k8s) 課程環境
###

checkProject() {
  PROJECT_ID=$(gcloud config get-value project)
  echo $PROJECT_ID

  GOOGLE_PROJECT_ID=$(gcloud projects list --filter=systex-lab  | awk 'END {print $1}')
  echo $GOOGLE_PROJECT_ID

  if [ -z $GOOGLE_PROJECT_ID  ]; then
    GOOGLE_PROJECT_ID=systex-lab-$(cat /proc/sys/kernel/random/uuid | cut -b -6)
    echo "  未定義 GOOGLE_PROJECT_ID.   由系統自動產生...(GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID)" 
  else
    echo "  系統參數 GOOGLE_PROJECT_ID  已設定...........(GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID)" 
  fi

  gcloud config set project $GOOGLE_PROJECT_ID
}

checkProject
