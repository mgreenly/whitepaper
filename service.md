# Platform Automation Orchestrator Service

## Table of Contents

- [Overview](#overview)
- [Current Implementation Status](#current-implementation-status)
- [Core API Specification](#core-api-specification)
- [Architecture & Technology Stack](#architecture--technology-stack)
- [Implementation Requirements](#implementation-requirements)
- [Performance & Success Metrics](#performance--success-metrics)
- [Deployment Configuration](#deployment-configuration)

## Overview

The Platform Automation Orchestrator (PAO) is a cloud-native REST service that transforms manual provisioning processes into automated self-service workflows by providing a document-driven convergence point where platform teams define services through Schema v2.0 YAML documents.

**Business Problem**: 2-3 week provisioning delays due to fragmented JIRA workflows across platform teams  
**Solution**: Central orchestration service enabling binary fulfillment (manual JIRA or complete automation)  
**Value**: 90%+ reduction in provisioning time (weeks to hours)

For strategic context see [whitepaper.md](whitepaper.md). For catalog design see [catalog.md](catalog.md).

## Current Implementation Status

**Q3 2025 (Aug-Oct) - Current Work**
- ✅ Basic Kubernetes infrastructure deployed
- ✅ Empty REST service with health endpoints
- 🚧 Core action types (JIRA, REST API, basic automation)
- 🚧 Dynamic form generation with basic field types
- 🚧 Catalog browsing and request management APIs
- 🚧 Basic IAM authentication

**Q4 2025 (Nov-Jan) - Planned**
- PostgreSQL state persistence with connection pooling
- Redis caching layer for performance
- Circuit breaker architecture for reliability
- Comprehensive retry logic and error handling
- Monitoring with Prometheus metrics and structured logging

**Future Work (2026+)**
- Full RBAC implementation
- Enterprise governance and compliance
- Advanced workflow management
- Multi-environment orchestration

## Core API Specification

### Essential APIs (Q3/Q4 Implementation)

**Catalog Management**
```http
GET    /api/v1/catalog                           # Browse available services
GET    /api/v1/catalog/items/{item_id}           # Service details
GET    /api/v1/catalog/items/{item_id}/schema    # Dynamic form schema
POST   /api/v1/catalog/refresh                   # Force catalog refresh
```

**Request Lifecycle**
```http
POST   /api/v1/requests                          # Submit service request
GET    /api/v1/requests                          # List user requests
GET    /api/v1/requests/{request_id}             # Request details
GET    /api/v1/requests/{request_id}/status      # Current status
GET    /api/v1/requests/{request_id}/logs        # Execution logs
```

**System Health**
```http
GET    /api/v1/health                            # Service health status
GET    /api/v1/health/ready                      # Readiness probe
GET    /api/v1/metrics                           # Prometheus metrics
GET    /api/v1/version                           # Service version info
```

**Platform Team Tools**
```http
POST   /api/v1/validate/catalog-item             # Validate service definition
POST   /api/v1/preview/form                      # Preview form generation
POST   /api/v1/test/variables                    # Test variable substitution
```

**Integration Webhooks**
```http
POST   /api/v1/webhooks/github                   # GitHub events
POST   /api/v1/webhooks/jira                     # JIRA status updates
POST   /api/v1/webhooks/terraform                # Terraform notifications
```

### Authentication & Authorization

**Current (Q3/Q4)**
- AWS IAM authentication with SigV4 request signing
- Basic access validation
- CloudTrail audit logging

**Future**
- Role-based access control (RBAC)
- Team-based access isolation
- Enterprise compliance frameworks

## Architecture & Technology Stack

### Core Design Principles
1. **Schema-Driven**: All services defined via Schema v2.0 YAML documents
2. **Binary Fulfillment**: Either manual JIRA OR complete automation (no partial states)
3. **Document-Driven Convergence**: Platform teams collaborate through central document store
4. **Progressive Enhancement**: Teams evolve from manual to automated at their own pace
5. **Cloud-Native**: Kubernetes-ready with horizontal scaling and zero-downtime deployments

### Service Components

**Catalog Management Engine**
- GitHub repository integration with webhook processing
- Schema v2.0 validation and error reporting
- Multi-tier caching (Redis + PostgreSQL)
- CODEOWNERS enforcement for governance

**Request Orchestration System**
- Request lifecycle: Submitted → Validation → Queued → In Progress → Completed/Failed
- Variable substitution with 8+ scopes (user, metadata, request, system, etc.)
- Circuit breaker architecture for external service calls
- State tracking and audit trail

**Multi-Action Fulfillment Engine**
- 5+ action types: JIRA, REST API, Terraform, GitHub workflows, webhooks
- Sequential execution with dependency management
- Retry logic with exponential backoff
- Automated rollback capabilities

### Technology Stack

**Runtime & Framework**
- Go programming language
- Gin web framework
- OpenAPI 3.0 specification
- JSON Schema validation

**Data Storage**
- PostgreSQL 14+ (primary database)
- Redis Cluster 7+ (caching layer)
- JSONB support for flexible state storage

**External Integrations**
- GitHub/GitLab webhooks
- JIRA REST API
- Terraform Cloud API
- HashiCorp Vault (secrets)

**Deployment**
- Kubernetes 1.24+
- Helm 3+ charts
- NGINX Ingress Controller
- Prometheus + Grafana monitoring

### Schema v2.0 Integration

PAO implements the Schema v2.0 specification from [catalog.md](catalog.md):

- **Metadata**: Service identification, ownership, SLA commitments
- **Presentation**: Dynamic form generation with conditional logic and validation
- **Fulfillment**: Binary model supporting manual JIRA and automated actions
- **Lifecycle**: Deprecation and versioning management
- **Monitoring**: Health checks and observability configuration

### Action Types

1. **JIRA Ticket Creation**: Multi-instance integration with variable templating
2. **REST API Integration**: HTTP calls with OAuth2/API key authentication
3. **Terraform Configuration**: Infrastructure provisioning with repository mapping
4. **GitHub Workflow Dispatch**: GitHub Actions integration with status monitoring
5. **Webhook Invocation**: HMAC-secured webhooks for system notifications

### Variable System

Supports 8+ variable scopes:
- `{{fields.field_id}}` - User form input
- `{{metadata.id}}` - Service metadata
- `{{request.id}}` - Request context
- `{{system.date}}` - System variables
- `{{env.VAR}}` - Environment variables
- `{{output.action_id.field}}` - Previous action outputs

## Implementation Requirements

### Q3 2025 Deliverables (Current)

**Core API Endpoints**
- Catalog browsing and service discovery
- Request submission and status tracking
- Health checks and metrics export
- Basic form generation from Schema v2.0
- Platform team validation tools

**Action Type Implementation**
- JIRA ticket creation with variable substitution
- REST API calls with authentication
- Basic webhook invocation
- GitHub workflow dispatch

**Infrastructure Components**
- GitHub repository integration with webhooks
- Basic catalog caching (Redis)
- Request state tracking (PostgreSQL)
- Kubernetes deployment with health probes

### Q4 2025 Deliverables (Planned)

**Reliability & Performance**
- Circuit breaker architecture for external calls
- Comprehensive retry logic with exponential backoff
- Connection pooling for PostgreSQL
- Distributed Redis caching

**Monitoring & Observability**
- Prometheus metrics export
- Structured JSON logging with correlation IDs
- Performance monitoring and alerting
- Business intelligence dashboard

**Security & Compliance**
- AWS IAM authentication with SigV4 signing
- CloudTrail audit logging
- Secret management via HashiCorp Vault
- Container security hardening

### Database Schema

**Requests Table**
```sql
CREATE TABLE requests (
    id UUID PRIMARY KEY,
    catalog_item_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    request_data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP
);
```

**Request Actions Table**
```sql
CREATE TABLE request_actions (
    id UUID PRIMARY KEY,
    request_id UUID REFERENCES requests(id),
    action_type VARCHAR(100) NOT NULL,
    action_config JSONB NOT NULL,
    status VARCHAR(50) NOT NULL,
    output JSONB,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);
```

### Configuration Requirements

**Environment Variables**
```bash
DATABASE_URL=postgresql://user:pass@host:5432/pao
REDIS_URL=redis://host:6379
GITHUB_WEBHOOK_SECRET=xxx
JIRA_API_TOKEN=xxx
VAULT_ADDR=https://vault.company.com
```

**Helm Values**
```yaml
image:
  repository: platform/orchestrator
  tag: v2.1.0

replicas: 3

resources:
  requests:
    memory: 512Mi
    cpu: 250m
  limits:
    memory: 1Gi
    cpu: 500m
```

## Performance & Success Metrics

### Performance Targets
- **API Response Time**: <200ms for catalog operations (P95)
- **Request Submission**: <2s for request processing (P99)
- **System Availability**: 99.9% uptime with zero-downtime deployments
- **Throughput**: Support 1000+ concurrent requests
- **Status Polling**: <50ms response with Redis caching

### Business Impact Metrics
- **Provisioning Time**: Reduce from 2-3 weeks to <4 hours (90%+ improvement)
- **Platform Adoption**: 100% of platform teams onboarded with ≥1 service
- **Developer Satisfaction**: >4.5/5 rating on self-service experience
- **Automation Rate**: 80%+ of services automated within 12 months

### Operational Excellence
- **Error Rate**: <5% failure rate for automated actions
- **Security Compliance**: Zero security incidents with full audit trail
- **MTTR**: <30 minutes for incident resolution
- **Support Efficiency**: <24 hour resolution for platform team issues

## Deployment Configuration

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: platform-orchestrator
  namespace: platform-automation
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: platform-orchestrator
  template:
    spec:
      serviceAccountName: platform-orchestrator
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: orchestrator
        image: platform/orchestrator:v2.1.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: orchestrator-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: orchestrator-secrets
              key: redis-url
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 15
```

### Security Configuration

- **Network Security**: TLS 1.3 encryption, network policies
- **Container Security**: Non-root containers, read-only filesystems
- **Secret Management**: HashiCorp Vault integration
- **Authentication**: AWS IAM with SigV4 signing
- **Audit Logging**: CloudTrail integration

### Monitoring Setup

- **Metrics**: Prometheus metrics export on `:8081/metrics`
- **Logging**: Structured JSON logs with correlation IDs
- **Health Checks**: `/health` and `/health/ready` endpoints
- **Alerting**: Grafana dashboards with automated alerts

### CI/CD Pipeline

1. **Build**: Go binary compilation with security scanning
2. **Test**: Unit tests, integration tests, security validation
3. **Deploy**: Helm chart deployment with automated rollback
4. **Monitor**: Post-deployment health verification

---

**Implementation Focus**: Q3/Q4 2025 deliverables with clear progression to enterprise features in 2026+  
**Success Criteria**: 90% reduction in provisioning time while maintaining platform team autonomy  
**Strategic Value**: Transform developer experience from weeks-long delays to hours-long automation