# Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

# Platform Automation Orchestrator Service

## Table of Contents

- [Overview](#overview)
- [Core API Specification](#core-api-specification)
  - [Essential APIs](#essential-apis)
  - [Authentication & Authorization](#authentication--authorization)
  - [Pagination](#pagination)
- [Architecture & Technology Stack](#architecture--technology-stack)
  - [Core Design Principles](#core-design-principles)
  - [Service Components](#service-components)
  - [Technology Stack](#technology-stack)
  - [Schema Integration](#schema-integration)
  - [Action Types](#action-types)
  - [Variable System](#variable-system)
  - [Manual Failure Resolution](#manual-failure-resolution)
- [Implementation Requirements](#implementation-requirements)
- [Performance & Success Metrics](#performance--success-metrics)
- [Deployment Configuration](#deployment-configuration)

## Overview

The Platform Automation Orchestrator (PAO) is a cloud-native REST service that transforms manual provisioning processes into automated self-service workflows by providing a document-driven convergence point where platform teams define services through schema YAML documents.

**Business Problem**: Multi-week provisioning delays due to fragmented JIRA workflows across platform teams  
**Solution**: Central orchestration service with automated fulfillment that falls back to manual JIRA when needed  
**Value**: 90%+ reduction in provisioning time (weeks to hours)

For strategic context see [whitepaper.md](whitepaper.md). For catalog design see [catalog.md](catalog.md).

## Core API Specification

### Essential APIs

**Catalog Management**
```http
GET    /api/v1/catalog                           # Browse available services
GET    /api/v1/catalog/items/{item_id}           # Service details
GET    /api/v1/catalog/items/{item_id}/schema    # Dynamic form schema
POST   /api/v1/catalog/refresh                   # Force catalog refresh
```

**Request Lifecycle**
```http
POST   /api/v1/validate/request                  # Validate user input before submission
POST   /api/v1/requests                          # Submit service request
GET    /api/v1/requests                          # List user requests
GET    /api/v1/requests/{request_id}             # Request details
GET    /api/v1/requests/{request_id}/status      # Current status
GET    /api/v1/requests/{request_id}/logs        # Execution logs
POST   /api/v1/requests/{request_id}/retry       # Retry failed action
POST   /api/v1/requests/{request_id}/abort       # Abort failed request
POST   /api/v1/requests/{request_id}/escalate    # Escalate to manual support
GET    /api/v1/requests/{request_id}/escalation  # Escalation details
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

**Implementation**
- AWS IAM authentication with SigV4 request signing
- Team-based access isolation
- CloudTrail audit logging
- Enterprise compliance frameworks

### Pagination

**Standard Pagination Pattern**
All list endpoints that return multiple items use cursor-based pagination with the following standard parameters:

**Query Parameters**
- `limit`: Number of items per page (default: 50, max: 200)
- `cursor`: Opaque cursor token for next page (optional)

**Response Format**
```json
{
  "data": [...],
  "pagination": {
    "has_more": true,
    "next_cursor": "eyJpZCI6MTIzLCJ0cyI6MTY5....",
    "total_count": 1247
  }
}
```

**Implementation Details**
- Cursor tokens are base64-encoded JSON containing sort keys
- Cursors are stateless and self-contained
- `total_count` is optional and may be omitted for performance
- Empty `next_cursor` indicates no more pages

## Architecture & Technology Stack

### Core Design Principles
1. **Schema-Driven**: All services defined via schema YAML documents
2. **Smart Fulfillment**: Automated actions with manual fallback - uses automation when available, falls back to manual JIRA when needed. No automatic error recovery; failures require human intervention
3. **Document-Driven Convergence**: Platform teams collaborate through central document store
4. **Progressive Enhancement**: Teams evolve from manual to automated at their own pace
5. **Serverless-First**: Likely AWS Lambda deployment with event-driven architecture

### Service Components

**Catalog Management Engine**
- GitHub repository integration with webhook processing
- Schema validation and error reporting
- Multi-tier caching (Redis + PostgreSQL)
- CODEOWNERS enforcement for governance

### GitHub Catalog Integration

**Webhook Processing Pipeline**:
1. **Event Reception**: GitHub webhook received at `/api/v1/webhooks/github`
2. **Security Validation**: HMAC signature verification using shared secret
3. **Event Filtering**: Process only `push` events to `main` branch affecting `/catalog/` directory
4. **Change Detection**: Identify added, modified, or deleted catalog files
5. **Validation Pipeline**: Schema validation for all changed files
6. **Cache Invalidation**: Remove stale entries from Redis and update PostgreSQL
7. **Notification**: Send status updates via webhook or notification channels

**Catalog File Processing**:
```go
type CatalogProcessor struct {
    GitHubClient   *github.Client
    SchemaValidator *jsonschema.Validator
    Cache          CacheService
    Database       DatabaseService
}

func (cp *CatalogProcessor) ProcessCatalogUpdate(event *github.PushEvent) error {
    // 1. Fetch changed files from GitHub API
    changedFiles := cp.getChangedCatalogFiles(event)
    
    // 2. Download and parse each file
    for _, file := range changedFiles {
        content := cp.downloadFile(file.Path)
        catalogItem := cp.parseYAML(content)
        
        // 3. Validate against schema
        if err := cp.validateCatalogItem(catalogItem); err != nil {
            return fmt.Errorf("validation failed for %s: %w", file.Path, err)
        }
        
        // 4. Update cache and database
        cp.updateCatalogCache(catalogItem)
    }
    
    return nil
}
```

**CODEOWNERS Enforcement**:
- Pre-commit validation via GitHub Actions using CODEOWNERS rules
- API endpoint validation checks user permissions against CODEOWNERS
- Automatic PR review requests based on changed file paths
- Catalog team approval required for schema changes

**Cache Strategy**:
- **Redis L1 Cache**: Individual catalog items (TTL: 1 hour)
- **Redis L2 Cache**: Category listings and search indexes (TTL: 6 hours)
- **PostgreSQL Storage**: Persistent catalog storage with versioning
- **Cache Invalidation**: Event-driven invalidation on catalog updates

**Error Handling for Malformed Catalog Files**:
- Schema validation errors logged with file path and line numbers
- Invalid files excluded from catalog without breaking entire update
- Error notifications sent to catalog repository via GitHub Status API
- Detailed error reports available via `/api/v1/catalog/validation-errors`

**Request Orchestration System**
- Request lifecycle: Submitted → Validation → Queued → In Progress → Completed/Failed
- Variable substitution with 8+ scopes (user, metadata, request, system, etc.)
- Circuit breaker architecture for external service calls
- State tracking and audit trail

### Request Processing Architecture

**SQS Queue Integration for Background Processing**:
```yaml
requestQueue:
  name: "pao-request-queue"
  visibilityTimeout: 300  # 5 minutes
  messageRetentionPeriod: 1209600  # 14 days
  maxReceiveCount: 3
  deadLetterQueue: "pao-request-dlq"
  
processingLambda:
  handler: "request-processor"
  timeout: 300  # 5 minutes
  batchSize: 10
  concurrency: 50
```

**Request Validation Pipeline**:
1. **Schema Validation**: Validate against catalog item schema using JSON Schema
2. **Business Rules**: Custom validation rules (naming conflicts, quota limits)
3. **User Authorization**: Verify user has permission to request this service
4. **Resource Availability**: Check dependent services and capacity constraints
5. **Variable Resolution**: Validate all template variables can be resolved

**Status Tracking and State Transitions**:
```go
type RequestStatus string

const (
    StatusSubmitted   RequestStatus = "submitted"
    StatusValidating  RequestStatus = "validating" 
    StatusQueued      RequestStatus = "queued"
    StatusInProgress  RequestStatus = "in_progress"
    StatusCompleted   RequestStatus = "completed"
    StatusFailed      RequestStatus = "failed"
    StatusAborted     RequestStatus = "aborted"
    StatusEscalated   RequestStatus = "escalated"
)

type RequestState struct {
    ID              string                 `json:"id"`
    CatalogItemID   string                 `json:"catalogItemId"`
    UserID          string                 `json:"userId"`
    Status          RequestStatus          `json:"status"`
    RequestData     map[string]interface{} `json:"requestData"`
    CurrentAction   int                    `json:"currentAction"`
    Actions         []ActionState          `json:"actions"`
    ErrorContext    *ErrorContext          `json:"errorContext,omitempty"`
    CreatedAt       time.Time              `json:"createdAt"`
    UpdatedAt       time.Time              `json:"updatedAt"`
}
```

**Audit Logging Implementation**:
- Correlation ID tracking across all system components
- Structured JSON logging with standardized fields
- Database audit trail for all state changes
- Integration with CloudWatch Logs and X-Ray tracing

**Background Job Processing Architecture**:
1. **Request Queuing**: New requests added to SQS queue after validation
2. **Lambda Processing**: Background Lambda processes queue messages
3. **Action Execution**: Sequential execution of catalog-defined actions
4. **State Persistence**: Each action result stored in database
5. **Error Handling**: Failed actions trigger manual intervention workflow
6. **Status Updates**: Real-time status updates via WebSocket or polling

**Multi-Action Fulfillment Engine**
- 5+ action types: JIRA, REST API, Terraform, GitHub workflows, webhooks
- Sequential execution with dependency management
- Retry logic with exponential backoff
- No automatic error recovery; failures stop execution and require manual intervention
- Failed requests provide detailed failure context for human decision-making
- Operators can retry failed actions, abort the request, or escalate to manual support

### Technology Stack

**Runtime & Framework**
- Go programming language
- HTTP router framework (handling 1000+ catalog endpoints internally)
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

**Deployment (Likely Path)**
- AWS Lambda functions
- API Gateway for REST endpoints
- CloudFormation/CDK for infrastructure
- CloudWatch for monitoring and logging

### Schema Integration

PAO implements the schema specification from [catalog.md](catalog.md):

- **Metadata**: Service identification, ownership, SLA commitments
- **Presentation**: Dynamic form generation with conditional logic and validation
- **Fulfillment**: Automated actions with manual JIRA fallback
- **Lifecycle**: Deprecation and versioning management
- **Monitoring**: Health checks and observability configuration

### Dynamic Form Generation

**Schema-to-Form Conversion Algorithm**:
The service transforms catalog `presentation.form` definitions into dynamic web forms and CLI interfaces.

**Field Type to UI Component Mapping**:
```yaml
string: 
  component: "text-input"
  validation: ["required", "pattern", "minLength", "maxLength"]
  
number:
  component: "number-input" 
  validation: ["required", "min", "max", "step"]
  
boolean:
  component: "checkbox"
  validation: ["required"]
  
select:
  component: "dropdown"
  validation: ["required", "enum"]
  props: { options: "field.enum" }
  
multiselect:
  component: "multi-dropdown"
  validation: ["required", "enum"] 
  props: { options: "field.enum", multiple: true }
  
date:
  component: "date-picker"
  validation: ["required", "min", "max"]
  
textarea:
  component: "textarea"
  validation: ["required", "minLength", "maxLength"]
  
password:
  component: "password-input"
  validation: ["required", "pattern", "strength"]
```

**Form Generation API Response**:
```json
{
  "catalogItemId": "database-postgresql-standard",
  "form": {
    "groups": [
      {
        "id": "basic",
        "name": "Basic Configuration", 
        "description": "Core database settings",
        "fields": [
          {
            "id": "instanceName",
            "name": "Instance Name",
            "type": "string",
            "component": "text-input",
            "required": true,
            "validation": {
              "pattern": "^[a-z][a-z0-9-]{2,28}[a-z0-9]$",
              "message": "Must be 3-30 chars, lowercase, alphanumeric with hyphens"
            },
            "placeholder": "my-database"
          }
        ]
      }
    ]
  },
  "validation": {
    "endpoint": "/api/v1/validate/request",
    "method": "POST"
  }
}
```

**Conditional Field Logic Implementation**:
```yaml
fields:
  - id: enableEncryption
    type: boolean
    name: "Enable Encryption"
    
  - id: encryptionKey  
    type: string
    name: "Encryption Key"
    conditional:
      dependsOn: "enableEncryption"
      condition: "equals"
      value: true
```

**Form Submission and Validation Pipeline**:
1. **Client-Side Validation**: Real-time validation using form schema rules
2. **Pre-Submit Validation**: `/api/v1/validate/request` endpoint check
3. **Server-Side Validation**: Schema validation + business logic validation  
4. **Request Creation**: Generate UUID and store in database
5. **Background Processing**: Queue request for action execution

### Action Types

1. **JIRA Ticket Creation**: Multi-instance integration with variable templating
2. **REST API Integration**: HTTP calls with OAuth2/API key authentication
3. **Terraform Configuration**: Infrastructure provisioning with repository mapping
4. **GitHub Workflow Dispatch**: GitHub Actions integration with status monitoring
5. **Webhook Invocation**: HMAC-secured webhooks for system notifications

**Error Handling**: All action types use limited retry logic. When any action fails after retries, execution stops and the request status is marked as failed, requiring manual review and intervention.

### JIRA Action Framework

**Authentication Configuration**:
```yaml
jira:
  instances:
    platform:
      baseUrl: "https://company.atlassian.net"
      authentication:
        type: "api_token"
        username: "{{env.JIRA_PLATFORM_USERNAME}}"
        token: "{{env.JIRA_PLATFORM_TOKEN}}"
    dba:
      baseUrl: "https://company.atlassian.net"
      authentication:
        type: "oauth2"
        clientId: "{{env.JIRA_DBA_CLIENT_ID}}"
        clientSecret: "{{env.JIRA_DBA_CLIENT_SECRET}}"
```

**Ticket Creation Workflow**:
1. **Template Processing**: Variable substitution in summary, description, and custom fields
2. **Instance Selection**: Route to appropriate JIRA instance based on catalog configuration
3. **Ticket Creation**: POST to JIRA REST API with error handling and validation
4. **Status Tracking**: Store ticket key and URL for future reference
5. **Webhook Registration**: Optional webhook setup for status updates

**Template Variable Processing**:
```yaml
ticket:
  project: "{{metadata.owner.jiraProject | default('PLATFORM')}}"
  issueType: "{{fields.priority | jiraIssueType}}"
  summary: "{{fields.name}} - {{metadata.name}}"
  description: |
    **Service Request**: {{metadata.name}} ({{metadata.version}})
    **Requested by**: {{request.user.email}}
    **Request ID**: {{request.id}}
    **Submitted**: {{request.timestamp}}
    
    **Configuration**:
    {{#each fields}}
    - {{@key}}: {{this}}
    {{/each}}
```

**Status Polling & Webhook Handling**:
- Periodic polling every 5 minutes for ticket status changes
- Webhook endpoint `/api/v1/webhooks/jira` for real-time updates
- Status mapping: `Open → In Progress`, `Done → Completed`, `Won't Do → Failed`
- JIRA comment posting for request updates and error context

### Variable System

The variable substitution system supports 6+ core scopes with template processing and transformation functions:

**Core Variable Scopes**:
- `{{fields.field_id}}` - User form input values from request submission
- `{{metadata.id}}` - Service metadata from catalog definition (id, name, version, category, owner)
- `{{request.id}}` - Request context (id, user.email, user.teams, timestamp, correlation_id)
- `{{system.date}}` - System-generated variables (date, timestamp, uuid, hostname)
- `{{environment.VAR}}` - Environment variables from orchestrator configuration
- `{{outputs.action_id.field}}` - Previous action outputs for chaining

**Template Processing Engine**:
- Mustache-style template syntax: `{{scope.key}}`
- Nested object access: `{{request.user.email}}`
- Array indexing: `{{fields.environments[0]}}`
- Conditional logic: `{{#if fields.enableSSL}}...{{/if}}`
- Iteration: `{{#each fields.ports}}...{{/each}}`

**Transformation Functions**:
- `{{upper(fields.name)}}` - Uppercase conversion
- `{{lower(metadata.category)}}` - Lowercase conversion
- `{{concat(fields.prefix, "-", system.uuid)}}` - String concatenation
- `{{replace(fields.name, " ", "-")}}` - String replacement
- `{{json(fields.config)}}` - JSON encoding for API payloads
- `{{base64(fields.secret)}}` - Base64 encoding
- `{{uuid()}}` - Generate unique identifier
- `{{timestamp()}}` - Current Unix timestamp

**Variable Validation & Error Handling**:
- Pre-execution validation ensures all variables can be resolved
- Missing variable references cause request validation failure
- Type checking prevents invalid transformations
- Circular dependency detection for output chaining
- Detailed error messages specify invalid variable paths

### Manual Failure Resolution

**Failure Context Preservation**:
When any action fails, the system preserves detailed failure information to support manual decision-making:

- **Partial State Inventory**: Which components succeeded/failed and what resources were created
- **Error Context**: Full error messages, logs, and failure timestamps  
- **Cleanup Guidance**: Component-specific cleanup procedures based on action types
- **Request Metadata**: Original request data and user context for troubleshooting

**Human Decision Options**:
When reviewing a failed request, operators have three options:

1. **Retry Failed Action**: Re-execute the failed action (useful for transient errors)
2. **Abort Request**: Mark the request as permanently failed and stop processing
3. **Escalate to Manual Support**: Create structured JIRA ticket for human intervention

**Manual Support Escalation**:
When operators choose to escalate, a structured JIRA ticket is created containing the preserved failure context:

**JIRA Ticket Template** (used when operator chooses to escalate):
```yaml
type: jira-ticket
config:
  ticket:
    project: ORCHESTRATION
    issueType: "Incident"
    priority: "High"
    summaryTemplate: "Manual Support Required - {{bundle.metadata.name}} ({{request.id}})"
    descriptionTemplate: |
      **Request Information**
      Service: {{bundle.metadata.name}} ({{bundle.metadata.version}})
      Request ID: {{request.id}}
      User: {{request.user.email}}
      Failure Time: {{failure.timestamp}}
      
      **Component Status**
      {{#each components}}
      - {{id}}: {{status}}{{#if resources}} (Resources: {{join resources ", "}}){{/if}}
      {{/each}}
      
      **Error Details**
      {{failure.error}}
      
      **Cleanup Required**
      {{#each components}}
      {{#if succeeded}}
      - {{id}}: {{cleanup.instructions}}
      {{/if}}
      {{/each}}
      
      **Original Request Data**
      ```json
      {{json request.data}}
      ```
```

**Request Status Workflow**:
- Failed requests remain in `"failed"` status until human decision
- **Retry**: Status remains `"failed"` until retry succeeds or fails again
- **Abort**: Status changes to `"aborted"` with timestamp
- **Escalate**: Status changes to `"escalated"` with JIRA ticket reference
- Operators can query by status: `GET /api/v1/requests?status=failed|aborted|escalated`

## Implementation Requirements

### Core Features

**Core API Endpoints**
- Catalog browsing and service discovery
- Request submission and status tracking
- Health checks and metrics export
- Dynamic form generation from schema
- Platform team validation tools

**Action Type Implementation**
- JIRA ticket creation with variable substitution
- REST API calls with authentication
- Webhook invocation
- GitHub workflow dispatch
- Terraform configuration management

**Infrastructure Components**
- GitHub repository integration with webhooks
- Catalog caching (ElastiCache Redis)
- Request state tracking (RDS PostgreSQL)
- Lambda deployment with health checks

**Reliability & Performance**
- Circuit breaker architecture for external calls
- Comprehensive retry logic with exponential backoff (limited retries, no infinite loops)
- RDS Proxy for PostgreSQL connections
- ElastiCache Redis clustering
- **Error Handling**: All failures require manual intervention; no automatic recovery mechanisms

**Monitoring & Observability**
- CloudWatch metrics and custom metrics
- Structured JSON logging with correlation IDs
- X-Ray distributed tracing
- CloudWatch dashboards and alarms

**Security & Compliance**
- AWS IAM authentication with SigV4 signing
- CloudTrail audit logging
- AWS Secrets Manager for secret storage
- Lambda security best practices

### Database Schema

**Requests Table**
```sql
CREATE TABLE requests (
    id UUID PRIMARY KEY,
    catalog_item_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,  -- submitted, in_progress, completed, failed, aborted, escalated
    request_data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    aborted_at TIMESTAMP,
    escalation_ticket_id VARCHAR(50),
    escalation_timestamp TIMESTAMP
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

### Core Infrastructure Implementation Details

**Database Connection Pooling and Optimization**:
```go
type DatabaseConfig struct {
    MaxOpenConns    int           `default:"25"`
    MaxIdleConns    int           `default:"10"`
    ConnMaxLifetime time.Duration `default:"5m"`
    ConnMaxIdleTime time.Duration `default:"1m"`
}

// RDS Proxy configuration for Lambda environments
type RDSProxyConfig struct {
    ProxyEndpoint string `env:"RDS_PROXY_ENDPOINT"`
    IAMAuth       bool   `default:"true"`
    Region        string `env:"AWS_REGION"`
}
```

**Redis Caching Strategy and Key Structure**:
```yaml
keyStructure:
  catalogItems: "catalog:item:{itemId}"
  catalogCategories: "catalog:category:{category}"
  requestStatus: "request:status:{requestId}"
  userSessions: "session:user:{userId}"
  formSchemas: "form:schema:{itemId}"
  
cacheTTL:
  catalogItems: 3600      # 1 hour
  categories: 21600       # 6 hours  
  requestStatus: 300      # 5 minutes
  formSchemas: 7200       # 2 hours

clusterConfig:
  nodes: 3
  replicationFactor: 2
  failoverEnabled: true
  backupSchedule: "0 2 * * *"  # Daily at 2 AM
```

**Lambda Function Organization and Event Routing**:
```yaml
functions:
  api-handler:
    purpose: "Handle all REST API endpoints"
    routes: "/api/v1/*"
    timeout: 30
    memory: 512
    
  catalog-processor:
    purpose: "Process GitHub webhook events for catalog updates"
    events: ["github.push", "github.pull_request"]
    timeout: 120
    memory: 256
    
  request-processor:
    purpose: "Execute background request processing"
    events: ["sqs.request-queue"]
    timeout: 300
    memory: 1024
    
  status-updater:
    purpose: "Handle external system status updates"
    events: ["jira.webhook", "terraform.callback"]
    timeout: 60
    memory: 256
```

**Error Context Preservation for Manual Escalation**:
```go
type ErrorContext struct {
    RequestID        string                 `json:"requestId"`
    FailedAction     ActionState            `json:"failedAction"`
    PartialResources []ResourceReference    `json:"partialResources"`
    ErrorDetails     map[string]interface{} `json:"errorDetails"`
    CleanupRequired  []CleanupInstruction   `json:"cleanupRequired"`
    EscalationPath   string                 `json:"escalationPath"`
    Timestamp        time.Time              `json:"timestamp"`
}

type CleanupInstruction struct {
    ResourceType string                 `json:"resourceType"`
    ResourceID   string                 `json:"resourceId"`
    Instructions string                 `json:"instructions"`
    Priority     string                 `json:"priority"` // high, medium, low
    Automated    bool                   `json:"automated"`
}
```

**Performance Monitoring and Metrics Collection**:
```yaml
customMetrics:
  - name: "pao_requests_total"
    type: "counter"
    labels: ["status", "catalog_item", "user_team"]
    
  - name: "pao_request_duration_seconds"
    type: "histogram"
    labels: ["catalog_item", "action_type"]
    buckets: [0.1, 0.5, 1, 5, 10, 30, 60]
    
  - name: "pao_catalog_cache_hit_ratio"
    type: "gauge"
    labels: ["cache_type"]
    
  - name: "pao_action_failure_rate"
    type: "gauge"
    labels: ["action_type", "failure_reason"]

alerting:
  - metric: "pao_request_failure_rate"
    threshold: 0.05  # 5%
    window: "5m"
    
  - metric: "pao_api_response_time_p95"
    threshold: 2.0   # 2 seconds
    window: "1m"
```

### Configuration Requirements

**Environment Variables**
```bash
DATABASE_URL=postgresql://user:pass@host:5432/pao
REDIS_CLUSTER_ENDPOINT=xxx.cache.amazonaws.com:6379
GITHUB_WEBHOOK_SECRET=xxx
JIRA_API_TOKEN=xxx
AWS_SECRETS_MANAGER_REGION=us-east-1
RDS_PROXY_ENDPOINT=pao-rds-proxy.cluster-xxxxx.us-east-1.rds.amazonaws.com
CATALOG_GITHUB_REPO=company/platform-catalog
CORRELATION_ID_HEADER=X-Correlation-ID
```

**Lambda Configuration**
```yaml
functions:
  api:
    runtime: go1.x
    memory: 512
    timeout: 30
    environment:
      DATABASE_URL: ${ssm:/pao/database-url}
      REDIS_CLUSTER_ENDPOINT: ${ssm:/pao/redis-endpoint}
  
  webhook_processor:
    runtime: go1.x
    memory: 256
    timeout: 60
    events:
      - eventBridge:
          pattern:
            source: ["github.webhook"]
```

## Performance & Success Metrics

### Performance Targets
- **API Response Time**: <200ms for catalog operations (P95)
- **Request Submission**: <2s for request processing (P99)
- **System Availability**: 99.9% uptime with zero-downtime deployments
- **Throughput**: Support 1000+ concurrent requests
- **Status Polling**: <50ms response with ElastiCache

### Business Impact Metrics
- **Provisioning Time**: Reduce from multi-week to <4 hours (90%+ improvement)
- **Platform Adoption**: 100% of platform teams onboarded with ≥1 service
- **Developer Satisfaction**: >4.5/5 rating on self-service experience
- **Automation Rate**: 80%+ of services automated within 12 months

### Operational Excellence
- **Error Rate**: <5% failure rate for automated actions
- **Security Compliance**: Zero security incidents with full audit trail
- **MTTR**: <30 minutes for incident resolution
- **Support Efficiency**: <24 hour resolution for platform team issues

## Deployment Configuration

### Lambda Deployment (Likely Path)

```yaml
service: platform-orchestrator
frameworkVersion: '3'

provider:
  name: aws
  runtime: go1.x
  region: us-east-1
  environment:
    DATABASE_URL: ${ssm:/pao/database-url}
    REDIS_CLUSTER_ENDPOINT: ${ssm:/pao/redis-endpoint}
  iamRoleStatements:
    - Effect: Allow
      Action:
        - rds:DescribeDBInstances
        - elasticache:DescribeReplicationGroups
        - secretsmanager:GetSecretValue
      Resource: "*"

functions:
  api:
    handler: bin/api
    events:
      - httpApi:
          path: /api/v1/{proxy+}
          method: ANY
    environment:
      FUNCTION_TYPE: api
    reservedConcurrency: 100
    
  webhook-processor:
    handler: bin/webhook
    events:
      - eventBridge:
          pattern:
            source: ["github.webhook"]
            detail-type: ["Repository Event"]
    environment:
      FUNCTION_TYPE: webhook
    
  request-processor:
    handler: bin/processor
    events:
      - sqs:
          arn: !GetAtt RequestQueue.Arn
          batchSize: 10
    environment:
      FUNCTION_TYPE: processor
    timeout: 300

resources:
  Resources:
    RequestQueue:
      Type: AWS::SQS::Queue
      Properties:
        QueueName: pao-request-queue
        VisibilityTimeoutSeconds: 360
```

### Security Configuration

- **Network Security**: TLS 1.3 encryption, VPC endpoints
- **Function Security**: Least privilege IAM roles, resource-based policies
- **Secret Management**: AWS Secrets Manager integration
- **Authentication**: AWS IAM with SigV4 signing
- **Audit Logging**: CloudTrail integration

### Monitoring Setup

- **Metrics**: CloudWatch custom metrics and AWS Lambda insights
- **Logging**: CloudWatch Logs with structured JSON and correlation IDs
- **Health Checks**: Lambda function health monitoring via CloudWatch
- **Alerting**: CloudWatch alarms with SNS notifications

### CI/CD Pipeline

1. **Build**: Go binary compilation with security scanning
2. **Test**: Unit tests, integration tests, security validation
3. **Deploy**: Serverless framework deployment with automated rollback
4. **Monitor**: Post-deployment function health verification

---

**Implementation Focus**: Core service capabilities with clear progression to enterprise features  
**Success Criteria**: 90% reduction in provisioning time while maintaining platform team autonomy  
**Strategic Value**: Transform developer experience from weeks-long delays to hours-long automation