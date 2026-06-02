# Chaos Sentinel: SLI & SLO Framework

This document outlines the Service Level Indicators (SLIs) and Service Level Objectives (SLOs) for the core microservices monitored by the Chaos Sentinel platform.

## Definitions

*   **SLI (Service Level Indicator):** A quantitative measure of some aspect of the level of service that is provided (e.g., error rate, latency).
*   **SLO (Service Level Objective):** A target value or range of values for a service level that is measured by an SLI (e.g., 99.9% availability).
*   **Error Budget:** The allowable threshold for errors and outages over a specific window before consequences are triggered (100% - SLO).

## Core SLIs

### 1. Availability (Success Rate)
The proportion of valid requests served successfully without a 5xx error.

*   **Metric:** HTTP 5xx responses vs. total HTTP requests.
*   **PromQL:**
    ```promql
    1 - (
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total[5m]))
    )
    ```

### 2. Latency (Responsiveness)
The time it takes to serve a request, measured at the 99th percentile (p99).

*   **Metric:** HTTP request duration histogram.
*   **PromQL:**
    ```promql
    histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
    ```

## Microservice SLO Targets

| Service | Availability SLO (30-day) | Latency SLO (p99) | Error Budget (30-day) |
| :--- | :--- | :--- | :--- |
| **Frontend** | 99.9% | < 500ms | 43.2 minutes |
| **CartService** | 99.95% | < 200ms | 21.6 minutes |
| **CheckoutService** | 99.99% | < 1000ms | 4.3 minutes |
| **Redis-Cart** | 99.99% | < 50ms | 4.3 minutes |

## Error Budget Burn Rate Alerting

We utilize Multi-Window, Multi-Burn-Rate alerting to detect SLO breaches proactively without alert fatigue.

| Burn Rate | Time Window | Alert Severity | Action |
| :--- | :--- | :--- | :--- |
| **14.4x** | 1 hour | Critical | Immediate page (Slack `#alerts-critical`). Indicates 2% budget consumed in 1h. |
| **6x** | 6 hours | Critical | Immediate page. Indicates 5% budget consumed in 6h. |
| **3x** | 3 days | Warning | Ticket created. Indicates 10% budget consumed in 3d. |
| **1x** | 30 days | Info | No immediate action. Review in weekly SRE sync. |

*Reference: The `SLOBreach` rule in `alert_rules.yaml` implements the 14.4x burn rate alert.*
