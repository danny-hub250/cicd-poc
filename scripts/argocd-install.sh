#!/bin/bash
# jumpbox VM에서 1회 수동 실행. 사전 조건: vm-init.sh 실행 완료(kubectl/helm 설치됨) +
# `az aks get-credentials --resource-group <app-rg> --name <aks_cluster_name>` 로 kubeconfig 확보.
set -euo pipefail

echo ">>> Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo ">>> Installing ArgoCD (stable manifests)..."
# server-side apply 사용: client-side apply는 last-applied-configuration 어노테이션에
# 전체 매니페스트를 저장하는데, applicationsets.argoproj.io CRD가 커서 256KiB 어노테이션
# 제한을 넘어 실패한다 (metadata.annotations: Too long).
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ">>> Waiting for argocd-server rollout..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo ">>> Exposing argocd-server via LoadBalancer (POC 용, 운영에서는 Ingress+TLS 권장)..."
kubectl -n argocd patch svc argocd-server -p '{"spec": {"type": "LoadBalancer"}}'

echo ">>> Waiting for external IP..."
for i in $(seq 1 30); do
  IP=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  [ -n "$IP" ] && break
  sleep 10
done

echo "=== ArgoCD UI: https://${IP:-<pending>} ==="
echo "=== admin password: ==="
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo

echo ">>> Registering the employee-app Application..."
kubectl apply -f "$(dirname "$0")/../argocd/application.yaml"

echo ">>> Done. Check sync status with: kubectl -n argocd get application employee-app"
