#!/bin/bash
# jumpbox VM에서 1회 수동 실행. employee-app이 쓰는 DB/Foundry 접속 정보를
# k8s Secret으로 생성한다 (git에는 절대 커밋하지 않음).
#
# 사용법: 아래 환경변수를 채운 뒤 실행
#   DB_HOST=<terraform output postgresql_fqdn> \
#   DB_PASSWORD=<db_admin_password> \
#   FOUNDRY_ENDPOINT=<terraform output foundry_endpoint> \
#   FOUNDRY_API_KEY=<terraform output foundry_primary_access_key> \
#   FOUNDRY_DEPLOYMENT=<terraform output foundry_deployment_name> \
#   ./create-app-secret.sh
set -euo pipefail

: "${DB_HOST:?DB_HOST is required (terraform output postgresql_fqdn)}"
: "${DB_PASSWORD:?DB_PASSWORD is required (db_admin_password)}"
: "${FOUNDRY_ENDPOINT:?FOUNDRY_ENDPOINT is required (terraform output foundry_endpoint)}"
: "${FOUNDRY_API_KEY:?FOUNDRY_API_KEY is required (terraform output foundry_primary_access_key)}"
: "${FOUNDRY_DEPLOYMENT:?FOUNDRY_DEPLOYMENT is required (terraform output foundry_deployment_name)}"

DB_NAME="${DB_NAME:-cicd_poc_db}"
DB_USER="${DB_USER:-psqladmin}"

kubectl create namespace cicd-poc --dry-run=client -o yaml | kubectl apply -f -

kubectl -n cicd-poc create secret generic employee-app-secrets \
  --from-literal=DB_HOST="$DB_HOST" \
  --from-literal=DB_NAME="$DB_NAME" \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=FOUNDRY_ENDPOINT="$FOUNDRY_ENDPOINT" \
  --from-literal=FOUNDRY_API_KEY="$FOUNDRY_API_KEY" \
  --from-literal=FOUNDRY_DEPLOYMENT="$FOUNDRY_DEPLOYMENT" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">>> Secret cicd-poc/employee-app-secrets applied."
