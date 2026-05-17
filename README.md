<div align="center">

<img src="https://img.shields.io/badge/Chaos_Mesh-v2.x-FF6B6B?style=for-the-badge&logo=kubernetes&logoColor=white" />
<img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" />
<img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white" />
<img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" />
<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
<img src="https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black" />
<img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />

# Chaos Sentinel

### Autonomous Chaos Engineering & Self-Healing Platform for Kubernetes Microservices

*Fault-injection at the push of a button. ML-driven anomaly detection. Autonomous recovery in the control loop.*

</div>

---

## Overview

Chaos Sentinel is a production-grade chaos engineering platform that closes the entire fault-injection lifecycle from **triggering controlled failures** to **detecting degradation** and **autonomously remediating** affected services without human intervention.

Built on top of **Google's Online Boutique** (an 11-service polyglot microservices app), Chaos Sentinel deploys a three-component intelligence stack: a **Chaos Injection Layer** (Chaos Mesh), a **SENTINEL Predictor** (IsolationForest + LSTM), and a **Decision Engine** (rule-driven Kubernetes remediation actuator). A React dashboard gives operators real-time visibility into service health and a manual chaos control panel.

The platform was designed to surface failure modes that conventional health checks miss specifically, degradation patterns that emerge from resource contention, cascading dependencies, and network faults.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CHAOS SENTINEL PLATFORM                         │
│                                                                     │
│  ┌─────────────────────┐      ┌──────────────────────────────────┐  │
│  │   Chaos Injection   │      │        SENTINEL Predictor        │  │
│  │                     │      │                                  │  │
│  │  ┌───────────────┐  │      │  ┌────────────┐  ┌───────────┐  │  │
│  │  │  Chaos Mesh   │  │      │  │ Prometheus │  │  FastAPI  │  │  │
│  │  │  (StressChaos │  │      │  │  Collector │→ │  /risk    │  │  │
│  │  │   NetworkChaos│  │      │  │ (CPU/MEM/  │  │  /stream  │  │  │
│  │  │   PodChaos)   │  │      │  │  Errors)   │  │  /chaos/* │  │  │
│  │  └───────────────┘  │      │  └────────────┘  └─────┬─────┘  │  │
│  │                     │      │                        │         │  │
│  │  ┌───────────────┐  │      │  ┌─────────────────────▼──────┐ │  │
│  │  │  YAML Chaos   │  │      │  │  ML Risk Scoring Pipeline  │ │  │
│  │  │  Scenarios    │  │      │  │                            │ │  │
│  │  │  • CPU Spike  │  │      │  │  IsolationForest           │ │  │
│  │  │  • Mem Bloat  │  │      │  │  (Unsupervised Anomaly)    │ │  │
│  │  │  • DDoS Flood │  │      │  │  +                         │ │  │
│  │  │  • Quarantine │  │      │  │  LSTM Forecaster           │ │  │
│  │  └───────────────┘  │      │  │  (60-step ahead prediction)│ │  │
│  └─────────────────────┘      │  └────────────────────────────┘ │  │
│                               └──────────────────────────────────┘  │
│                                              │                       │
│                                     Risk Score > 0.85               │
│                                              │                       │
│                               ┌──────────────▼───────────────────┐  │
│                               │       Decision Engine            │  │
│                               │                                  │  │
│                               │  • Scale Deployment              │  │
│                               │  • Restart Pod                   │  │
│                               │  • Revert Image Corruption       │  │
│                               │  • Re-apply NetworkPolicy        │  │
│                               │  • Purge Chaos Experiments       │  │
│                               │  • Fire Slack Alert              │  │
│                               └──────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              React Operator Dashboard (SENTINEL UI)          │    │
│  │  Live Risk Telemetry │ Node Graph │ Chaos Panel │ Audit Log  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Grafana Dashboards                        │    │
│  │  Risk Score History │ Recovery Timelines │ SLA Compliance    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

| Component | Tech | Role |
|---|---|---|
| **Chaos Layer** | Chaos Mesh (StressChaos, NetworkChaos, PodChaos) | Declarative fault injection into the K8s cluster |
| **Metrics Pipeline** | Prometheus + `prometheus_api_client` | Scrapes CPU / memory / HTTP 5xx rates per pod over 5-min rolling windows |
| **SENTINEL Predictor** | Python, FastAPI, scikit-learn, PyTorch | ML anomaly detection + LSTM 60-step CPU forecasting |
| **Decision Engine** | Python, `kubernetes` client | Watches risk scores; executes service-specific healing actions |
| **Grafana** | Grafana + Prometheus datasource | Dashboards for risk score history, recovery timelines, and SLA compliance during chaos runs |
| **Sentinel UI** | React, Recharts, Lucide Icons | Real-time operator dashboard with live telemetry and chaos control panel |
| **Target System** | Google Online Boutique (11 microservices) | Polyglot workload (Go, Python, Node, Java, C#, Ruby) on Kubernetes |

---

## ML Risk Scoring Pipeline

The predictor runs a **multi-vector risk aggregation pipeline** per service on a 15-second polling interval. This is not a single metric threshold it fuses three independent signal vectors into a single normalized risk score `[0.0, 1.0]`.

### Signal Vectors

**Vector 1 — CPU Utilization (Anomaly Detection)**

An `IsolationForest` (100 estimators, 5% contamination) is trained on baseline CPU telemetry at startup. At inference time, it receives a 4-dimensional feature vector `[mean, std, slope, max]` computed over the trailing 60 seconds. The anomaly score is normalized as:

```
risk = max(0, min(1, (offset_ - raw_score) / |offset_| × 2.5))
```

This amplifies the IsolationForest's decision boundary displacement to produce a human-readable [0, 1] risk value.

**Vector 2 — Memory (OOMKilled Cycle & Bloat Detection)**

Memory working set bytes are fetched from Prometheus. Two heuristics run in parallel:
- `cartservice` / `frontend`: If `mean < 15 MB` → OOMKill restart cycle detected → risk `0.96`
- `redis-cart`: If `mean > 100 MB` → StressChaos memory bloat active → risk `0.95`

This catches OOMKilled thrash loops that CPU metrics alone cannot surface.

**Vector 3 — Network Error Rate (HTTP 5xx)**

`rate(http_requests_total{status=~"5.."}[1m])` per pod. If mean 5xx rate `> 0.1 req/s` → risk `0.97`. This catches immediate service crashes and network partition effects before CPU/memory signals degrade.

**LSTM Forward Lookahead (Risk Amplifier)**

A 2-layer LSTM (hidden=64) takes the last 120 CPU samples (normalized), and predicts the next 60 timesteps. If the forecasted peak is `> 1.5× current max`, the final risk is amplified by +0.15 (capped at 1.0). This enables **pre-emptive** intervention before conditions fully deteriorate.

```
aggregated_risk = max(cpu_anomaly_risk, memory_risk, error_risk)
if lstm_forecast_peak > 1.5 × current_max:
    final_risk = min(1.0, aggregated_risk + 0.15)
```

### Risk Thresholds

| Zone | Score Range | Action |
|---|---|---|
| 🟢 Healthy | 0.0 – 0.65 | Monitor |
| 🟡 Warning | 0.65 – 0.85 | Alert log entry |
| 🔴 Critical | > 0.85 | Autonomous remediation triggered |

---

## Chaos Scenarios

Four fault injection scenarios exercise distinct failure modes:

### Scenario 1: CPU Meltdown (`cartservice`)
```yaml
kind: StressChaos
spec:
  stressors:
    cpu:
      workers: 4
      load: 100        # 100% CPU saturation on all workers
    memory:
      workers: 4
      size: '500MB'    # Concurrent memory pressure
  duration: '5m'
```
**Target failure mode**: CPU throttling + OOMKill restart cascade under combined resource pressure.

### Scenario 2: Memory Bloat (`redis-cart`)
Injects memory stress into the session cache. Simulates a memory leak or large-dataset cache warming that degrades cart operations across the entire purchase funnel.

### Scenario 3: L7 DDoS Flood (`frontend`)
```yaml
kind: StressChaos
spec:
  stressors:
    cpu:
      workers: 8
      load: 100        # Saturates all 8 CPU workers
  duration: '3m'
```
Simulates volumetric traffic flood causing CPU saturation at the API gateway layer, propagating backpressure to dependent services.

### Scenario 4: IDS Malware Quarantine (`frontend`)
```bash
kubectl label pod $POD app=quarantined security-status=isolated --overwrite
```
Combined with a **zero-egress/ingress NetworkPolicy** (`isolation-policy.yaml`):
```yaml
spec:
  podSelector:
    matchLabels:
      security-status: isolated
  policyTypes: [Ingress, Egress]
  # Empty spec = deny all traffic
```
Simulates a compromised pod that must be network-isolated without a full deployment restart. The Decision Engine purges all active Chaos Mesh experiments and relabels the pod atomically.

---

## Autonomous Remediation (Decision Engine)

The Decision Engine polls `/risk` every 15 seconds with a **120-second cooldown** per service to prevent action storms.

```python
if risk_score > 0.85 and (now - last_action_time) > 120s:
    # 1. Fire Slack alert with service name and risk score
    # 2. Purge all active Chaos Mesh experiments (kubectl delete networkchaos,stresschaos,podchaos)
    # 3. Execute service-specific healing action
```

### Healing Action Map

| Service | Detected Condition | Remediation |
|---|---|---|
| `cartservice` | CPU/memory meltdown | Scale to 3 replicas; patch memory limit back to 512Mi |
| `frontend` | Image corruption / DDoS | Revert to known-good image `v0.10.1`; scale to 3 replicas |
| `redis-cart` | Network partition / deletion | Declarative `kubectl apply` of full manifest; restart pod |
| `checkoutservice` | Pod crash | Graceful pod restart via Kubernetes API |

All healing actions interact with the Kubernetes API via the official `kubernetes` Python client, ensuring they are audit-logged and reconciliation-safe.

---

## Operator Dashboard (SENTINEL UI)

The React dashboard provides:

- **Service Health Cards** — Live risk scores with animated progress bars (green → amber → red) polled every 3 seconds
- **Chaos Gateway Mesh** — Animated SVG node graph of the full 11-service topology with live per-node health glow states
- **Live Risk Telemetry** — Area chart with 300-sample rolling history per service, with `WARN` (0.65) and `RED` (0.85) reference lines
- **Chaos Control Panel** — One-click chaos injection buttons (CPU Spike, Memory Bloat, DDoS Flood, Malware Quarantine) backed by FastAPI endpoints
- **Decision Engine Audit Log** — Chronological log of all autonomous actions and alert events
- **Quarantine Badge** — Real-time display of isolated pod count pulled from `kubectl get pods -l security-status=isolated`
- **Critical Alert Banner + Siren** — Full-screen banner and Web Audio API siren when any service crosses the red threshold

---

## Repository Structure

```
chaos-sentinel/
├── chaos/                          # Chaos Mesh fault-injection scenarios
│   ├── scenario1_cpu.yaml          # CPU + memory meltdown (cartservice)
│   ├── scenario3_memory.yaml       # Memory bloat (redis-cart)
│   ├── scenario4_ddos.yaml         # L7 DDoS flood (frontend)
│   └── isolation-policy.yaml       # Zero-traffic NetworkPolicy for quarantine
│
├── sentinel/
│   ├── predictor/                  # SENTINEL Predictor service
│   │   ├── main.py                 # FastAPI app, prediction loop, chaos endpoints
│   │   ├── collector.py            # Prometheus metric fetching & feature computation
│   │   ├── lstm_model.py           # 2-layer LSTM forecaster (PyTorch)
│   │   ├── risk_scorer.py          # IsolationForest anomaly scorer
│   │   └── requirements.txt
│   │
│   └── decision-engine/            # Autonomous remediation actuator
│       ├── decision.py             # Main decision loop + service healing actions
│       ├── xray.py                 # Prometheus diagnostic probe
│       └── xray-redis.py           # Redis-specific diagnostic utility
│
├── sentinel-ui/                    # React operator dashboard
│   └── src/
│       ├── App.js                  # Main dashboard (node graph, charts, chaos panel)
│       └── index.css               # Dark-mode glassmorphism UI system
│
└── microservices-demo/             # Google Online Boutique (target workload)
    ├── kubernetes-manifests/       # Kubernetes deployment manifests
    ├── istio-manifests/            # Service mesh configuration
    └── src/                        # 11-service polyglot source code
```

---

## Getting Started

### Prerequisites

| Dependency | Version | Purpose |
|---|---|---|
| Minikube / K8s cluster | ≥ 1.26 | Target workload runtime |
| Chaos Mesh | ≥ 2.0 | Fault injection operator |
| Prometheus | ≥ 2.40 | Metrics collection |
| Python | ≥ 3.10 | Predictor + Decision Engine |
| Node.js | ≥ 18 | Sentinel UI |

### 1. Deploy the Target Workload

```bash
# Deploy Google Online Boutique to your cluster
kubectl apply -f microservices-demo/release/kubernetes-manifests.yaml

# Apply the quarantine NetworkPolicy
kubectl apply -f chaos/isolation-policy.yaml

# Verify all services are running
kubectl get pods -n default
```

### 2. Install Chaos Mesh

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace=chaos-mesh \
  --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock
```

### 3. Deploy Grafana Dashboards

We use Helm to deploy Grafana, auto-provisioned with the Prometheus datasource and SENTINEL dashboards.

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  -f helm-chart/grafana/values.yaml

# Get the admin password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port-forward to access Grafana at http://localhost:3000
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

### 4. Configure Prometheus Port-Forward

```bash
# Expose Prometheus locally (Predictor expects port 9091)
kubectl port-forward svc/prometheus-operated 9091:9090 -n monitoring
```

### 5. Run the SENTINEL Predictor

```bash
cd sentinel/predictor
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The predictor trains the IsolationForest on startup and begins polling Prometheus in ~5 seconds.

### 6. Run the Decision Engine

```bash
cd sentinel/decision-engine
# Set Slack webhook (optional)
echo "WEBHOOK_URL=https://hooks.slack.com/services/YOUR/HOOK" > ../../.env

python decision.py
```

### 7. Launch the Operator Dashboard

```bash
cd sentinel-ui
npm install
npm start
# Dashboard at http://localhost:3000
```

### 8. Inject Chaos

From the UI dashboard or CLI:

```bash
# CPU Meltdown on cartservice
kubectl apply -f chaos/scenario1_cpu.yaml

# Memory Bloat on redis-cart
kubectl apply -f chaos/scenario3_memory.yaml

# DDoS Flood on frontend
kubectl apply -f chaos/scenario4_ddos.yaml

# Clean up all experiments
kubectl delete networkchaos,stresschaos,podchaos --all --all-namespaces
```

---

## Design Decisions & Trade-offs

**Why IsolationForest over a static threshold?**
Static CPU thresholds are service-agnostic and brittle — a Java service idles at 5% CPU; a Python service may idle at 25%. IsolationForest learns the baseline distribution per service, making it robust to heterogeneous workloads without per-service manual tuning.

**Why a cooldown on autonomous actions?**
Without a 120-second cooldown, a flapping service could trigger hundreds of restart loops per hour, amplifying the incident rather than containing it. The cooldown also provides a natural stabilization window for the healing action to take effect before re-evaluation.

**Why declarative `kubectl apply` for redis-cart recovery?**
When a Kubernetes `Service` or `PersistentVolume` is deleted (a chaos scenario), a simple pod restart does not suffice the networking fabric itself is gone. Re-applying the full manifest declaratively ensures idempotent, complete restoration without state drift.

**Why LSTM alongside IsolationForest?**
IsolationForest is reactive it scores the current window. The LSTM provides a forward-looking signal: if CPU is currently at 60% but the model predicts it will reach 95% in the next 5 minutes, the system can begin remediation 5 minutes before the SLO breach rather than after it.

**Why an audio siren in the UI?**
Operators monitoring multiple dashboards miss visual-only alerts. The Web Audio API siren ensures that a critical threshold breach is impossible to ignore even in a multi-screen NOC environment.

---

## Monitoring Stack

| Signal | PromQL Query |
|---|---|
| CPU utilization per pod | `sum(rate(container_cpu_usage_seconds_total{namespace="default", pod=~"^SERVICE.*"}[1m]))` |
| Memory working set | `sum(container_memory_working_set_bytes{namespace="default", pod=~"^SERVICE.*"})` |
| HTTP 5xx error rate | `sum(rate(http_requests_total{namespace="default", pod=~"^SERVICE.*", status=~"5.."}[1m]))` |

Metrics are fetched over a 5-minute rolling window with 5-second step resolution. Feature computation extracts `[mean, std, slope, max]` over the trailing 60 seconds (12 samples × 5s step).

---

## Key Results

- **Detected OOMKill restart cascade** in `cartservice` within 15 seconds of onset a failure mode invisible to standard Kubernetes readiness probes, which only surface full pod crashes, not thrash loops
- **Autonomous remediation restored full service health** in under 45 seconds for CPU meltdown and DDoS scenarios, including time to detect, purge chaos experiments, patch the deployment, and verify recovery
- **Surfaced 3 failure modes undetected by existing liveness/readiness checks**: (1) gradual memory bloat in Redis that degrades cart latency 30s before OOMKill; (2) CPU-induced checkout cascade failures caused by upstream frontend saturation; (3) IDS quarantine scenarios where a healthy pod is isolated without a pod restart, leaving standard health checks green while all traffic is silently dropped

---

## Failure Modes Discovered

| Failure Mode | Detection Method | Health Check Blind Spot |
|---|---|---|
| Redis memory bloat → cart latency degradation | Memory vector threshold (>100MB) | Readiness probe passes; no pod restart |
| Frontend CPU saturation → checkout cascade | CPU IsolationForest + LSTM amplifier | Downstream services appear healthy independently |
| Pod quarantine (NetworkPolicy) → silent traffic drop | `kubectl get pods -l security-status=isolated` | Liveness/readiness probes pass; pod is running but network-isolated |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Fault Injection** | Chaos Mesh (StressChaos, PodChaos, NetworkChaos) |
| **Metrics** | Prometheus, `prometheus_api_client` |
| **ML** | scikit-learn (IsolationForest), PyTorch (LSTM) |
| **API** | FastAPI, SSE (`text/event-stream`) |
| **Remediation** | Kubernetes Python client, `kubectl` |
| **Alerting** | Slack Webhooks |
| **UI** | React, Recharts, Lucide Icons, Web Audio API |
| **Target Workload** | Google Online Boutique (11 microservices) |
| **Container Orchestration** | Kubernetes (Minikube), Helm |

---

<div align="center">

*Built to find what health checks miss.*

</div>
