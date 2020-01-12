#!/bin/bash

KUBECTL_OPERATION=""
STRIMZI_VERSION="0.15.0"
STRIMZI_FILE="strimzi-cluster-operator-$STRIMZI_VERSION.yaml"
STRIMZI_OPERATOR_BASE_DOWNLOAD_URL="https://github.com/strimzi/strimzi-kafka-operator/releases/download"
STRIMZI_OPERATOR_DOWNLOAD_URL="$STRIMZI_OPERATOR_BASE_DOWNLOAD_URL/$STRIMZI_VERSION/$STRIMZI_FILE"
STRIMZI_NAMESPACE="default"

# $1: message
function __log__() {
  printf "[$(date '+%d/%m/%Y %H:%M:%S')] -> $1\n"
}

# =======================================================================================================
# ========================================= STRIMZI HELPER MENU =========================================
# =======================================================================================================
while getopts 'o:v:n:h' opt
do
  case $opt in
    o)
       KUBECTL_OPERATION=$OPTARG;;
    v)
       STRIMZI_VERSION=$OPTARG
       STRIMZI_FILE="strimzi-cluster-operator-$STRIMZI_VERSION.yaml"
       STRIMZI_OPERATOR_DOWNLOAD_URL="$STRIMZI_OPERATOR_BASE_DOWNLOAD_URL/$STRIMZI_VERSION/$STRIMZI_FILE";;
    n)
       STRIMZI_NAMESPACE=$OPTARG;;
    h|?)
       echo "USAGE: ./strimzi_helper -o [operation] -v [version] -n [namespace] -h";;
  esac
done
# =========================================================================================================

if [[ "$KUBECTL_OPERATION" == "" ]]; then
  printf "USAGE: ./strimzi_helper \n\t%s \n\t%s \n\t%s \n\t%s\n" \
       "-o [operation] (apply or delete)" \
       "-v [strimzi_version] (optional) -> Valid Strimzi version (default: 0.15.0)" \
       "-n [kubernetes_namespace] (optional) -> Kubernetes deployment namespace for Strimzi (default: default)" \
       "-h Strimzi helper manual"
else
  __log__ "Kubectl Operation: ${KUBECTL_OPERATION}"
  __log__ "Strimzi Operator Version: ${STRIMZI_VERSION}"
  __log__ "Strimzi Operator Download Url: ${STRIMZI_OPERATOR_DOWNLOAD_URL}"
  __log__ "Strimzi Operator Deployment File: ${STRIMZI_FILE}"
  __log__ "Strimzi Operator Deployment Namespace: ${STRIMZI_NAMESPACE}"

  if [[ ! -f $STRIMZI_FILE ]]; then
    __log__ "Downloading $STRIMZI_OPERATOR_DOWNLOAD_URL..."
    wget $STRIMZI_OPERATOR_DOWNLOAD_URL &> /dev/null
  fi

  sed 's/namespace: .*/namespace: '$STRIMZI_NAMESPACE'/' $STRIMZI_FILE > $STRIMZI_FILE.copy
  mv $STRIMZI_FILE.copy $STRIMZI_FILE

  __log__ "Installing resources to Kubernetes cluster:\n"
  kubectl $KUBECTL_OPERATION -f $STRIMZI_FILE -n $STRIMZI_NAMESPACE
fi