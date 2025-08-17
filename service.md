# Platform Automation Orchestrator Service

## Table of Contents

- [Overview](#overview)
- [Core API Specification](#core-api-specification)
  - [Essential APIs](#essential-apis)
  - [Authentication & Authorization](#authentication--authorization)
  - [Pagination](#pagination)
- [Architecture & Technology Stack](#architecture--technology-stack)
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

**Request Orchestration System**
- Request lifecycle: Submitted → Validation → Queued → In Progress → Completed/Failed
- Variable substitution with 8+ scopes (user, metadata, request, system, etc.)
- Circuit breaker architecture for external service calls
- State tracking and audit trail

**Multi-Action Fulfillment Engine**
- 5+ action types: JIRA, REST API, Terraform, GitHub workflows, webhooks
- Sequential execution with dependency management
- Retry logic with exponential backoff
- No automatic error recovery; failures stop execution and require manual intervention

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

### Action Types

1. **JIRA Ticket Creation**: Multi-instance integration with variable templating
2. **REST API Integration**: HTTP calls with OAuth2/API key authentication
3. **Terraform Configuration**: Infrastructure provisioning with repository mapping
4. **GitHub Workflow Dispatch**: GitHub Actions integration with status monitoring
5. **Webhook Invocation**: HMAC-secured webhooks for system notifications

**Error Handling**: All action types use limited retry logic. When any action fails after retries, execution stops and the request status is marked as failed, requiring manual review and intervention.

### Variable System

Supports 8+ variable scopes:
- `{{fields.field_id}}` - User form input
- `{{metadata.id}}` - Service metadata
- `{{request.id}}` - Request context
- `{{system.date}}` - System variables
- `{{env.VAR}}` - Environment variables
- `{{output.action_id.field}}` - Previous action outputs

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
REDIS_CLUSTER_ENDPOINT=xxx.cache.amazonaws.com:6379
GITHUB_WEBHOOK_SECRET=xxx
JIRA_API_TOKEN=xxx
AWS_SECRETS_MANAGER_REGION=us-east-1
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