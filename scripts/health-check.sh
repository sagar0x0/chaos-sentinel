#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================================"
echo "🩺 Chaos Sentinel Health Check"
echo "========================================================"

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 is Healthy${NC}"
    else
        echo -e "${RED}✗ $1 is Failing${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}1. Checking Kubernetes Nodes...${NC}"
kubectl get nodes

echo -e "\n${YELLOW}2. Checking Microservices Workload (default namespace)...${NC}"
kubectl get pods -n default
if [ $(kubectl get pods -n default --field-selector=status.phase!=Running | wc -l) -gt 1 ]; then
    echo -e "${RED}✗ Some microservices are not running normally.${NC}"
else
    echo -e "${GREEN}✓ All microservices are running.${NC}"
fi

echo -e "\n${YELLOW}3. Checking Monitoring Stack (monitoring namespace)...${NC}"
kubectl get pods -n monitoring
if [ $(kubectl get pods -n monitoring --field-selector=status.phase!=Running | wc -l) -gt 1 ]; then
    echo -e "${RED}✗ Monitoring stack has issues.${NC}"
else
    echo -e "${GREEN}✓ Monitoring stack is fully operational.${NC}"
fi

echo -e "\n${YELLOW}4. Validating Prometheus Configurations...${NC}"
# Use promtool to check alerting rules if available locally
if command -v promtool >/dev/null 2>&1; then
    promtool check rules ../monitoring/alertmanager/alert_rules.yaml
    check_status "Alert Rules syntax"
else
    echo -e "${YELLOW}promtool not installed locally, skipping rule syntax check.${NC}"
fi

echo -e "\n${YELLOW}5. Checking AlertManager Integration...${NC}"
if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo -e "${YELLOW}⚠ SLACK_WEBHOOK_URL is not set. Slack alerts will fail.${NC}"
else
    echo -e "${GREEN}✓ Slack webhook is configured.${NC}"
fi

echo -e "\n========================================================"
echo -e "${GREEN}Health Check Complete.${NC}"
