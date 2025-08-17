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

The Platform Automation Orchestrator (PAO) is a cloud-native REST service that transforms multi-week provisioning processes into automated self-service workflows by providing a document-driven convergence point where platform teams define services through Schema v2.0 YAML documents.

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

## API Implementation

### Developer Self-Service APIs

#### Catalog Discovery & Browsing

**GET /api/v1/catalog**
- **Purpose**: Browse available services with filtering and pagination
- **Implementation**: Query catalog repository with Redis caching, support filters by category, environment, team authorization
- **Response**: Paginated list of catalog items with metadata
- **Caching**: 300-second TTL with automatic invalidation on catalog changes
- **Authorization**: Basic access validation (comprehensive RBAC planned for later quarterly phase)

**GET /api/v1/catalog/{category}**
- **Purpose**: Retrieve category-specific services
- **Implementation**: Category validation against enum, filtered catalog query
- **Response**: Services within specified category with availability status
- **Performance**: Sub-200ms response with Redis caching

**GET /api/v1/catalog/search?q={query}**
- **Purpose**: Full-text search across service names, descriptions, and tags
- **Implementation**: Elasticsearch integration with relevance scoring
- **Response**: Ranked search results with highlighting
- **Features**: Fuzzy matching, auto-complete suggestions, search analytics

**GET /api/v1/catalog/items/{item_id}**
- **Purpose**: Detailed service information including SLA and documentation
- **Implementation**: Catalog repository lookup with variable substitution for dynamic content
- **Response**: Complete catalog item with resolved variables and user-specific information
- **Authorization**: Basic access validation (comprehensive RBAC planned for later quarterly phase)

**GET /api/v1/catalog/items/{item_id}/schema**
- **Purpose**: Generate dynamic JSON schema for form rendering
- **Implementation**: Transform presentation section into JSON Schema with conditional logic
- **Response**: JSON Schema with field validation rules, conditional dependencies, and data sources
- **Features**: Validation rules, conditional field visibility, dynamic data source integration

#### Request Lifecycle Management

**POST /api/v1/requests**
- **Purpose**: Submit new service provisioning request
- **Implementation**: 
  - Validate payload against catalog item schema
  - Execute prerequisite checks (quota, approval requirements)
  - Generate unique request ID and initialize state tracking
  - Queue request for processing based on priority
- **Response**: Request ID with initial status and estimated completion time
- **State Management**: Persist to PostgreSQL with full audit trail

**GET /api/v1/requests**
- **Purpose**: List user's requests with filtering and pagination
- **Implementation**: Query user's request history with status filtering, date ranges, service types
- **Response**: Paginated request list with status, progress, and quick actions
- **Performance**: Optimized queries with database indexing on user_id, status, created_at

**GET /api/v1/requests/{request_id}**
- **Purpose**: Comprehensive request details including all metadata, field values, and execution history
- **Implementation**: Aggregate request data with action logs, outputs, and state transitions
- **Response**: Complete request object with timeline, current action, and next steps
- **Authorization**: Basic ownership verification (comprehensive RBAC planned for later quarterly phase)

**GET /api/v1/requests/{request_id}/status**
- **Purpose**: Current status with progress percentage and current action
- **Implementation**: Fast status query optimized for polling with Redis caching
- **Response**: Status object with progress, current action, ETA, and state
- **Performance**: <50ms response time with Redis caching

**GET /api/v1/requests/{request_id}/logs**
- **Purpose**: Detailed execution logs with correlation IDs and timestamps
- **Implementation**: Structured log retrieval with filtering and pagination
- **Response**: Chronological log entries with severity levels and correlation tracking
- **Features**: Log streaming, filtering by action/severity, correlation ID tracking

**POST /api/v1/requests/{request_id}/retry**
- **Purpose**: Retry failed request with option to modify parameters
- **Implementation**: 
  - Validate retry eligibility based on failure type and retry count
  - Reset request state to appropriate checkpoint
  - Re-queue with exponential backoff consideration
- **Response**: New execution tracking information
- **Authorization**: Basic ownership verification (comprehensive RBAC planned for later quarterly phase)

**POST /api/v1/requests/{request_id}/cancel**
- **Purpose**: Cancel pending or in-progress request
- **Implementation**:
  - Check cancellation eligibility based on current state
  - Execute rollback actions if already in progress
  - Update state with cancellation reason and timestamp
- **Response**: Cancellation confirmation with rollback status
- **Safety**: Prevent cancellation of critical operations in progress

### Platform Team APIs

#### Team Management & Analytics

**GET /api/v1/teams/{team_id}/requests**
- **Purpose**: Team request history and analytics
- **Implementation**: Aggregate team member requests with filtering and analytics
- **Response**: Request history with success rates, average completion times, and performance analysis
- **Authorization**: Basic access validation (comprehensive RBAC planned for later quarterly phase)
- **Analytics**: Success rates, usage trends, popular services, failure patterns

**GET /api/v1/teams/{team_id}/catalog**
- **Purpose**: Services owned and maintained by the team
- **Implementation**: Filter catalog by ownership metadata, include usage statistics
- **Response**: Team-owned services with adoption metrics and feedback
- **Features**: Service health scores, user satisfaction ratings, improvement suggestions

**GET /api/v1/teams/{team_id}/usage**
- **Purpose**: Resource usage analysis by team
- **Implementation**: Aggregate resource consumption across all team requests
- **Response**: Usage breakdown by service type and trend analysis
- **Integration**: Resource monitoring APIs

**GET /api/v1/teams/{team_id}/analytics**
- **Purpose**: Performance dashboards and business intelligence
- **Implementation**: Generate team-specific analytics from request data and usage metrics
- **Response**: Dashboard data with KPIs, trends, recommendations
- **Features**: Customizable metrics, comparative analysis, forecasting

#### Service Development & Testing

**POST /api/v1/validate/catalog-item**
- **Purpose**: Validate service definition against Schema v2.0
- **Implementation**: 
  - Comprehensive JSON schema validation
  - Cross-reference validation (dependencies, data sources)
  - Variable substitution testing
  - Action configuration validation
- **Response**: Validation results with detailed error messages and remediation suggestions
- **Features**: Validation severity levels, best practice recommendations, migration guidance

**POST /api/v1/preview/form**
- **Purpose**: Preview form generation from presentation definition
- **Implementation**: Transform presentation section into UI components without persistence
- **Response**: Form preview data with field layout, validation rules, conditional logic
- **Features**: Multiple layout previews, accessibility validation, mobile responsiveness

**POST /api/v1/test/variables**
- **Purpose**: Test variable substitution with sample data
- **Implementation**: Execute variable engine with provided test context and field values
- **Response**: Substituted templates with highlighting and debug information
- **Features**: Variable scope testing, conditional logic validation, function testing

**POST /api/v1/simulate/fulfillment**
- **Purpose**: Simulate automation workflow execution
- **Implementation**: 
  - Dry-run action execution with mock external calls
  - State machine simulation with branching logic
  - Dependency resolution testing
  - Error scenario simulation
- **Response**: Simulation results with execution path, timing estimates, potential issues
- **Safety**: Sandbox execution environment with no external side effects

### Administrative APIs

#### System Health & Monitoring

**GET /api/v1/health**
- **Purpose**: Comprehensive service health check including dependencies
- **Implementation**: 
  - Check database connectivity (PostgreSQL, Redis)
  - Validate external integrations (JIRA, GitHub, Terraform)
  - Monitor resource utilization and performance metrics
  - Check catalog repository accessibility
- **Response**: Health status with component-level details and degradation information
- **Performance**: <100ms response time with cached dependency checks

**GET /api/v1/health/ready**
- **Purpose**: Kubernetes readiness probe for traffic routing
- **Implementation**: Fast health check focused on request processing capability
- **Response**: Simple ready/not-ready status
- **Criteria**: Database connectivity, catalog availability, core service functionality

**GET /api/v1/metrics**
- **Purpose**: Prometheus metrics export for monitoring and alerting
- **Implementation**: Export custom metrics including request rates, success rates, performance timings
- **Response**: Prometheus-formatted metrics
- **Metrics**: API response times, request counts, error rates, catalog statistics, resource usage

**GET /api/v1/version**
- **Purpose**: Service version information for debugging and deployment tracking
- **Implementation**: Return build metadata, version numbers, commit hashes
- **Response**: Version information with build timestamp and environment details

#### Catalog Management

**POST /api/v1/catalog/refresh**
- **Purpose**: Force immediate catalog refresh from repository
- **Implementation**: 
  - Trigger repository fetch and validation
  - Update cache with new catalog data
  - Return refresh status immediately
- **Response**: Refresh status with validation results
- **Authorization**: Administrative access control (RBAC planned for later quarterly phase)

**GET /api/v1/catalog/validation/{item_id}**
- **Purpose**: Detailed validation results for specific catalog item
- **Implementation**: Execute comprehensive validation with detailed reporting
- **Response**: Validation report with errors, warnings, best practice suggestions
- **Features**: Historical validation results, trend analysis, improvement tracking

**GET /api/v1/stats/usage**
- **Purpose**: System-wide usage statistics and trends
- **Implementation**: Aggregate usage data across all teams and services
- **Response**: Usage statistics with trends, popular services, adoption rates
- **Analytics**: Service popularity, user engagement, platform health indicators

**GET /api/v1/stats/performance**
- **Purpose**: Performance metrics and SLA tracking
- **Implementation**: Calculate performance metrics against defined SLAs
- **Response**: Performance data with SLA compliance, bottleneck identification
- **Features**: Historical performance trends, capacity planning insights

**GET /api/v1/audit/requests**
- **Purpose**: Comprehensive audit trail access for compliance
- **Implementation**: Query audit logs with filtering and export capabilities
- **Response**: Audit trail data with compliance reporting features
- **Authorization**: Administrative access control (RBAC planned for later quarterly phase)
- **Compliance**: Basic audit trail capabilities (enterprise compliance planned for future phases)

### Enterprise Governance APIs

#### Approval & Workflow Management

**GET /api/v1/approvals/pending**
- **Purpose**: List pending approval requests for current user
- **Implementation**: Query approval workflows where user is designated approver
- **Response**: Pending approvals with context, urgency, and decision deadlines
- **Features**: Approval delegation, escalation tracking, batch approval capabilities

**POST /api/v1/approvals/{approval_id}/approve**
- **Purpose**: Approve pending request with optional comments
- **Implementation**: 
  - Validate approver authorization
  - Record approval decision with timestamp and comments
  - Trigger next workflow stage or request continuation
- **Response**: Approval confirmation with next steps
- **Audit**: Full approval trail with decision rationale

**POST /api/v1/approvals/{approval_id}/reject**
- **Purpose**: Reject pending request with required justification
- **Implementation**: 
  - Record rejection with mandatory reason
  - Trigger notification to requester
  - Update request status with rejection details
- **Response**: Rejection confirmation with communication status
- **Features**: Rejection templates, escalation options, appeal process

#### Quota Management

**GET /api/v1/quota/usage/{team_id}**
- **Purpose**: Current quota usage and available capacity
- **Implementation**: Calculate current resource consumption against defined limits
- **Response**: Quota usage with projections and alerts
- **Features**: Usage forecasting, capacity planning, automatic alerts

**POST /api/v1/quota/limits/{team_id}**
- **Purpose**: Update team resource quotas and limits
- **Implementation**: 
  - Validate new limits against organizational policies
  - Update quota configuration with effective date
  - Trigger notifications for quota changes
- **Response**: Updated quota configuration
- **Authorization**: Administrative access control (RBAC planned for later quarterly phase)

### Integration Webhooks

**POST /api/v1/webhooks/github**
- **Purpose**: Process GitHub repository events and workflow notifications
- **Implementation**: 
  - Validate webhook signature
  - Parse event payload and correlate with active requests
  - Update request status based on workflow completion
- **Security**: HMAC signature validation, IP allowlisting
- **Events**: Workflow completion, deployment status, error notifications

**POST /api/v1/webhooks/jira**
- **Purpose**: Process JIRA ticket status updates
- **Implementation**: 
  - Parse JIRA webhook payload
  - Correlate ticket updates with PAO requests
  - Update request status and notify stakeholders
- **Features**: Status mapping, assignment changes, comment synchronization

**POST /api/v1/webhooks/terraform**
- **Purpose**: Process Terraform Cloud/Enterprise notifications
- **Implementation**: 
  - Parse Terraform webhook events
  - Extract output values and state information
  - Update request with infrastructure details
- **Integration**: Terraform Cloud API, state file analysis


## Enterprise Integration Architecture

### Authentication & Authorization
- **IAM Authentication**: AWS IAM-based authentication for all API access with SigV4 request signing
- **Basic Access Control**: Simple authentication with comprehensive RBAC planned for later quarterly phase
- **Service Authentication**: IAM roles for service-to-service authentication with automatic credential rotation
- **Future Authorization**: Team-based access and granular permissions to be implemented in later phases
- **Audit Logging**: Comprehensive CloudTrail integration with IAM principal tracking (enterprise compliance planned for future phases)

### State Management & Persistence
- **Request State**: PostgreSQL with connection pooling, read replicas, and automated backups
- **Resource Tracking**: Simple state tracking for provisioned resources with lifecycle management
- **Configuration Cache**: Redis cluster with distributed caching, TTL management, and invalidation strategies
- **Metrics Collection**: Time-series data for usage analytics, performance monitoring, and business intelligence
- **Audit Trail**: Immutable audit logs with retention policies and compliance reporting

### Reliability & Performance Architecture
- **Circuit Breakers**: Fault tolerance for external service calls with configurable thresholds and automatic recovery
- **Rate Limiting**: Request throttling to prevent system overload with dynamic adjustment
- **Request Queuing**: Asynchronous processing with configurable concurrency and priority queues
- **Health Checks**: Kubernetes-ready liveness and readiness probes with dependency checking
- **Auto-scaling**: Horizontal pod autoscaling based on CPU, memory, and custom metrics
- **Zero-downtime Deployments**: Blue-green deployments with automated rollback

### Monitoring & Observability
- **Structured Logging**: JSON-formatted logs with correlation IDs, structured metadata, and log aggregation
- **Metrics Export**: Prometheus-compatible metrics for monitoring with custom dashboards
- **Distributed Tracing**: Request tracing across action chains with Jaeger integration
- **Error Tracking**: Centralized error reporting with Sentry integration and alerting
- **Business Intelligence**: Usage analytics dashboard with optimization recommendations
- **Performance Monitoring**: SLA tracking with automated alerting and escalation

## Technology Implementation Stack

### Service Runtime & Framework
- **Runtime**: Go programming language for high performance and enterprise compatibility
- **Framework**: Gin web framework with OpenAPI 3.0 specification
- **API Documentation**: Automated Swagger/OpenAPI generation with examples and validation
- **Validation**: JSON Schema validation with comprehensive error reporting
- **Configuration**: Viper configuration management with environment variable support

### Data Storage & Caching
- **Primary Database**: PostgreSQL 14+ with connection pooling (PgBouncer) and read replicas
- **Caching Layer**: Redis Cluster 7+ with distributed caching and persistence
- **Message Queue**: Redis Streams or Apache Kafka for asynchronous processing
- **State Backend**: PostgreSQL with JSONB support for flexible state storage
- **Backup Strategy**: Automated backups with point-in-time recovery

### External Integrations & Security
- **Git Repository**: GitHub/GitLab webhook integration with CODEOWNERS enforcement
- **JIRA API**: Atlassian REST API with retry logic and rate limiting
- **Terraform**: Terraform Cloud API or local runners with state management
- **Kubernetes**: In-cluster deployment with service discovery and secrets management
- **Secret Management**: HashiCorp Vault integration with automatic rotation
- **Security Scanning**: SAST/DAST integration with dependency vulnerability scanning

### Deployment & Infrastructure
- **Container Platform**: Kubernetes 1.24+ with Docker containers
- **Orchestration**: Helm 3+ charts with parameterized deployment templates
- **Service Mesh**: Istio (optional) for advanced traffic management and security
- **Load Balancing**: NGINX Ingress Controller with SSL termination
- **Monitoring Stack**: Prometheus, Grafana, Jaeger, and ELK stack
- **CI/CD Pipeline**: GitHub Actions with automated testing and deployment

## Operational Deployment Architecture

### Kubernetes Production Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: platform-orchestrator
  namespace: platform-automation
  labels:
    app: platform-orchestrator
    version: v2.1.0
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
    metadata:
      labels:
        app: platform-orchestrator
        version: v2.1.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8080"
    spec:
      serviceAccountName: platform-orchestrator
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: orchestrator
        image: platform/orchestrator:v2.1.0
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 8081
          name: metrics
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
        - name: VAULT_ADDR
          value: "https://vault.company.com"
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
        - name: secrets
          mountPath: /app/secrets
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: orchestrator-config
      - name: secrets
        secret:
          secretName: orchestrator-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: platform-orchestrator
  namespace: platform-automation
  labels:
    app: platform-orchestrator
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  - port: 8081
    targetPort: 8081
    protocol: TCP
    name: metrics
  selector:
    app: platform-orchestrator
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: platform-orchestrator
  namespace: platform-automation
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - orchestrator.company.com
    secretName: orchestrator-tls
  rules:
  - host: orchestrator.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: platform-orchestrator
            port:
              number: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: platform-orchestrator
  namespace: platform-automation
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: platform-orchestrator
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### Configuration Management
- **Environment Variables**: Database connections, API keys, feature flags with validation
- **ConfigMaps**: Catalog repository settings, integration endpoints, application configuration
- **Secrets**: Authentication tokens, encryption keys, database credentials with rotation
- **Helm Charts**: Parameterized deployment templates for multiple environments with values files
- **External Secrets**: HashiCorp Vault integration with automatic secret rotation

### Security Implementation
- **Network Security**: TLS 1.3 encryption, network policies, firewall rules with allowlists
- **Container Security**: Non-root containers, read-only filesystems, security contexts
- **Secret Management**: HashiCorp Vault integration with automatic rotation and audit
- **Dependency Scanning**: Automated vulnerability assessment with Snyk integration
- **Security Testing**: SAST/DAST integration with Veracode and OWASP ZAP
- **Compliance**: Basic security compliance (enterprise compliance frameworks planned for future phases)

---

**Implementation Focus**: Q3/Q4 2025 deliverables with clear progression to enterprise features in 2026+  
**Success Criteria**: 90% reduction in provisioning time while maintaining platform team autonomy  
**Strategic Value**: Transform developer experience from weeks-long delays to hours-long automation