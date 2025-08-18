# Platform Automation Orchestrator Service

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Table of Contents

- [Overview](#overview)
- [Core API Specification](#core-api-specification)
  - [Essential APIs](#essential-apis)
  - [Authentication & Authorization](#authentication--authorization)
  - [Pagination](#pagination)
- [Q3 Synchronous Processing Architecture](#q3-synchronous-processing-architecture)
  - [Synchronous Request Processing Design](#synchronous-request-processing-design)
  - [Request Lifecycle Architecture](#request-lifecycle-architecture)
  - [Variable Substitution Architecture](#variable-substitution-architecture)
  - [JIRA Integration Architecture](#jira-integration-architecture)
  - [Data Model and Access Architecture](#data-model-and-access-architecture)
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
- [Architectural Recommendation](#architectural-recommendation)
- [Service Configuration](#service-configuration)
- [SQL Schema](#sql-schema)
- [Future Enhancements](#future-enhancements)

## Overview

The Platform Automation Orchestrator (PAO) is a cloud-native REST service that transforms manual provisioning processes into automated self-service workflows by providing a document-driven convergence point where platform teams define services through schema YAML documents.

**Business Problem**: Multi-week provisioning delays due to fragmented JIRA workflows across platform teams  
**Solution**: Central orchestration service with automated fulfillment that falls back to manual JIRA when needed  
**Value**: Significant reduction in provisioning time

For strategic context see [whitepaper.md](whitepaper.md). For catalog design see [catalog.md](catalog.md).

## Core API Specification

### Essential APIs

The Platform Automation Orchestrator provides a comprehensive REST API organized into four primary categories:

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
GET    /api/v1/version                           # Service version info
```

**Platform Team Tools**
```http
POST   /api/v1/validate/catalog-item             # Validate service definition
POST   /api/v1/preview/form                      # Preview form generation
POST   /api/v1/test/variables                    # Test variable substitution
```

**System Integration**
```http
POST   /api/v1/webhooks/github                   # GitHub webhook handler
```

**Total API Endpoints**: 19 endpoints as specified in Q3 roadmap requirements
- Core User Journey: 12 endpoints
- System Health: 3 endpoints  
- Platform Team Tools: 3 endpoints
- System Integration: 1 endpoint

### API Request/Response Schemas

#### POST /api/v1/requests - Submit Service Request
**Request**:
```json
{
  "catalogItemId": "database-postgresql-standard",
  "fields": {
    "instanceName": "myapp-db",
    "instanceClass": "db.t3.medium",
    "storageSize": 100
  },
  "metadata": {
    "correlationId": "optional-uuid",
    "tags": ["production", "critical"]
  }
}
```

**Response**:
```json
{
  "id": "req-123e4567-e89b-12d3-a456-426614174000",
  "catalogItemId": "database-postgresql-standard",
  "status": "submitted",
  "correlationId": "corr-123e4567-e89b-12d3-a456-426614174000",
  "createdAt": "2025-08-18T10:30:00Z",
  "estimatedCompletionTime": "2025-08-18T11:00:00Z"
}
```

#### GET /api/v1/requests/{request_id}/status - Request Status
**Response**:
```json
{
  "id": "req-123e4567-e89b-12d3-a456-426614174000",
  "status": "in_progress",
  "currentAction": {
    "index": 1,
    "type": "jira-ticket",
    "status": "in_progress",
    "startedAt": "2025-08-18T10:35:00Z",
    "externalReference": "PLATFORM-12345"
  },
  "progress": {
    "completedActions": 1,
    "totalActions": 3,
    "percentComplete": 33
  },
  "updatedAt": "2025-08-18T10:35:00Z"
}
```

#### Error Response Format
**Standard Error Response**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Field validation failed",
    "details": {
      "field": "instanceName",
      "constraint": "pattern",
      "received": "Invalid-Name-!",
      "expected": "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    },
    "correlationId": "corr-123e4567-e89b-12d3-a456-426614174000",
    "timestamp": "2025-08-18T10:30:00Z"
  }
}
```

**Error Codes**:
- `VALIDATION_ERROR`: Request validation failed
- `CATALOG_ITEM_NOT_FOUND`: Referenced catalog item doesn't exist
- `UNAUTHORIZED`: Authentication/authorization failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Service internal error
- `EXTERNAL_SERVICE_ERROR`: External service (JIRA, GitHub) error
- `REQUEST_NOT_FOUND`: Requested resource not found
- `ACTION_FAILED`: Action execution failed
- `INVALID_STATE_TRANSITION`: Invalid request state change

### Authentication & Authorization

**AWS IAM Authentication Implementation**:
```go
type AuthenticationConfig struct {
    AWSRegion           string `env:"AWS_REGION" default:"us-east-1"`
    RequireSignedRequests bool  `default:"true"`
    AllowedPrincipals   []string `env:"ALLOWED_PRINCIPALS"`
    SessionDuration     time.Duration `default:"1h"`
}

type SigV4Validator struct {
    Region    string
    Service   string
    Validator *v4.Verifier
}

func (s *SigV4Validator) ValidateRequest(req *http.Request) (*AuthContext, error) {
    // 1. Extract AWS credentials from Authorization header
    authHeader := req.Header.Get("Authorization")
    if !strings.HasPrefix(authHeader, "AWS4-HMAC-SHA256") {
        return nil, errors.New("invalid authorization header")
    }
    
    // 2. Verify signature using AWS SigV4
    if err := s.Validator.Verify(req); err != nil {
        return nil, fmt.Errorf("signature verification failed: %w", err)
    }
    
    // 3. Extract user context from AWS identity
    identity, err := s.getCallerIdentity(req)
    if err != nil {
        return nil, fmt.Errorf("failed to get caller identity: %w", err)
    }
    
    return &AuthContext{
        UserID:    identity.UserID,
        Email:     identity.Email,
        Teams:     identity.Teams,
        ARN:       identity.ARN,
        SessionID: uuid.New().String(),
    }, nil
}
```

**Team-Based Access Control**:
- Users are associated with teams through AWS IAM groups or OIDC claims
- Catalog items specify allowed teams in metadata
- Request submission validated against user's team membership
- Cross-team request access controlled by catalog item configuration

**Authorization Enforcement**:
```go
type AuthorizationChecker struct {
    CatalogService CatalogService
}

func (a *AuthorizationChecker) CanRequestService(userTeams []string, catalogItemID string) (bool, error) {
    item, err := a.CatalogService.GetItem(catalogItemID)
    if err != nil {
        return false, err
    }
    
    // Check if any user team is in allowed teams
    allowedTeams := item.Metadata.Access.AllowedTeams
    if len(allowedTeams) == 0 {
        return true, nil // No restrictions
    }
    
    for _, userTeam := range userTeams {
        for _, allowedTeam := range allowedTeams {
            if userTeam == allowedTeam {
                return true, nil
            }
        }
    }
    
    return false, nil
}
```

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

## Q3 Synchronous Processing Architecture

The Q3 Foundation Epic establishes a synchronous request processing architecture specifically designed for JIRA-based fulfillment. This architecture provides the technical foundation for Q4's automated provisioning while delivering immediate value through manual JIRA workflows.

**Q3 Architecture Principles**:
- **Synchronous Processing**: All requests processed within HTTP request handlers (3-5 seconds)
- **JIRA-Only Actions**: Single action type for manual fulfillment via JIRA tickets
- **Direct Database Integration**: PostgreSQL connection pooling without background workers
- **Real-time Status**: Direct JIRA API queries for status updates (no caching)
- **Foundation for Q4**: Architectural patterns that support future automated actions

### Synchronous Request Processing Design

**Core Processing Interface Pattern**:
The synchronous request processor follows a simple interface pattern that handles the complete request lifecycle within HTTP handlers.

```go
type RequestProcessor interface {
    ProcessRequest(ctx context.Context, request *ServiceRequest) (*ProcessingResult, error)
    ValidateRequest(ctx context.Context, request *ServiceRequest) error
    GetRequestStatus(ctx context.Context, requestID string) (*RequestStatus, error)
}

type SynchronousProcessor struct {
    Database     DatabaseService
    JIRAClient   JIRAService
    Validator    RequestValidator
    AuditLogger  AuditService
}
```

**Request Processing Flow Architecture**:
1. **Request Reception**: HTTP handler receives POST to `/api/v1/requests`
2. **Validation Pipeline**: Multi-stage validation (schema, business rules, authorization)
3. **Database Transaction**: Store request with correlation ID in single transaction
4. **JIRA Action Execution**: Synchronous JIRA API call with variable substitution
5. **State Update**: Update request status and store JIRA ticket reference
6. **Response**: Return request ID and JIRA ticket details to client

**State Transition Architecture**:
Q3 supports a simplified state model optimized for synchronous processing:
- `submitted` → `in_progress` (when JIRA call starts)
- `in_progress` → `completed` (when JIRA ticket created successfully)
- `in_progress` → `failed` (when JIRA call fails)
- `failed` → `aborted` (manual abort operation)
- `failed` → `escalated` (manual escalation to support)

**Error Boundary Design**:
- **HTTP Handler Level**: Request validation and authentication errors
- **Business Logic Level**: Catalog item validation and authorization errors
- **External Service Level**: JIRA API failures with detailed context preservation
- **Database Level**: Transaction failures with rollback and correlation tracking

### Request Lifecycle Architecture

**Request Lifecycle Components**:
The request lifecycle is managed by coordinated components that handle validation, execution, and status tracking.

```go
type RequestLifecycleManager interface {
    SubmitRequest(ctx context.Context, submission *RequestSubmission) (*Request, error)
    ExecuteActions(ctx context.Context, request *Request) error
    UpdateStatus(ctx context.Context, requestID string, status RequestStatus) error
    RetrieveStatus(ctx context.Context, requestID string) (*RequestStatus, error)
}

type RequestValidator interface {
    ValidateSchema(catalogItem *CatalogItem, fields map[string]interface{}) error
    ValidateAuthorization(user *AuthContext, catalogItem *CatalogItem) error
    ValidateBusinessRules(request *ServiceRequest) error
}
```

**Database Transaction Patterns**:
Q3 uses ACID transactions to ensure consistency during synchronous processing:

```go
type DatabaseTransaction interface {
    Begin() (Transaction, error)
    Commit(tx Transaction) error
    Rollback(tx Transaction) error
    
    StoreRequest(tx Transaction, request *Request) error
    UpdateRequestStatus(tx Transaction, requestID string, status RequestStatus) error
    StoreActionResult(tx Transaction, requestID string, actionResult *ActionResult) error
    LogAuditEvent(tx Transaction, event *AuditEvent) error
}
```

**Transaction Boundary Strategy**:
- **Request Submission**: Single transaction for request creation and initial audit log
- **Action Execution**: Single transaction for action execution and status update
- **Status Updates**: Individual transactions for each status change with audit logging
- **Failure Handling**: Rollback with error context preservation for manual resolution

**Audit Trail Architecture**:
Every request operation generates correlation-tracked audit events:

```go
type AuditEvent struct {
    CorrelationID string
    RequestID     string
    EventType     string
    EventData     map[string]interface{}
    UserContext   *AuthContext
    Timestamp     time.Time
}

type AuditService interface {
    LogEvent(ctx context.Context, event *AuditEvent) error
    GetRequestAuditTrail(ctx context.Context, requestID string) ([]*AuditEvent, error)
    GetCorrelationTrail(ctx context.Context, correlationID string) ([]*AuditEvent, error)
}
```

### Variable Substitution Architecture

**Variable Scope Resolution Design**:
The variable substitution system uses a hierarchical scope resolution pattern supporting 6+ core scopes.

```go
type VariableResolver interface {
    ResolveTemplate(template string, context *VariableContext) (string, error)
    ValidateTemplate(template string, availableScopes []string) error
    GetAvailableScopes(request *ServiceRequest) []string
}

type VariableContext struct {
    Fields      map[string]interface{} // User form input
    Metadata    *CatalogItemMetadata   // Service metadata
    Request     *RequestContext        // Request information
    System      *SystemContext         // System-generated variables
    Environment map[string]string      // Environment variables
    Outputs     map[string]interface{} // Previous action outputs (Q4)
}
```

**Template Processing Architecture**:
Variable substitution follows a multi-phase processing pattern:

1. **Parse Phase**: Extract variable references and validate syntax
2. **Scope Validation**: Verify all variables exist in available scopes
3. **Resolution Phase**: Apply template engine with validated context
4. **Transformation Phase**: Apply built-in functions (upper, lower, concat, etc.)
5. **Output Generation**: Return processed template with audit trail

**Scope Isolation Patterns**:
Each scope has isolated access patterns to prevent data leakage:

```go
type ScopeResolver interface {
    ResolvePath(path []string, context interface{}) (interface{}, error)
    ValidatePath(path []string, scopeType string) error
}

type FieldsResolver struct{}     // Resolves {{fields.key}} from user input
type MetadataResolver struct{}   // Resolves {{metadata.key}} from catalog
type RequestResolver struct{}    // Resolves {{request.key}} from request context
type SystemResolver struct{}     // Resolves {{system.key}} from system state
```

**Template Validation Architecture**:
Pre-execution validation prevents runtime template failures:

```go
type TemplateValidator interface {
    ValidateSyntax(template string) error
    ValidateVariables(template string, availableScopes []string) error
    ValidateFunctions(template string) error
}
```

### JIRA Integration Architecture

**JIRA Client Interface Design**:
The JIRA integration uses a clean interface pattern supporting multiple JIRA instances and authentication methods.

```go
type JIRAService interface {
    CreateTicket(ctx context.Context, config *JIRATicketConfig) (*JIRATicket, error)
    GetTicketStatus(ctx context.Context, ticketKey string) (*JIRAStatus, error)
    UpdateTicket(ctx context.Context, ticketKey string, updates *JIRAUpdates) error
    ValidateConnection(ctx context.Context) error
}

type JIRATicketConfig struct {
    Project         string
    IssueType       string
    Summary         string
    Description     string
    Priority        string
    Labels          []string
    CustomFields    map[string]interface{}
    CorrelationID   string
}
```

**Multi-Instance Architecture Pattern**:
Support for multiple JIRA instances with different authentication:

```go
type JIRAInstanceManager interface {
    GetInstance(projectKey string) (JIRAService, error)
    RegisterInstance(name string, config *JIRAInstanceConfig) error
    ValidateAllInstances(ctx context.Context) error
}

type JIRAInstanceConfig struct {
    BaseURL      string
    AuthType     string  // api_token, oauth2, basic
    Credentials  map[string]string
    DefaultProject string
    Timeout      time.Duration
}
```

**Authentication Architecture**:
Flexible authentication supporting multiple JIRA configurations:

```go
type JIRAAuthenticator interface {
    Authenticate(req *http.Request, config *JIRAInstanceConfig) error
    RefreshCredentials(config *JIRAInstanceConfig) error
}

type APITokenAuth struct{}    // Username + API token
type OAuth2Auth struct{}      // OAuth2 client credentials
type BasicAuth struct{}       // Username + password (deprecated)
```

**Status Tracking Architecture**:
Q3 uses real-time JIRA status queries without caching:

```go
type StatusTracker interface {
    GetCurrentStatus(ctx context.Context, externalReference string) (*ActionStatus, error)
    MapJIRAStatus(jiraStatus string) RequestStatus
    TrackStatusChange(ctx context.Context, requestID string, oldStatus, newStatus RequestStatus) error
}
```

**Template Processing for JIRA**:
JIRA ticket creation uses the variable substitution system:

```go
type JIRATemplateProcessor interface {
    ProcessTicketTemplate(template *JIRATicketTemplate, context *VariableContext) (*JIRATicketConfig, error)
    ValidateTemplate(template *JIRATicketTemplate) error
}

type JIRATicketTemplate struct {
    ProjectTemplate     string
    SummaryTemplate     string
    DescriptionTemplate string
    PriorityTemplate    string
    LabelsTemplate      []string
    CustomFieldTemplates map[string]string
}
```

### Data Model and Access Architecture

**Request State Model**:
The database schema optimizes for Q3 synchronous processing patterns with clear state management.

**Core Entity Architecture**:
```go
type Request struct {
    ID                string
    CatalogItemID     string
    UserID            string
    UserEmail         string
    UserTeams         []string
    Status            RequestStatus
    RequestData       map[string]interface{} // JSONB
    CorrelationID     string
    ErrorContext      *ErrorContext          // JSONB
    EscalationTicket  string
    CreatedAt         time.Time
    UpdatedAt         time.Time
    CompletedAt       *time.Time
    AbortedAt         *time.Time
}

type RequestAction struct {
    ID               string
    RequestID        string
    ActionIndex      int
    ActionType       string  // "jira-ticket" in Q3
    ActionConfig     map[string]interface{} // JSONB
    Status           ActionStatus
    Output           map[string]interface{} // JSONB
    ErrorDetails     map[string]interface{} // JSONB
    ExternalReference string // JIRA ticket key
    StartedAt        *time.Time
    CompletedAt      *time.Time
}
```

**Database Access Pattern Architecture**:
```go
type RequestRepository interface {
    Create(ctx context.Context, request *Request) error
    GetByID(ctx context.Context, id string) (*Request, error)
    GetByUserID(ctx context.Context, userID string, filters *ListFilters) ([]*Request, error)
    UpdateStatus(ctx context.Context, id string, status RequestStatus) error
    ListByStatus(ctx context.Context, status RequestStatus) ([]*Request, error)
}

type ActionRepository interface {
    Create(ctx context.Context, action *RequestAction) error
    GetByRequestID(ctx context.Context, requestID string) ([]*RequestAction, error)
    UpdateStatus(ctx context.Context, id string, status ActionStatus) error
    StoreOutput(ctx context.Context, id string, output map[string]interface{}) error
}
```

**Query Optimization Architecture**:
Database indexes optimized for Q3 synchronous query patterns:

- **User Request Queries**: Index on (user_id, created_at DESC) for request lists
- **Status Filtering**: Index on (status, created_at DESC) for admin views  
- **Correlation Tracking**: Index on correlation_id for audit trail queries
- **JIRA Reference Lookup**: Index on external_reference for status queries
- **Team Access Control**: GIN index on user_teams array for authorization

**Transaction Management Architecture**:
```go
type TransactionManager interface {
    WithTransaction(ctx context.Context, fn func(ctx context.Context) error) error
    BeginTransaction(ctx context.Context) (context.Context, error)
    CommitTransaction(ctx context.Context) error
    RollbackTransaction(ctx context.Context) error
}
```

**Audit Trail Data Architecture**:
Complete audit logging with correlation ID tracking:

```go
type AuditRepository interface {
    LogEvent(ctx context.Context, event *AuditEvent) error
    GetByCorrelationID(ctx context.Context, correlationID string) ([]*AuditEvent, error)
    GetByRequestID(ctx context.Context, requestID string) ([]*AuditEvent, error)
    GetByEventType(ctx context.Context, eventType string, timeRange *TimeRange) ([]*AuditEvent, error)
}
```

**Cache Architecture for Q3**:
Minimal caching strategy focused on catalog data:

```go
type CacheService interface {
    GetCatalogItem(ctx context.Context, id string) (*CatalogItem, error)
    SetCatalogItem(ctx context.Context, id string, item *CatalogItem, ttl time.Duration) error
    InvalidateCatalog(ctx context.Context) error
    GetFormSchema(ctx context.Context, catalogItemID string) (*FormSchema, error)
}
```

**Connection Pool Architecture**:
PostgreSQL connection management optimized for synchronous processing:

```go
type DatabaseConfig struct {
    MaxOpenConns    int           // Higher for persistent containers
    MaxIdleConns    int           // More idle connections
    ConnMaxLifetime time.Duration // Longer lifetime
    ConnMaxIdleTime time.Duration // Longer idle timeout
    QueryTimeout    time.Duration // Individual query timeout
}
```

## Architecture & Technology Stack

### Core Design Principles

1. **Schema-Driven**: All services defined via schema YAML documents
2. **Smart Fulfillment**: Automated actions with manual fallback - uses automation when available, falls back to manual JIRA when needed. No automatic error recovery; failures require human intervention
3. **Document-Driven Convergence**: Platform teams collaborate through central document store
4. **Progressive Enhancement**: Teams evolve from manual to automated at their own pace
5. **Container-First**: EKS deployment with persistent services and horizontal scaling

### Service Components

**Catalog Management Engine**
- GitHub repository integration with polling and webhook processing
- Schema validation and error reporting
- PostgreSQL persistence with in-memory caching
- CODEOWNERS enforcement for governance

**Request Orchestration System**
- Request lifecycle: Submitted → Validation → Queued → In Progress → Completed/Failed
- Variable substitution with 6+ scopes (user, metadata, request, system, environment, outputs)
- Circuit breaker architecture for external service calls
- State tracking and audit trail

**Multi-Action Fulfillment Engine**
- 4+ action types: JIRA, REST API, Terraform, GitHub workflows
- Sequential execution with dependency management in background workers
- Retry logic with exponential backoff handled by worker pool
- No automatic error recovery; failures stop execution and require manual intervention
- Failed requests provide detailed failure context for human decision-making
- Operators can retry failed actions, abort the request, or escalate to manual support
- Persistent worker processes maintain connection pools and state

### Technology Stack

**Runtime & Framework**
- Go programming language
- HTTP router framework (handling 1000+ catalog endpoints internally)
- OpenAPI 3.0 specification
- JSON Schema validation

**Data Storage**
- PostgreSQL 14+ (primary database)
- JSONB support for flexible state storage

**External Integrations**
- GitHub/GitLab APIs for catalog management
- JIRA REST API for ticket creation and status tracking
- AWS Parameter Store for secret management

**Deployment Architecture**
- EKS container pods with horizontal autoscaling
- Application Load Balancer for REST endpoints
- Helm charts for infrastructure deployment

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
5. **Status Polling**: Regular polling for status updates

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

**JIRA Status Handling**:
- The orchestrator does not track or store JIRA ticket status
- When a status request is made via API or CLI, the service queries JIRA in real-time
- Each status check makes a fresh API call to JIRA to get current ticket state
- Platform teams update ticket status in JIRA as work progresses
- No polling or caching of JIRA status occurs

**JIRA Status Mapping**:
```go
type JIRAStatusMapping struct {
    Open        []string `default:"[\"Open\", \"To Do\", \"Backlog\"]"`
    InProgress  []string `default:"[\"In Progress\", \"In Review\", \"Testing\"]"`
    Completed   []string `default:"[\"Done\", \"Closed\", \"Resolved\"]"`
    Failed      []string `default:"[\"Won't Do\", \"Cancelled\", \"Rejected\"]"`
}

func (j *JIRAStatusMapping) MapToRequestStatus(jiraStatus string) RequestStatus {
    for _, status := range j.InProgress {
        if status == jiraStatus {
            return StatusInProgress
        }
    }
    for _, status := range j.Completed {
        if status == jiraStatus {
            return StatusCompleted
        }
    }
    for _, status := range j.Failed {
        if status == jiraStatus {
            return StatusFailed
        }
    }
    return StatusSubmitted // Default for unmapped statuses
}
```

### Templating Engine Architecture Recommendations

**Executive Summary**: The current Mustache-based templating system requires architectural enhancements focused on core template processing concerns: variable resolution, function execution, template syntax support, and output generation.

**Core Templating Engine Concerns**:
- Variable scope resolution and context management
- Template function library and execution model
- Template syntax parsing and validation
- Output rendering and transformation pipeline
- Template metadata and dependency tracking

**Recommendation 1: Enhanced Variable Resolution Architecture**

**Pattern**: Hierarchical Scope Resolution with Context Isolation

**Variable Context Architecture**:
- **Scope Hierarchy**: Structured variable namespace with clear precedence rules
- **Context Isolation**: Prevent variable leakage between template executions
- **Dynamic Scoping**: Support runtime scope injection for different action types
- **Null Handling**: Consistent behavior for undefined variables across all scopes

**Variable Scope Design**:
- **fields**: User input from form submission with type-safe access
- **metadata**: Catalog item properties with structured access patterns
- **request**: Request context including user identity and correlation data
- **system**: System-generated values with controlled generation timing
- **environment**: Configuration values with environment-specific resolution
- **outputs**: Action chain results with dependency-aware access

**Recommendation 2: Template Function Library Architecture**

**Pattern**: Modular Function Registry with Type-Safe Execution

**Function Library Design**:
- **Core Functions**: Essential transformations (upper, lower, concat, replace)
- **Data Functions**: Format conversions (json, base64, timestamp, uuid)
- **Validation Functions**: Input validation and constraint checking
- **Conditional Functions**: Logic operations (default, coalesce, conditional)
- **Custom Functions**: Domain-specific transformations for platform needs

**Function Execution Model**:
- **Parameter Validation**: Type checking and constraint enforcement before execution
- **Error Handling**: Consistent error propagation with context preservation
- **Return Type Management**: Predictable output types for template composition
- **Function Composition**: Support for nested function calls with proper precedence

**Recommendation 3: Template Syntax and Parsing Architecture**

**Pattern**: Extensible Syntax Parser with Validation Pipeline

**Template Syntax Support**:
- **Variable References**: Standard {{scope.key}} syntax with nested object access
- **Function Calls**: {{function(args)}} syntax with parameter passing
- **Conditional Blocks**: {{#if condition}}...{{/if}} for dynamic content
- **Iteration Blocks**: {{#each array}}...{{/each}} for list processing
- **Comments**: {{! comment}} for template documentation

**Parsing Architecture**:
- **Lexical Analysis**: Token identification and classification
- **Syntax Validation**: Structure verification and error reporting
- **Dependency Extraction**: Variable and function reference identification
- **AST Generation**: Abstract syntax tree for optimized execution

**Recommendation 4: Template Output Generation Architecture**

**Pattern**: Streaming Renderer with Transformation Pipeline

**Output Generation Pipeline**:
- **Template Rendering**: Convert template AST to output string
- **Content Transformation**: Apply post-processing transformations
- **Encoding Management**: Handle character encoding and escaping
- **Size Management**: Control output size and truncation behavior

**Rendering Strategy**:
- **Incremental Rendering**: Process template sections independently
- **Error Recovery**: Continue rendering when non-critical errors occur
- **Output Buffering**: Efficient memory management for large templates
- **Content Validation**: Verify output meets expected format requirements

**Implementation Priority and Impact Assessment**:

1. **High Priority (Q3 Implementation)**:
   - Template compilation caching (Recommendation 1): Critical for performance at scale
   - Enhanced security validation (Recommendation 2): Essential for enterprise deployment
   - Basic performance monitoring (Recommendation 4): Required for production operations

2. **Medium Priority (Q4 Enhancement)**:
   - Advanced template functions (Recommendation 3): Improves developer experience and capabilities
   - Template debugging tools (Recommendation 5): Accelerates platform team development

3. **Low Priority (Future Enhancement)**:
   - AST parsing and optimization: Performance optimization for high-volume scenarios
   - Advanced template analytics: Deep insights for template usage patterns

**Security Considerations**:
- All template processing must be sandboxed to prevent code injection
- Function execution must have timeout controls to prevent DoS attacks
- Template output size limits prevent memory exhaustion attacks
- Variable scope isolation prevents information leakage between requests

**Performance Impact**:
- Template compilation caching reduces CPU usage by 60-80% for repeated templates
- Pre-compiled templates eliminate parse overhead during request processing
- Memory usage optimization through LRU cache eviction and size limits
- Concurrent rendering limits prevent resource exhaustion under load

**Developer Experience Benefits**:
- Rich debugging information accelerates catalog item development
- Template validation provides immediate feedback during development
- Performance metrics help optimize template design
- Enhanced function library reduces custom code requirements

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

**Variable Substitution Engine Implementation**:
```go
type VariableResolver struct {
    RequestData  map[string]interface{}
    Metadata     CatalogItemMetadata
    SystemVars   map[string]interface{}
    Environment  map[string]string
    ActionOutputs map[string]map[string]interface{}
}

func (vr *VariableResolver) ResolveTemplate(template string) (string, error) {
    // 1. Parse template for variable references
    variables := vr.extractVariables(template)
    
    // 2. Validate all variables can be resolved
    for _, variable := range variables {
        if _, err := vr.resolveVariable(variable); err != nil {
            return "", fmt.Errorf("cannot resolve variable %s: %w", variable, err)
        }
    }
    
    // 3. Apply template engine (Mustache)
    tmpl, err := mustache.ParseString(template)
    if err != nil {
        return "", fmt.Errorf("invalid template syntax: %w", err)
    }
    
    // 4. Build context map
    context := map[string]interface{}{
        "fields":      vr.RequestData,
        "metadata":    vr.Metadata,
        "system":      vr.SystemVars,
        "environment": vr.Environment,
        "outputs":     vr.ActionOutputs,
        "request": map[string]interface{}{
            "id":            vr.RequestData["_requestId"],
            "correlationId": vr.RequestData["_correlationId"],
            "user":          vr.RequestData["_user"],
            "timestamp":     vr.RequestData["_timestamp"],
        },
    }
    
    // 5. Render template
    result, err := tmpl.Render(context)
    if err != nil {
        return "", fmt.Errorf("template rendering failed: %w", err)
    }
    
    return result, nil
}

func (vr *VariableResolver) extractVariables(template string) []string {
    // Extract {{scope.key}} patterns
    re := regexp.MustCompile(`\{\{([^}]+)\}\}`)
    matches := re.FindAllStringSubmatch(template, -1)
    
    var variables []string
    for _, match := range matches {
        if len(match) > 1 {
            variables = append(variables, match[1])
        }
    }
    
    return variables
}

func (vr *VariableResolver) resolveVariable(variable string) (interface{}, error) {
    parts := strings.Split(variable, ".")
    if len(parts) < 2 {
        return nil, fmt.Errorf("invalid variable format: %s", variable)
    }
    
    scope := parts[0]
    path := parts[1:]
    
    switch scope {
    case "fields":
        return vr.resolveFromMap(vr.RequestData, path)
    case "metadata":
        return vr.resolveFromStruct(vr.Metadata, path)
    case "system":
        return vr.resolveFromMap(vr.SystemVars, path)
    case "environment":
        if len(path) == 1 {
            value, exists := vr.Environment[path[0]]
            if !exists {
                return nil, fmt.Errorf("environment variable %s not found", path[0])
            }
            return value, nil
        }
        return nil, fmt.Errorf("invalid environment variable path: %s", variable)
    case "outputs":
        if len(path) < 2 {
            return nil, fmt.Errorf("outputs require actionId.field format")
        }
        actionId := path[0]
        fieldPath := path[1:]
        actionOutputs, exists := vr.ActionOutputs[actionId]
        if !exists {
            return nil, fmt.Errorf("no outputs for action %s", actionId)
        }
        return vr.resolveFromMap(actionOutputs, fieldPath)
    default:
        return nil, fmt.Errorf("unknown variable scope: %s", scope)
    }
}
```

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
- GitHub workflow dispatch
- Terraform configuration management

**External Integrations**
- GitHub repository integration with polling
- JIRA REST API integration  
- PostgreSQL database for state tracking

**Reliability & Performance**
- Circuit breaker architecture for external API calls
- Retry logic with exponential backoff (limited retries, no infinite loops)
- Connection pooling for database
- **Error Handling**: All failures require manual intervention; no automatic recovery mechanisms

### Request Processing Architecture

**Q3 Synchronous Processing Architecture**:
The Q3 implementation follows the synchronous processing patterns defined in the Q3 Synchronous Processing Architecture section:

1. **Request Validation**: Synchronous validation using RequestValidator interface
2. **JIRA Action Execution**: Direct JIRA API calls via JIRAService interface (1-2 seconds)
3. **Database Transaction**: Store request and ticket reference using DatabaseTransaction pattern
4. **Immediate Response**: Return request ID and JIRA ticket details to client

**Q4 Background Worker Integration (Future Enhancement)**:
```yaml
backgroundWorkers:
  workerPool: 10  # Concurrent workers
  queueSize: 1000  # In-memory queue capacity
  processingTimeout: 300  # 5 minutes
  retryDelay: 30  # 30 seconds
  
containerConfig:
  replicas: 2-6  # Horizontal pod autoscaling
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
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

**Request State Definitions**:

Each request progresses through clearly defined states that represent the current status of the fulfillment process:

- `submitted`: Request received and stored, awaiting processing to begin
- `in_progress`: Request is actively being processed (actions are executing)
- `completed`: All actions succeeded, request fulfillment is finished
- `failed`: One or more actions failed, request processing has stopped
- `aborted`: Request was manually cancelled, no further processing will occur
- `escalated`: Request failed and was escalated to manual support via JIRA ticket; further resolution occurs outside the orchestrator system

**Request State Transition Rules**:

The request lifecycle follows strict state transition rules to ensure data integrity and proper workflow management:

**Valid State Transitions**:
- `submitted` → `in_progress` (when processing starts)
- `in_progress` → `completed` (when all actions succeed)  
- `in_progress` → `failed` (when any action fails)
- `failed` → `in_progress` (via retry operation)
- `failed` → `aborted` (via abort operation)
- `failed` → `escalated` (via escalate operation)

**Terminal States**: `completed`, `aborted`, `escalated`
- No further transitions allowed once reached
- Requests in terminal states are immutable within the orchestrator
- **Note**: `escalated` requests lose tracking of final resolution state as work continues in external JIRA system

**Retry-Eligible States**: `failed`
- Only failed requests can be retried
- Retry resets to `in_progress` and resumes from failed action

**State Transition Validation**:
- All transitions must be explicitly validated before database updates
- Invalid transitions return HTTP 400 with error details
- State changes trigger audit log entries with correlation IDs
- Concurrent state modification protection via database constraints

**Q3 Scope Limitations**:
- `validating` and `queued` states reserved for Q4 background processing
- Q3 uses synchronous processing: `submitted` → `in_progress` → terminal state

**Future Consideration**: The loss of final state tracking for `escalated` requests may need to be addressed in future versions through JIRA webhook integration or periodic status polling.

**Audit Logging Implementation**:
- Correlation ID tracking across all system components
- Structured JSON logging with standardized fields
- Database audit trail for all state changes

**Q3 Request Processing (Synchronous JIRA Only)**:
1. **Request Validation**: Immediate validation of request against catalog schema
2. **JIRA Ticket Creation**: Synchronous JIRA API call with variable substitution (1-2 seconds)
3. **State Persistence**: Store request and JIRA ticket reference in database
4. **Response**: Return request ID and JIRA ticket key to user immediately
5. **Status Queries**: Real-time JIRA status queries when requested

**Q4 Background Processing Architecture (Future)**:
1. **Request Queuing**: In-memory queue for long-running operations (Terraform, etc.)
2. **Worker Pool Processing**: Background goroutines process queued requests
3. **Action Execution**: Sequential execution of catalog-defined actions
4. **State Persistence**: Each action result stored in database
5. **Error Handling**: Failed actions trigger manual intervention workflow
6. **Status Updates**: Real-time status updates via WebSocket connections

**Volume Expectations**:
- **Very Low Volume Service**: Designed for internal platform teams, not end users
- **Expected Load**: 10-50 requests per day across entire organization
- **Peak Capacity**: Designed to handle 100 requests per hour maximum
- **Concurrent Users**: 5-10 platform engineers typically active
- **No High-Performance Requirements**: Simple, reliable operation over speed

**Q3 Request Processing Architecture**:
The Q3 synchronous processing follows the architectural patterns defined in the Q3 Synchronous Processing Architecture section:

```go
type RequestProcessor struct {
    Database     DatabaseService
    ActionRunner ActionRunner
    Logger       Logger
}
```

**Processing Flow Architecture**:
1. **Request Loading**: Load request from database using DatabaseService interface
2. **Status Update**: Update status to in_progress with transaction management
3. **Sequential Action Execution**: Execute JIRA actions using ActionRunner interface
4. **Error Context Storage**: Store detailed error context for manual resolution
5. **Result Persistence**: Store action results and update request progress
6. **Completion**: Mark request as completed or failed based on action outcomes

**Q3 Request Response Format**:
```json
{
  "requestId": "req-123e4567-e89b-12d3-a456-426614174000",
  "jiraTicket": "PLATFORM-12345",
  "jiraUrl": "https://company.atlassian.net/browse/PLATFORM-12345",
  "status": "submitted",
  "correlationId": "corr-123e4567-e89b-12d3-a456-426614174000",
  "createdAt": "2025-08-18T10:30:00Z",
  "processingTime": "1.2s"
}
```

**Q4 Background Worker Message Format (Future)**:
```json
{
  "requestId": "req-123e4567-e89b-12d3-a456-426614174000",
  "catalogItemId": "database-postgresql-standard",
  "priority": "normal",
  "correlationId": "corr-123e4567-e89b-12d3-a456-426614174000",
  "timestamp": "2025-08-18T10:30:00Z",
  "retryCount": 0,
  "maxRetries": 3,
  "workerAssignment": "worker-pool-1"
}
```

### GitHub Catalog Integration

**Catalog Update Processing**:
1. **Periodic Polling**: Regular polling of GitHub repository for changes
2. **Change Detection**: Identify added, modified, or deleted catalog files
3. **Validation Pipeline**: Schema validation for all changed files
4. **Cache Invalidation**: Refresh in-memory cache and update PostgreSQL
5. **Notification**: Send status updates via notification channels

**Catalog Synchronization**:

The orchestrator service stays synchronized with the catalog repository through GitHub webhooks:

- **Push Events**: When changes are merged to the main branch, GitHub sends a webhook to the PAO service
- **Webhook Endpoint**: The service exposes `/api/v1/webhooks/github` to receive catalog update notifications
- **Validation**: The service validates incoming catalog changes against the schema before accepting them
- **Cache Invalidation**: Successfully validated changes trigger cache refresh in the service
- **Fallback**: Manual catalog refresh available via `/api/v1/catalog/refresh` endpoint if needed

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
- **In-Memory Cache**: Individual catalog items with expiration management
- **PostgreSQL Storage**: Persistent catalog storage with versioning
- **Cache Invalidation**: Event-driven invalidation on catalog updates

**Error Handling for Malformed Catalog Files**:
- Schema validation errors logged with file path and line numbers
- Invalid files excluded from catalog without breaking entire update
- Error notifications sent to catalog repository via GitHub Status API
- Detailed error reports available via `/api/v1/catalog/validation-errors`

**GitHub Webhook Architecture**:
The GitHub webhook integration follows a clean architectural pattern for catalog synchronization:

```go
type GitHubWebhookHandler struct {
    Secret           string
    CatalogProcessor *CatalogProcessor
    Logger           Logger
}
```

**Webhook Processing Architecture**:
1. **Signature Verification**: Validate webhook authenticity using secret verification
2. **Event Parsing**: Parse GitHub push events and extract catalog file changes
3. **File Filtering**: Identify catalog-specific changes (catalog/*.yaml files)
4. **Asynchronous Processing**: Process catalog updates in background goroutines
5. **Error Handling**: Log processing errors without blocking webhook response

**Catalog Synchronization Pattern**:
- **Push Event Detection**: Filter commits for catalog directory changes
- **File Deduplication**: Ensure unique file processing across multiple commits
- **Background Processing**: Use goroutines for non-blocking catalog updates
- **Error Isolation**: Prevent catalog processing errors from affecting webhook responses

## Performance & Success Metrics

### Performance Targets
- **API Response Time**: < 500ms for catalog operations
- **Request Submission**: < 3 seconds end-to-end (including JIRA ticket creation)
- **System Availability**: 99.5% uptime (allows for maintenance windows)
- **Throughput**: 100 requests per hour maximum (very low volume service)
- **Status Monitoring**: < 2 seconds for real-time JIRA status queries
- **Concurrent Users**: Support 5-10 platform engineers simultaneously

### Business Impact Metrics
- **Provisioning Time**: Significant reduction from multi-week delays
- **Platform Adoption**: High platform team adoption with multiple services
- **Developer Satisfaction**: High rating on self-service experience
- **Automation Rate**: High percentage of services automated

### Operational Excellence
- **Error Rate**: Low failure rate for automated actions
- **Security Compliance**: Strong security posture with full audit trail
- **MTTR**: Fast incident resolution
- **Support Efficiency**: Timely resolution for platform team issues

## Architectural Recommendation

### Deployment Architecture: EKS Containers (Recommended)

**EKS container deployment is strongly recommended** over AWS Lambda for the Platform Automation Orchestrator service.

### Executive Summary

For an enterprise organization with 1,700 developers performing 250,000 application deployments annually, EKS containers provide superior operational characteristics despite slightly higher costs. The annual cost difference ($1,536 EKS vs $2,500 Lambda with infrastructure) is negligible at enterprise scale while delivering significantly better developer experience.

### Traffic Analysis and Scaling

**Volume Expectations**:
- **Daily API Volume**: 3,100-10,400 requests/day
- **Peak Traffic**: 200-700 calls/hour during deployment windows (9-11 AM, 2-4 PM)
- **Traffic Patterns**: Sustained CI/CD integration load with seasonal spikes
- **Growth Projection**: 15,000-20,000 requests/day as platform adoption increases

**API Call Breakdown**:
- Service Requests: 1,200-3,000/day
- Status & Monitoring: 1,400-6,000/day (2-3x checks per deployment)
- Request Details/Logs: 300-800/day (troubleshooting)
- Catalog Operations: 200-600/day (discovery)

### Cost Comparison

**AWS Lambda Total Cost**: ~$2,350-$2,500/year
- Compute costs: $541-$1,884/year
- RDS Proxy (required): $1,680/year
- CloudWatch/X-Ray: $70-$150/year

**EKS Container Total Cost**: ~$1,536/year
- Pod resources: $1,486/year (3 vCPU, 6GB RAM, 24/7)
- Storage: $50/year
- Existing infrastructure: $0 (shared EKS cluster, ALB)

**Annual Savings with EKS**: $814-$964/year

### Operational Advantages

**EKS Benefits**:
- **No Cold Starts**: Eliminates 1-3 second delays affecting 10-15% of requests
- **Consistent Performance**: Sub-200ms response times under normal load
- **Persistent Connections**: Stable PostgreSQL connection pools
- **Better Observability**: Standard Kubernetes monitoring and logging
- **Simplified Operations**: 10-20 hours/year engineering time savings

**Lambda Operational Overhead**:
- Cold start debugging and optimization
- Complex RDS Proxy configuration
- Connection pool management across invocations
- Performance unpredictability during spikes
- **Estimated overhead**: 20-40 hours/year engineering time

### Performance Impact

**Lambda Performance Issues**:
- Cold start latency: 1-3 seconds (10-15% of requests)
- Connection establishment overhead per invocation
- Variable performance under sustained load
- Complex debugging across distributed functions

**EKS Performance Consistency**:
- Zero cold starts with persistent processes
- Predictable resource allocation
- Better circuit breaker pattern implementation
- Horizontal pod autoscaling capabilities

### Scalability Considerations

**Lambda Scaling Concerns**:
- Linear cost increase with request volume
- Break-even point with EKS at ~15,000 requests/day
- Concurrent execution limits (1,000 default)
- Connection pooling complexity

**EKS Scaling Benefits**:
- Fixed cost regardless of request volume
- Better resource utilization efficiency
- Horizontal pod autoscaling (2-6 pods)
- Superior traffic distribution

### Risk Analysis

**Lambda Risks** (High):
- Performance degradation during traffic spikes
- Cold start impact on developer experience
- Complex debugging across distributed functions
- Vendor lock-in to AWS Lambda runtime

**EKS Risks** (Low-Medium):
- Requires Kubernetes expertise (mitigated by existing platform)
- More complex initial setup (one-time cost)
- Potential resource over-provisioning (managed via quotas)

### Implementation Strategy

**Phase 1: EKS Deployment**
- Deploy 2 API pods: 1 vCPU + 2GB RAM each
- Configure horizontal pod autoscaling (2-6 pods)
- Implement persistent database connections
- Set up comprehensive monitoring and alerting

**Phase 2: Optimization**
- Monitor actual resource usage patterns
- Tune resource requests/limits based on data
- Implement circuit breakers for external dependencies
- Add performance testing and alerting

**Cost Management**:
- Resource quotas to prevent over-provisioning
- Monthly actual vs. requested resource monitoring
- Scale down during known low-traffic periods
- Regular cost review and optimization

### Alternative Considerations

**If Lambda Required** (Mitigation Strategy):
- Implement Provisioned Concurrency ($150/month additional)
- Use RDS Proxy for connection management
- Optimize function memory based on usage patterns
- Plan migration path to containers at 15,000+ requests/day

**Hybrid Approach**:
- Lambda: Catalog processor (infrequent, event-driven)
- EKS: API handlers and background processors
- Cost: ~$1,000/year
- Complexity: Moderate operational overhead

### Recommendation Rationale

**Primary Recommendation: EKS Container Deployment**

1. **Cost Effectiveness**: $814-$964 annual savings compared to Lambda
2. **Operational Excellence**: Better suited for developer-facing services
3. **Performance Predictability**: Consistent response times, no cold starts
4. **Developer Experience**: Faster, more reliable service improves platform adoption
5. **Scalability**: Superior cost profile as traffic grows beyond current projections

For an enterprise platform supporting 1,700 developers, the recommendation prioritizes long-term operational excellence over short-term cost optimization, recognizing that platform services are critical infrastructure requiring reliability and performance.

**Monitoring & Observability**
- Health check endpoints (`/api/v1/health`, `/api/v1/health/ready`)
- Structured JSON logging with correlation IDs

**Security & Compliance**
- AWS IAM authentication with SigV4 signing
- Audit logging with correlation IDs
- AWS Parameter Store for secret configuration
- Request validation and sanitization

## Service Configuration

### Container Configuration

**Service Container Requirements**:
- HTTP server listening on port 8080
- Health check endpoints: `/api/v1/health` and `/api/v1/health/ready`
- Environment variable configuration support
- Graceful shutdown handling
- Resource requirements: 1-2 CPU cores, 2-4GB RAM

### Security Configuration

- **Authentication**: AWS IAM with SigV4 request signing
- **Secret Management**: AWS Parameter Store for sensitive configuration
- **Database Access**: Aurora PostgreSQL with IAM authentication
- **External APIs**: JIRA and GitHub API authentication via tokens from Parameter Store

### Service Health Monitoring

- **Health Endpoints**: `/api/v1/health` and `/api/v1/health/ready` for container orchestration
- **Logging**: Structured JSON logs with correlation ID tracking

### Build and Deployment

- **Build Requirements**: Go binary compilation with container image packaging
- **Deployment**: Standard containerized deployment process
- **Configuration**: Environment variable and Parameter Store integration

### Database Connection Pooling and Optimization

```go
// EKS-optimized connection pool settings
type DatabaseConfig struct {
    // Connection pool settings for persistent containers
    MaxOpenConns    int           `default:"50"`    // Higher for containers
    MaxIdleConns    int           `default:"20"`    // More idle connections
    ConnMaxLifetime time.Duration `default:"1h"`    // Longer lifetime
    ConnMaxIdleTime time.Duration `default:"10m"`   // Longer idle timeout
    
    // Direct database connection (no proxy needed)
    DatabaseURL     string `env:"DATABASE_URL"`
    IAMAuth         bool   `default:"true"`
    
    // SSL configuration
    SSLMode         string `default:"require"`
    SSLCert         string `env:"DB_SSL_CERT_PATH"`
    
    // Query timeouts
    QueryTimeout    time.Duration `default:"30s"`
    PrepareTimeout  time.Duration `default:"5s"`
}

// Connection pool optimization for EKS containers
func ConfigureDatabasePool(db *sql.DB, config DatabaseConfig) {
    db.SetMaxOpenConns(config.MaxOpenConns)
    db.SetMaxIdleConns(config.MaxIdleConns)
    db.SetConnMaxLifetime(config.ConnMaxLifetime)
    db.SetConnMaxIdleTime(config.ConnMaxIdleTime)
}
```

### In-Memory Caching Strategy

```yaml
cacheConfig:
  catalogItems: 3600      # 1 hour TTL
  categories: 21600       # 6 hours TTL
  requestStatus: 300      # 5 minutes TTL
  formSchemas: 7200       # 2 hours TTL
  maxMemoryUsage: "512MB" # Maximum cache memory
  evictionPolicy: "LRU"   # Least Recently Used
```

### Service Process Organization

```yaml
serviceComponents:
  api-server:
    purpose: "Handle all REST API endpoints"
    routes: "/api/v1/*"
    port: 8080
    
  catalog-processor:
    purpose: "Background goroutine for GitHub repository polling"
    schedule: "Every 5 minutes"
    
  request-processor:
    purpose: "Background worker pool for request processing"
    workers: 10
    
  status-updater:
    purpose: "Background goroutine for external system status updates"
    schedule: "Every 5 minutes"
```

### Error Context Preservation for Manual Escalation

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


### Complete Environment Variables

```bash
# Database Configuration
DATABASE_HOST=pao-aurora-cluster.cluster-xxx.us-east-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_NAME=pao
DATABASE_USER=pao_service
DB_MAX_OPEN_CONNS=50
DB_MAX_IDLE_CONNS=20
DB_CONN_MAX_LIFETIME=1h
DB_CONN_MAX_IDLE_TIME=10m

# Cache Configuration
CACHE_MAX_MEMORY=512MB
CACHE_EVICTION_POLICY=LRU

# JIRA Integration
JIRA_BASE_URL=https://company.atlassian.net
JIRA_USERNAME=platform-automation
JIRA_DEFAULT_PROJECT=PLATFORM

# GitHub Integration
CATALOG_GITHUB_REPO=company/platform-catalog
CATALOG_GITHUB_BRANCH=main
CATALOG_POLL_INTERVAL=5m

# AWS Parameter Store Paths for Secrets
JIRA_API_TOKEN_PATH=/pao/jira/api-token
GITHUB_TOKEN_PATH=/pao/github/token
GITHUB_WEBHOOK_SECRET_PATH=/pao/github/webhook-secret

# AWS Configuration
AWS_REGION=us-east-1
AWS_SECRETS_MANAGER_REGION=us-east-1

# EKS Configuration
KUBERNETES_NAMESPACE=platform-orchestrator
SERVICE_ACCOUNT_NAME=platform-orchestrator
WORKER_POOL_SIZE=10
MAX_CONCURRENT_REQUESTS=100

# Service Configuration
CORRELATION_ID_HEADER=X-Correlation-ID
API_TIMEOUT=30s
REQUEST_TIMEOUT=5m
MAX_REQUEST_SIZE=1MB
RATE_LIMIT_REQUESTS_PER_MINUTE=60

# Monitoring and Logging
LOG_LEVEL=info
LOG_FORMAT=json
METRICS_ENABLED=true
TRACING_ENABLED=true
TRACING_SAMPLE_RATE=0.1
```

### Configuration Validation

```go
type ServiceConfig struct {
    Database struct {
        Host            string        `env:"DATABASE_HOST" validate:"required"`
        Port            int           `env:"DATABASE_PORT" default:"5432"`
        Name            string        `env:"DATABASE_NAME" validate:"required"`
        User            string        `env:"DATABASE_USER" validate:"required"`
        UseIAMAuth      bool          `default:"true"`
        MaxOpenConns    int           `env:"DB_MAX_OPEN_CONNS" default:"50"`
        MaxIdleConns    int           `env:"DB_MAX_IDLE_CONNS" default:"20"`
        ConnMaxLifetime time.Duration `env:"DB_CONN_MAX_LIFETIME" default:"1h"`
    }
    
    Cache struct {
        MaxMemory      string `env:"CACHE_MAX_MEMORY" default:"512MB"`
        EvictionPolicy string `env:"CACHE_EVICTION_POLICY" default:"LRU"`
    }
    
    JIRA struct {
        BaseURL         string `env:"JIRA_BASE_URL" validate:"required,url"`
        Username        string `env:"JIRA_USERNAME" validate:"required"`
        APITokenPath    string `env:"JIRA_API_TOKEN_PATH" validate:"required"`
        DefaultProject  string `env:"JIRA_DEFAULT_PROJECT" default:"PLATFORM"`
    }
    
    GitHub struct {
        Repository        string        `env:"CATALOG_GITHUB_REPO" validate:"required"`
        TokenPath         string        `env:"GITHUB_TOKEN_PATH" validate:"required"`
        Branch            string        `env:"CATALOG_GITHUB_BRANCH" default:"main"`
        PollInterval      time.Duration `env:"CATALOG_POLL_INTERVAL" default:"5m"`
        WebhookSecretPath string        `env:"GITHUB_WEBHOOK_SECRET_PATH" validate:"required"`
    }
    
    ParameterStore struct {
        Region string `env:"AWS_REGION" validate:"required"`
    }
    
    AWS struct {
        Region    string `env:"AWS_REGION" validate:"required"`
    }
    
    EKS struct {
        Namespace           string `env:"KUBERNETES_NAMESPACE" default:"platform-orchestrator"`
        ServiceAccount      string `env:"SERVICE_ACCOUNT_NAME" default:"platform-orchestrator"`
        WorkerPoolSize      int    `env:"WORKER_POOL_SIZE" default:"10"`
        MaxConcurrentReqs   int    `env:"MAX_CONCURRENT_REQUESTS" default:"100"`
    }
    
    Service struct {
        APITimeout     time.Duration `env:"API_TIMEOUT" default:"30s"`
        RequestTimeout time.Duration `env:"REQUEST_TIMEOUT" default:"5m"`
        MaxRequestSize int64         `env:"MAX_REQUEST_SIZE" default:"1048576"` // 1MB
        RateLimit      int           `env:"RATE_LIMIT_REQUESTS_PER_MINUTE" default:"60"`
    }
}

// Configuration Loading Architecture
type ConfigLoader interface {
    LoadConfig() (*ServiceConfig, error)
    LoadSecrets(config *ServiceConfig) error
    ValidateConfig(config *ServiceConfig) error
}

// Configuration loading follows these architectural patterns:
// 1. Environment variable parsing with validation tags
// 2. AWS Parameter Store integration for secrets
// 3. Configuration validation with required field checking
// 4. Default value application for optional settings
```

### Service Configuration

```yaml
service:
  port: 8080
  environment:
    DATABASE_HOST: ${env:DATABASE_HOST}
    DATABASE_NAME: ${env:DATABASE_NAME}
    DATABASE_USER: ${env:DATABASE_USER}
    CACHE_MAX_MEMORY: ${env:CACHE_MAX_MEMORY}
    CACHE_EVICTION_POLICY: ${env:CACHE_EVICTION_POLICY}
    JIRA_BASE_URL: ${env:JIRA_BASE_URL}
    CATALOG_GITHUB_REPO: ${env:CATALOG_GITHUB_REPO}
    # Secrets loaded from AWS Parameter Store
    JIRA_API_TOKEN_PATH: ${env:JIRA_API_TOKEN_PATH}
    GITHUB_TOKEN_PATH: ${env:GITHUB_TOKEN_PATH}
    GITHUB_WEBHOOK_SECRET_PATH: ${env:GITHUB_WEBHOOK_SECRET_PATH}
  
workers:
  catalog_processor:
    interval: "5m"
  request_processor:
    pool_size: 10
  status_updater:
    interval: "5m"
```

## SQL Schema

### Q3/Q4 Database Schema

**Core Tables Required for Q3 Foundation Epic**

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Q3: Requests table - Core request tracking for synchronous JIRA processing
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    catalog_item_id VARCHAR(255) NOT NULL,
    catalog_item_version VARCHAR(50) NOT NULL DEFAULT '1.0.0',
    user_id VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_teams TEXT[] NOT NULL DEFAULT '{}',
    -- Q3: Limited status set for synchronous processing
    status VARCHAR(50) NOT NULL CHECK (status IN (
        'submitted', 'in_progress', 'completed', 'failed', 'aborted', 'escalated'
        -- Q4: Add 'validating', 'queued' for background processing
    )),
    request_data JSONB NOT NULL, -- User form input fields
    current_action_index INTEGER NOT NULL DEFAULT 0, -- Q3: Sequential action tracking
    error_context JSONB, -- Q3: Manual failure resolution context
    correlation_id UUID NOT NULL DEFAULT uuid_generate_v4(), -- Q3: Required for audit trail
    escalation_ticket_id VARCHAR(100), -- Q3: JIRA ticket for manual escalation
    escalation_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    aborted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_escalation CHECK (
        (status = 'escalated' AND escalation_ticket_id IS NOT NULL) OR
        (status != 'escalated' AND escalation_ticket_id IS NULL)
    )
);

-- Q3: Request actions table - Individual action execution tracking
CREATE TABLE request_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    action_index INTEGER NOT NULL, -- Q3: Sequential processing order
    -- Q3: Only 'jira-ticket' needed; Q4: Add 'rest-api', 'terraform', 'github-workflow'
    action_type VARCHAR(100) NOT NULL CHECK (action_type IN (
        'jira-ticket'
        -- Q4: Expand to: 'jira-ticket', 'rest-api', 'terraform', 'github-workflow'
    )),
    action_config JSONB NOT NULL, -- Template and variable configuration
    status VARCHAR(50) NOT NULL CHECK (status IN (
        'pending', 'in_progress', 'completed', 'failed'
        -- Q4: Add 'retrying' for background worker retry logic
    )),
    output JSONB, -- Q4: Action outputs for variable chaining
    error_details JSONB, -- Q3: Failure context for manual resolution
    retry_count INTEGER NOT NULL DEFAULT 0, -- Q4: Background worker retry tracking
    external_reference VARCHAR(255), -- Q3: JIRA ticket key; Q4: GitHub run ID, etc.
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(request_id, action_index)
);

-- Q3: Catalog items cache table - GitHub repository cache
CREATE TABLE catalog_items (
    id VARCHAR(255) PRIMARY KEY, -- catalog-item-id from YAML
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    version VARCHAR(50) NOT NULL,
    category VARCHAR(100) NOT NULL, -- compute, databases, security, etc.
    owner_team VARCHAR(255) NOT NULL,
    owner_contact VARCHAR(255) NOT NULL,
    definition JSONB NOT NULL, -- Complete catalog item YAML as JSON
    file_path VARCHAR(500) NOT NULL, -- GitHub repository file path
    git_sha VARCHAR(40) NOT NULL, -- Q3: GitHub webhook synchronization
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Q3: Audit log table - Complete audit trail with correlation ID tracking
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    correlation_id UUID NOT NULL, -- Q3: Required for request tracing
    request_id UUID REFERENCES requests(id) ON DELETE SET NULL,
    action_id UUID REFERENCES request_actions(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL, -- request_created, status_changed, etc.
    event_data JSONB NOT NULL,
    user_id VARCHAR(255),
    user_email VARCHAR(255),
    source_system VARCHAR(100) NOT NULL, -- orchestrator_service, devctl, etc.
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Note: No user sessions table - System is stateless with AWS SigV4 authentication
-- User identity and teams extracted from AWS IAM/SSO on each request
```

### Indexes for Performance

**Q3 Foundation Epic - Essential Indexes**

```sql
-- Q3: Core request query patterns for synchronous processing
CREATE INDEX idx_requests_user_id ON requests(user_id); -- User's request list
CREATE INDEX idx_requests_status ON requests(status); -- Status filtering
CREATE INDEX idx_requests_catalog_item ON requests(catalog_item_id); -- Service filtering
CREATE INDEX idx_requests_created_at ON requests(created_at DESC); -- Chronological listing
CREATE INDEX idx_requests_correlation_id ON requests(correlation_id); -- Q3: Audit trail lookup
CREATE INDEX idx_requests_status_created ON requests(status, created_at DESC); -- Combined filtering

-- Q3: User team-based access control
CREATE INDEX idx_requests_user_teams ON requests USING GIN(user_teams);

-- Q3: Sequential action processing lookup patterns
CREATE INDEX idx_actions_request_id ON request_actions(request_id); -- Actions per request
CREATE INDEX idx_actions_status ON request_actions(status); -- Failed action queries
CREATE INDEX idx_actions_external_ref ON request_actions(external_reference) WHERE external_reference IS NOT NULL; -- JIRA ticket lookup

-- Q3: Catalog browsing and GitHub synchronization
CREATE INDEX idx_catalog_category ON catalog_items(category); -- Browse by category
CREATE INDEX idx_catalog_owner_team ON catalog_items(owner_team); -- Team ownership
CREATE INDEX idx_catalog_active ON catalog_items(is_active) WHERE is_active = true; -- Active items only
CREATE INDEX idx_catalog_git_sha ON catalog_items(git_sha); -- Q3: GitHub webhook sync

-- Q3: Audit trail with correlation ID tracking
CREATE INDEX idx_audit_correlation_id ON audit_logs(correlation_id); -- End-to-end tracing
CREATE INDEX idx_audit_request_id ON audit_logs(request_id) WHERE request_id IS NOT NULL; -- Request history
CREATE INDEX idx_audit_event_type ON audit_logs(event_type); -- Event filtering
CREATE INDEX idx_audit_created_at ON audit_logs(created_at DESC); -- Chronological audit

-- Q4: Production indexes (not needed for Q3)
-- CREATE INDEX idx_actions_type_status ON request_actions(action_type, status); -- Multi-action type queries
-- CREATE INDEX idx_audit_user_id ON audit_logs(user_id) WHERE user_id IS NOT NULL; -- User activity tracking
```

### Triggers for Automated Updates

```sql
-- Auto-update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_requests_updated_at 
    BEFORE UPDATE ON requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_actions_updated_at 
    BEFORE UPDATE ON request_actions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_catalog_updated_at 
    BEFORE UPDATE ON catalog_items 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Audit logging trigger
CREATE OR REPLACE FUNCTION log_request_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (
        correlation_id, request_id, event_type, event_data, 
        user_id, user_email, source_system
    ) VALUES (
        COALESCE(NEW.correlation_id, OLD.correlation_id),
        COALESCE(NEW.id, OLD.id),
        CASE 
            WHEN TG_OP = 'INSERT' THEN 'request_created'
            WHEN TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN 'request_status_changed'
            WHEN TG_OP = 'UPDATE' THEN 'request_updated'
            WHEN TG_OP = 'DELETE' THEN 'request_deleted'
        END,
        jsonb_build_object(
            'old_status', OLD.status,
            'new_status', NEW.status,
            'operation', TG_OP
        ),
        COALESCE(NEW.user_id, OLD.user_id),
        COALESCE(NEW.user_email, OLD.user_email),
        'orchestrator_service'
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER audit_request_changes
    AFTER INSERT OR UPDATE OR DELETE ON requests
    FOR EACH ROW
    EXECUTE FUNCTION log_request_changes();
```

### Migration Strategy

**Migration Versioning**

```sql
-- Migration tracking table
CREATE TABLE schema_migrations (
    version VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) NOT NULL
);

-- Initial migration record
INSERT INTO schema_migrations (version, description, checksum) 
VALUES ('001_initial_schema', 'Initial database schema creation', 'sha256_checksum_here');
```

### Foreign Key Relationships and Cascading Behaviors

```sql
-- Explicit foreign key constraints with appropriate cascading
ALTER TABLE request_actions 
    ADD CONSTRAINT fk_actions_request 
    FOREIGN KEY (request_id) 
    REFERENCES requests(id) 
    ON DELETE CASCADE 
    ON UPDATE RESTRICT;

ALTER TABLE audit_logs 
    ADD CONSTRAINT fk_audit_request 
    FOREIGN KEY (request_id) 
    REFERENCES requests(id) 
    ON DELETE SET NULL 
    ON UPDATE RESTRICT;

ALTER TABLE audit_logs 
    ADD CONSTRAINT fk_audit_action 
    FOREIGN KEY (action_id) 
    REFERENCES request_actions(id) 
    ON DELETE SET NULL 
    ON UPDATE RESTRICT;

-- Check constraints for data integrity
ALTER TABLE requests 
    ADD CONSTRAINT valid_current_action 
    CHECK (current_action_index >= 0);

ALTER TABLE request_actions 
    ADD CONSTRAINT valid_action_index 
    CHECK (action_index >= 0);

ALTER TABLE request_actions 
    ADD CONSTRAINT valid_retry_count 
    CHECK (retry_count >= 0 AND retry_count <= 5);
```

### Database Maintenance

```sql
-- Cleanup queries for automated maintenance
-- Remove completed requests older than 90 days
DELETE FROM requests 
WHERE status = 'completed' 
AND completed_at < CURRENT_TIMESTAMP - INTERVAL '90 days';

-- Remove audit logs older than 1 year
DELETE FROM audit_logs 
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 year';

-- Remove expired user sessions
DELETE FROM user_sessions 
WHERE expires_at < CURRENT_TIMESTAMP;

-- Vacuum and analyze for performance
VACUUM ANALYZE requests;
VACUUM ANALYZE request_actions;
VACUUM ANALYZE audit_logs;
```

## Future Enhancements

### Q4 2025 and Beyond

**Advanced Action Types**
- **Terraform Integration**: Direct Terraform Cloud/Enterprise integration with state management
- **AWS Lambda Functions**: Direct Lambda invocation for custom automation workflows
- **CloudFormation/CDK**: AWS native infrastructure provisioning capabilities
- **Ansible Playbooks**: Configuration management and server provisioning
- **Custom Scripts**: Shell script execution in secure sandboxed environments

**Enhanced Orchestration**
- **Parallel Action Execution**: Execute independent actions concurrently for faster provisioning
- **Conditional Workflows**: Dynamic action execution based on runtime conditions
- **Approval Gates**: Human approval requirements for sensitive operations
- **Rollback Mechanisms**: Automated rollback on failure with resource cleanup
- **Circuit Breaker Patterns**: Advanced failure handling and service degradation

**Developer Experience Improvements**
- **Real-time Status Updates**: WebSocket connections for live status streaming
- **Interactive Debugging**: Step-through debugging for failed requests
- **Request Templates**: Saved request configurations for common use cases
- **Bulk Operations**: Submit multiple related requests as atomic operations
- **Resource Dependency Visualization**: Graphical view of service dependencies

**Platform Team Tools**
- **Catalog Analytics**: Usage metrics and performance insights for catalog items
- **A/B Testing Framework**: Test new service configurations with subset of users
- **Validation Sandbox**: Test catalog items in isolated environment before publishing
- **Auto-generated Documentation**: Dynamic documentation generation from catalog schemas
- **Cost Estimation**: Predicted resource costs for requested services

**Security and Compliance**
- **Policy as Code**: Automated policy enforcement through Open Policy Agent (OPA)
- **Compliance Reporting**: Automated compliance validation and reporting
- **Secret Rotation**: Automated secret rotation for provisioned resources
- **Access Reviews**: Periodic access reviews for provisioned resources
- **Data Classification**: Automatic data classification and protection policies

**Multi-Cloud and Hybrid**
- **Multi-Cloud Support**: Extend beyond AWS to Azure, GCP, and on-premises
- **Cloud Provider Abstraction**: Abstract cloud-specific implementations
- **Hybrid Cloud Workflows**: Seamless provisioning across cloud boundaries
- **Cost Optimization**: Cross-cloud cost comparison and optimization recommendations
- **Disaster Recovery**: Multi-region and multi-cloud disaster recovery automation

**AI and Machine Learning**
- **Intelligent Recommendations**: ML-powered service recommendations based on usage patterns
- **Anomaly Detection**: Automated detection of unusual provisioning patterns
- **Predictive Scaling**: Predict resource needs based on historical data
- **Natural Language Processing**: Natural language service requests and troubleshooting
- **Automated Optimization**: AI-driven resource right-sizing and cost optimization

**Enterprise Integration**
- **ServiceNow Integration**: Bi-directional integration with enterprise ITSM
- **Active Directory/LDAP**: Enhanced user management and group-based access control
- **Enterprise Monitoring**: Integration with enterprise monitoring and alerting systems
- **Compliance Frameworks**: Built-in support for SOC2, PCI-DSS, HIPAA, etc.
- **Financial Management**: Chargeback, showback, and budget management capabilities

**Advanced Analytics and Observability**
- **Request Flow Tracing**: End-to-end tracing across all system components
- **Performance Profiling**: Detailed performance analysis and optimization recommendations
- **Capacity Planning**: Predictive capacity planning based on usage trends
- **Business Metrics**: Integration with business KPIs and outcome tracking
- **Custom Dashboards**: User-configurable dashboards for different stakeholder groups

**Ecosystem Extensions**
- **Marketplace Integration**: Public and private marketplace for community-contributed catalog items
- **Plugin Architecture**: Extensible plugin system for custom integrations
- **API Gateway**: Enhanced API management with rate limiting, versioning, and documentation
- **Event Streaming**: Real-time event streaming for external system integration
- **GraphQL Support**: Alternative GraphQL API alongside REST for flexible data querying

### Implementation Priorities

**Phase 1 (Q4 2025)**: Terraform integration, parallel execution, real-time updates
**Phase 2 (Q1 2026)**: Multi-cloud support, advanced security features, AI recommendations
**Phase 3 (Q2 2026)**: Enterprise integrations, compliance frameworks, marketplace
**Phase 4 (Q3 2026)**: Advanced analytics, ecosystem extensions, natural language processing

### Technology Evolution

**Architecture Patterns**
- Event-driven architecture with event sourcing
- Microservices decomposition for enhanced scalability
- CQRS (Command Query Responsibility Segregation) for read/write optimization
- Saga pattern for distributed transaction management

**Infrastructure Modernization**
- Kubernetes deployment options alongside Lambda
- Service mesh integration (Istio/Linkerd) for advanced networking
- GitOps deployment patterns with ArgoCD/Flux
- Infrastructure as Code with Pulumi/CDK support

**Data and Analytics**
- Data lake integration for advanced analytics
- Real-time stream processing with Apache Kafka
- Machine learning pipelines with MLOps practices
- Time-series databases for metrics and monitoring

---

**Implementation Focus**: Core service capabilities with clear progression to enterprise features  
**Success Criteria**: Significant reduction in provisioning time while maintaining platform team autonomy  
**Strategic Value**: Transform developer experience from lengthy delays to efficient automation