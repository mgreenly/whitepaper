# Platform Automation Orchestrator Service

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Note on Implementation

This document serves as architectural guidance and conceptual inspiration for engineering teams developing orchestration services. It is not intended as a precise implementation specification or detailed blueprint. Engineering teams should interpret these concepts, adapt the proposed patterns to their specific technical environment and organizational requirements, and develop their own detailed work plans accordingly. While implementation approaches may vary, the core architectural concepts, data structures, and operational patterns described herein should be represented in the final system design to ensure consistency with the overall platform vision.

## Table of Contents

- [Strategic Context](#strategic-context)
- [Architectural Overview](#architectural-overview)
- [Document-Driven Convergence Model](#document-driven-convergence-model)
- [API Design Specification](#api-design-specification)
- [Request Processing Architecture](#request-processing-architecture)
- [Queue Architecture](#queue-architecture)
- [Variable Substitution Engine](#variable-substitution-engine)
- [Integration Patterns](#integration-patterns)
- [Data Architecture](#data-architecture)
- [Operational Patterns](#operational-patterns)
- [Success Metrics & KPIs](#success-metrics--kpis)
- [Evolution Strategy](#evolution-strategy)

## Strategic Context

The Platform Automation Orchestrator (PAO) serves as the central orchestration capability within the Integration and Delivery Plane of the Internal Developer Platform. PAO transforms multi-week provisioning delays into same-day resource delivery by providing a document-driven convergence point where platform teams define their service offerings through YAML documents.

This approach enables self-service provisioning while maintaining team autonomy, reducing provisioning times from weeks to hours in Phase 1 (JIRA-based) and eventually to minutes in subsequent phases (automation-enabled).

**Reference Documentation**:
- Strategic vision and context: [whitepaper.md](whitepaper.md)
- Catalog schema and specifications: [catalog.md](catalog.md)
- CLI tool documentation: [devctl.md](devctl.md)

## Architectural Overview

### Position in Reference Architecture

PAO operates within the **Integration and Delivery Plane**, serving as the orchestration hub that connects:

- **Developer Control Plane**: Where developers interact via portal or CLI
- **Resource Plane**: Where actual Platform Team Resource provisioning occurs
- **Security & Compliance Plane**: For policy enforcement and secrets management
- **Monitoring & Logging Plane**: For observability and audit trails

### Core Architectural Principles

1. **Document-Driven Design**: All resource definitions exist as versioned YAML documents
2. **Catalog-Centric**: The catalog repository is the single source of truth for available resources
3. **Stateless Processing**: Each request is self-contained with all necessary context
4. **Progressive Enhancement**: Manual processes evolve to automation without disruption
5. **Team Autonomy**: Platform teams maintain control over their resource definitions
6. **Fail-Safe Operations**: Failures require human intervention - no automatic recovery that could cause damage

### Service Boundaries

**PAO Responsibilities**:
- Request orchestration and state management
- Variable substitution and template processing
- Catalog synchronization from GitHub repository
- API gateway for developer interactions
- Fulfillment action execution:
  - JIRA ticket creation
  - REST API calls
  - GitHub commit operations
  - GitHub workflow dispatch

**Platform Team Responsibilities**:
- Actual resource provisioning (databases, compute, storage)
- Resource lifecycle management and state
- JIRA ticket template content and required fields
- Resource-specific validation rules and constraints

## Document-Driven Convergence Model

### The Convergence Point

The catalog repository (`platform-automation-repository`) serves as the convergence point where:

1. **Platform Teams Contribute**: Each team defines their resources as YAML documents
2. **Schema Enforcement**: All documents conform to CatalogItem or CatalogBundle schemas
3. **Resource Discovery**: PAO consumes these documents to build the resource catalog
4. **Dynamic Forms**: Input definitions generate forms in the developer portal
5. **Fulfillment Templates**: Action definitions determine how requests are processed

### Catalog Document Types

**CatalogItem**: Individual resource offerings
- Metadata: Identity, ownership, and classification
- Input Form: Dynamic field definitions with validation
- Fulfillment Actions: JIRA tickets (Phase 1) or automated APIs (Phase 2+)

**CatalogBundle**: Composite resource packages
- Components: References to multiple CatalogItems
- Dependencies: Execution order and relationships
- Orchestration: Sequential processing with JIRA linking

### Progressive Enhancement Model

```
Phase 1: Foundation - Manual JIRA
├── All resources use JIRA tickets
├── Platform teams fulfill manually
└── Hours instead of weeks

Phase 2: Mixed Mode Automation
├── Some resources automated
├── Others remain JIRA-based
└── Teams migrate at own pace

Phase 3: Full Automation
├── Most resources automated
├── JIRA for exceptions
└── Minutes instead of hours
```

### Ownership Model

- **Platform Teams**: Own catalog item definitions within their designated categories, define fulfillment templates, and maintain resource-specific documentation
- **PAO Team**: Owns the orchestration service, maintains catalog repository structure and schemas, develops and maintains the CLI tool (devctl), and ensures overall system health

## API Design Specification

### RESTful API Architecture

The service exposes a RESTful API organized into logical resource collections:

**Catalog Resources** (`/api/v1/catalog`)
- `GET /catalog` - List available resources with filtering
- `GET /catalog/{item-id}` - Get resource details and form schema
- `GET /catalog/{item-id}/form` - Get rendered form definition
- `POST /catalog/refresh` - Force catalog synchronization

**Request Resources** (`/api/v1/requests`)
- `POST /requests` - Submit new resource request
- `GET /requests` - List user's requests with filtering
- `GET /requests/{request-id}` - Get request details including queue position
- `GET /requests/{request-id}/status` - Get current status and processing state
- `GET /requests/{request-id}/logs` - Get execution logs
- `POST /requests/{request-id}/retry` - Retry failed request (re-enqueue)
- `POST /requests/{request-id}/abort` - Abort failed request
- `POST /requests/{request-id}/escalate` - Escalate to support

**Queue Management** (`/api/v1/queue`)
- `GET /queue/stats` - Queue depth, message age, processing rate (main and DLQ)
- `GET /queue/messages` - List messages in main queue
- `GET /queue/dlq/messages` - List messages in dead letter queue
- `GET /queue/messages/{message-group-id}` - Get all messages for a request
- `POST /queue/dlq/{message-id}/redrive` - Move message from DLQ back to main queue

**Health Resources** (`/api/v1/health`)
- `GET /health` - Service health status
- `GET /health/ready` - Readiness probe
- `GET /version` - Version information

**Platform Tools** (`/api/v1/tools`)
- `POST /tools/validate` - Validate catalog item
- `POST /tools/preview` - Preview form rendering
- `POST /tools/test-variables` - Test variable substitution

**Integration Endpoints**
- `POST /webhooks/github` - GitHub catalog updates

### API Design Patterns

**Authentication**
- Identity federation through organizational IAM
- Request signing for API authentication

**Request/Response Patterns**
- Consistent JSON structure with envelope
- Standardized error response format
- Cursor-based pagination for lists
- Field filtering and sparse fieldsets

**Idempotency & Safety**
- GET requests are safe and cacheable
- POST requests include idempotency keys
- Retry-safe operation design
- Correlation IDs for request tracing

### Error Handling Architecture

**Error Classification**:
- **4xx Client Errors**: Invalid requests, authentication failures, validation errors
- **5xx Server Errors**: Internal failures, integration errors, resource exhaustion

**Error Response Structure**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [{"field": "name", "issue": "pattern mismatch"}],
    "correlation_id": "uuid"
  }
}
```

## Request Processing Architecture

### Asynchronous Processing Architecture

The service employs an asynchronous queue-based architecture to ensure reliable request processing and enable horizontal scaling. This design replaces multi-week manual delays with same-day delivery through automated orchestration.

**Request Processing Pipeline**:

1. **Reception & Validation**
   - Receive request with catalog item ID and form data
   - Generate correlation ID for distributed tracing
   - Validate against catalog schema and constraints
   - Verify required fields and patterns

2. **Queueing & Persistence**
   - Persist request to database with initial state
   - Enqueue message to SQS FIFO queue
   - Return tracking ID to client immediately
   - Enable status polling for progress

3. **Template Processing**
   - Parse templates for variable references
   - Resolve variables from four namespaces
   - Apply necessary transformations
   - Generate final payload content

4. **Action Execution**
   - Route to appropriate action handler
   - Execute action (JIRA, REST API, etc.)
   - Capture results and external references
   - Handle failures with appropriate context

5. **State Management**
   - Update request status in database
   - Record action outputs for subsequent use
   - Create immutable audit log entries
   - Trigger next action if bundle component

**Key Characteristics**:
- Asynchronous message-based processing
- Immediate acknowledgment with tracking ID
- Horizontal scaling through worker pools
- Real-time status updates via API polling

### Request State Machine

```
[submitted] ──→ [queued] ──→ [in_progress] ──→ [completed]
                    │              │
                    │              ↓
                    │          [failed] ──→ [aborted]
                    │              ├──→ [retrying]
                    │              └──→ [escalated]
                    │
                    └──→ [stuck]
```

**State Definitions**:
- `submitted`: Request received and validated
- `queued`: Message in queue awaiting processing
- `in_progress`: Worker actively processing action
- `completed`: All actions successful
- `failed`: Action execution failed, awaiting human decision
- `retrying`: Human initiated retry, message re-queued
- `aborted`: User chose to abandon
- `escalated`: Transferred to manual support
- `stuck`: Message not progressing (visibility timeout exceeded multiple times)

### Bundle Orchestration

For CatalogBundles, the orchestrator:

1. **Component Resolution**: Load referenced CatalogItems
2. **Dependency Ordering**: Sort components by dependencies
3. **Sequential Execution**: Process components in order
4. **JIRA Linking**: Create "blocks/blocked by" relationships
5. **Output Accumulation**: Build `.output` namespace progressively
6. **Failure Handling**: Stop on first failure

## Queue Architecture

### SQS FIFO Queue Design

The service uses AWS SQS FIFO queues to ensure ordered processing of actions within each request while allowing parallel processing across different requests.

**Queue Structure**:
- **Action Queue**: Primary FIFO queue for all action processing
- **Dead Letter Queue**: FIFO queue for messages that fail after 3 receive attempts
- **Message Group ID**: Request UUID ensures all actions for a request process in order

**How FIFO Message Groups Work**:

SQS FIFO queues use Message Group IDs to ensure ordering within a group while allowing parallel processing across groups:

- **Message Group ID = Request UUID**: Each request gets its own message group
- **Ordering Guarantee**: All messages with the same group ID process in exact FIFO order
- **Parallel Processing**: Different message groups (different requests) process simultaneously
- **Example**: Two bundles processing concurrently:
  - Bundle A (3 components): A1 → A2 → A3 (group ID: Bundle A request ID)
  - Bundle B (4 components): B1 → B2 → B3 → B4 (group ID: Bundle B request ID)
  - Parallel processing enabled by different group IDs

### Message Flow

**Request Submission**:
1. API validates request and generates request ID
2. Persists request to database with "submitted" status
3. Enqueues message to SQS FIFO with request ID as message group ID
4. Returns request ID to client immediately

**Action Processing**:
1. Worker dequeues message from queue
2. Executes the action (JIRA ticket creation, API call, etc.)
3. Updates request status in database
4. If bundle with multiple actions, enqueues next action with same message group ID
5. Process continues until all actions complete or one fails

### Worker Design

**Worker Architecture**:
- Unified worker implementation for all action types
- Dynamic routing based on action configuration
- Horizontal scaling based on queue metrics
- Stateless design with database-backed state

### Error Handling

**Failure Handling Pattern**:
- If action fails, mark request as "failed" in database
- No automatic retries at application level - matches existing "fail-safe" principle
- Messages that fail to process after 3 receives move to DLQ automatically (SQS feature)
- Failed requests handled via API endpoints:
  - `POST /requests/{request-id}/retry` - Re-enqueue from DLQ or create new message
  - `POST /requests/{request-id}/abort` - Mark as aborted, remove from DLQ
  - `POST /requests/{request-id}/escalate` - Escalate to support team

**Dead Letter Queue (DLQ)**:
- Captures messages that fail after maximum retry attempts
- Prevents failed messages from blocking queue processing
- Preserves message content for debugging and analysis
- Requires manual intervention for resolution

**Queue Operations (devctl)**:
- Display queue metrics and statistics
- List requests by processing state
- Examine dead letter queue contents
- Redrive DLQ messages to main queue
- Show queue position for requests
- Execute batch operations on failures

## Variable Substitution Engine

### Four-Namespace Variable System

The orchestrator implements a hierarchical namespace system for template variable resolution:

**1. Current Namespace (`.current.*`)**
- Contains user input from request form
- Structure: `{{.current.name}}` (required field)
- Group fields: `{{.current.groupId.fieldId}}`
- Immutable during request processing
- Shared across all bundle components

**2. Output Namespace (`.output.*`)**
- Accumulates computed values from actions
- Flat structure: `{{.output.userSelectedKey}}`
- Built progressively during execution
- Each action can add new keys
- Available to subsequent actions

**3. Metadata Namespace (`.metadata.*`)**
- Static catalog item metadata
- Structure: `{{.metadata.catalogItemId.field}}`
- Includes standard fields (id, name, version)
- Includes custom metadata fields
- Read-only during execution

**4. System Namespace (`.system.*`)**
- Platform-provided context
- Request context: `{{.system.requestId}}`
- User context: `{{.system.user.email}}`
- Environment: `{{.system.platform.region}}`
- Generated values: `{{.system.timestamp}}`

### Template Processing Architecture

**Processing Phases**:

1. **Parse Phase**
   - Identify variable references `{{.namespace.path}}`
   - Extract namespace and path components
   - Build dependency graph

2. **Validation Phase**
   - Verify namespace exists
   - Check path accessibility
   - Validate circular dependencies
   - Type compatibility checks

3. **Resolution Phase**
   - Fetch values from namespaces
   - Apply type conversions
   - Handle missing values (empty string)
   - Process nested paths

4. **Transformation Phase**
   - Apply transformation functions
   - Format for target context (JSON, YAML)
   - Escape special characters
   - Handle array/object serialization

### Variable Scoping Rules

**Access Control**:
- Templates access only predefined namespaces
- No dynamic namespace creation permitted
- Request isolation enforced (no cross-request access)
- Bundle components share `.current` namespace values

**Sequential Processing**:
- `.output` namespace accumulates progressively
- Subsequent actions access all prior outputs
- Failed actions leave no output values
- Retry operations reset output namespace

## Integration Patterns

### Catalog Synchronization

The service maintains an up-to-date view of the catalog repository through event-driven synchronization:

**Synchronization Flow**:
1. GitHub webhook triggered on repository changes
2. Webhook signature validation for security
3. Filter for relevant changes (*.yaml in catalog/ and bundles/)
4. Schema validation of modified documents
5. Update in-memory cache for performance
6. Persist to database for durability

**Loading Strategies**:
- **Startup**: Full catalog load from repository
- **Runtime**: Event-driven updates via webhooks
- **Recovery**: Manual refresh endpoint available
- **Caching**: In-memory with configurable TTL
- **Persistence**: Database backup for resilience

**Team Mapping**:
- Parse CODEOWNERS file for team assignments
- Map teams to catalog categories
- Maintain ownership metadata for reference

### JIRA Integration

**Multi-Instance Configuration**:
- Support for multiple JIRA instances
- Project-based routing from templates
- Per-instance authentication and connection pooling
- Configurable timeout and retry policies

**Ticket Creation Flow**:
1. Process template with resolved variables
2. Construct JIRA payload with required fields
3. Include custom fields from catalog definition
4. Submit via JIRA REST API
5. Store ticket reference (key and URL)
6. Map JIRA response to request state

**Status Management**:
- On-demand status queries (no polling)
- Direct JIRA API calls for current state
- State mapping between JIRA and PAO
- Consistent status representation to clients

### Additional Integration Patterns

**REST API Actions**:
- Configurable endpoints and HTTP methods
- Template-driven headers and request bodies
- Response capture for `.output` namespace
- Circuit breaker pattern for resilience

**Terraform Integration**:
- Template-based plan generation
- State management coordination
- Output capture for dependency chains
- Rollback and recovery procedures

**GitHub Workflow Actions**:
- Workflow dispatch with input parameters
- Status tracking and monitoring
- Output artifact collection
- Error handling and notifications

## Data Architecture

### Persistence Strategy

The service uses a relational database with JSONB for flexibility:

**Core Database Tables**:

1. **Requests**
   - Request ID (UUID, primary key)
   - Catalog item reference
   - User identity and team membership
   - Current state and status
   - Form data (JSONB)
   - Correlation ID for tracing
   - Timestamps and audit metadata

2. **Request Actions**
   - Parent request reference
   - Action sequence index
   - Action type and configuration
   - Execution status and outputs
   - External references (e.g., JIRA keys)
   - Error context if failed

3. **Catalog Cache**
   - Catalog item definitions
   - Version and Git commit SHA
   - Category and team ownership
   - Complete definition (JSONB)
   - Synchronization timestamp

4. **Audit Logs**
   - Correlation ID for request linking
   - Event type and payload
   - User and system metadata
   - Immutable event record

### JSONB Usage Patterns

**Advantages**:
- Schema flexibility for evolving forms
- Native JSON operations in queries
- Indexing on JSONB paths
- Efficient storage of variable data

**Use Cases**:
- Request form data storage
- Action configurations
- Catalog definitions
- Audit event data

### Indexing Strategy

**Performance Indexes**:
- User email for request queries
- Status for filtering
- Correlation ID for tracing
- Created timestamp for sorting
- JIRA ticket key for lookups

**JSONB Indexes**:
- GIN index on user teams array
- Path indexes for common queries
- Expression indexes for computed values

### Data Retention

**Retention Policies**:
- Active requests: Indefinite
- Completed requests: 90 days
- Failed requests: 180 days
- Audit logs: Configurable retention period
- Catalog versions: Last 10 versions

## Operational Patterns

### Deployment Architecture

**Container-Based Deployment**:
- Stateless service containers
- Horizontal scaling capability
- Health check endpoints
- Graceful shutdown handling
- Resource limits defined

**High Availability**:
- Multiple service instances
- Load balancer distribution
- Database connection pooling
- Circuit breakers for integrations
- Fallback to manual processes

### Observability Architecture

**Logging Strategy**:
- Structured JSON logging
- Correlation ID threading
- Request/response logging
- Error context capture
- Performance metrics

**Monitoring Metrics**:
- RED metrics (Rate, Errors, Duration)
- Business metrics (requests per day)
- Integration health status
- Database performance indicators
- Cache hit/miss ratios
- Queue depth and message age
- Worker processing status
- Failed request statistics

**Alert Conditions**:
- Service availability below SLO
- Error rate threshold breaches
- Response time degradation
- Integration connection failures
- Database connectivity issues
- Queue backlog thresholds
- Worker processing stalls

### Security Patterns

**Authentication**:
- Federated identity management
- API authentication patterns
- Audit trail for all actions

**Secret Management**:
- External secret storage
- Rotation capabilities
- Encryption at rest
- Secure transmission

**Data Protection**:
- Sensitive data classification
- PII handling rules
- Encryption standards
- Retention policies

### Operational Procedures

**Incident Response**:
- Clear escalation paths
- Runbook documentation
- Rollback procedures
- Communication protocols

**Maintenance Windows**:
- Zero-downtime deployments
- Database migration patterns
- Cache warming strategies
- Graceful degradation

**Capacity Planning**:
- Usage trend analysis
- Scaling triggers defined
- Resource forecasting
- Performance testing

## Success Metrics & KPIs

### Business Metrics

**Primary KPIs**:
- **Provisioning Time**: Weeks → Hours (Phase 1), Hours → Minutes (Phase 2+)
- **Developer Satisfaction**: NPS score > 50
- **Platform Adoption**: Progressive team onboarding
- **Service Coverage**: Growing catalog of resources

**Operational Metrics**:
- Request volume growth rate
- Average time to fulfillment
- Automation percentage
- Error rate by resource type
- Retry success rate

### Technical Metrics

**Performance SLIs**:
- API response time < 500ms (p95)
- Request submission < 3 seconds
- Catalog refresh < 30 seconds
- JIRA ticket creation < 2 seconds

**Reliability SLOs**:
- Service availability: 99.5%
- Request success rate: 95%
- Data durability: 99.999%
- Catalog accuracy: 100%

### Volume Projections

**Phase 1 (JIRA Only)**:
- 10-50 requests/day
- 5-10 concurrent users
- 20-30 catalog items
- Initial platform teams

**Phase 2 (Mixed Mode)**:
- 100-200 requests/day
- 20-30 concurrent users
- 50-70 catalog items
- Expanded platform teams

**Phase 3 (Scaled Adoption)**:
- 500-1000 requests/day
- 50-100 concurrent users
- 100+ catalog items
- All platform teams

## Evolution Strategy

### Phase 1: Foundation

**Objectives**:
- Eliminate multi-week provisioning delays
- Validate document-driven architecture
- Establish initial platform adoption
- Build organizational confidence

**Core Deliverables**:
- Orchestration service with queue architecture
- JIRA-based fulfillment automation
- Initial catalog repository with schemas
- API and developer portal integration

### Phase 2: Progressive Automation

**Prerequisites**: Stable Phase 1 operations

**Objectives**:
- Introduce automated provisioning alongside JIRA
- Support mixed-mode operations
- Expand catalog coverage
- Enhance developer experience

**New Capabilities**:
- REST API action execution
- Infrastructure-as-code integration
- Parallel processing for independent actions
- Advanced error recovery patterns

### Phase 3: Platform Maturity

**Prerequisites**: Phase 2 capabilities operational

**Advanced Capabilities**:
- Conditional workflow execution
- Multi-cloud resource orchestration
- Sophisticated error recovery
- Policy-based automation

**Intelligence Features**:
- Usage-based recommendations
- Anomaly detection and alerting
- Predictive capacity planning
- Cost optimization insights

**Enterprise Enhancements**:
- Team-based access control
- Compliance framework integration
- Multi-tenancy architecture
- Advanced audit capabilities

### Long-Term Vision

**Platform Excellence**:
- Complete self-service capabilities
- Zero-touch resource provisioning
- Intelligent automation and recommendations
- Exceptional developer experience

**Business Impact**:
- Accelerated innovation cycles
- Reduced operational overhead
- Improved team productivity
- Enhanced competitive positioning

### Implementation Strategy

**Phased Adoption**:
1. Start with well-understood resources
2. Progressively increase complexity
3. Transition to automation when mature
4. Preserve backward compatibility

**Organizational Enablement**:
1. Comprehensive training programs
2. Dedicated support channels
3. Success story documentation
4. Continuous feedback loops

**Risk Management**:
1. Manual process fallback options
2. Team-by-team rollout approach
3. Thorough testing protocols
4. Documented rollback procedures
