#!/bin/bash
set -eo pipefail

echo "========================================================"
echo "🛡️ Deploying Chaos Sentinel Monitoring Stack"
echo "========================================================"

# Check for required tools
command -v kubectl >/dev/null 2>&1 || { echo >&2 "❌ kubectl is required but it's not installed. Aborting."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo >&2 "❌ helm is required but it's not installed. Aborting."; exit 1; }

echo "📦 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "🚀 Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "⚙️ Applying custom Prometheus & AlertManager configurations..."
# In a real environment, we would use ConfigMaps/Secrets for these.
# For this setup, we apply them via the helm values.

echo "📊 Installing kube-prometheus-stack (Prometheus, AlertManager, Grafana)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f ../monitoring/prometheus/kube-prometheus-stack-values.yaml \
  --set alertmanager.config.global.slack_api_url="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/mock/webhook}" \
  --wait

echo "✅ Monitoring stack deployed successfully."
echo ""
echo "To access Grafana (admin/admin):"
echo "  kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo ""
echo "To access Prometheus UI:"
echo "  kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
echo ""
echo "To access AlertManager UI:"
echo "  kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring"
