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
- [Variable Substitution Engine](#variable-substitution-engine)
- [Integration Patterns](#integration-patterns)
- [Data Architecture](#data-architecture)
- [Operational Patterns](#operational-patterns)
- [Success Metrics & KPIs](#success-metrics--kpis)
- [Evolution Strategy](#evolution-strategy)

## Strategic Context

### The Problem

Our development teams face multi-week delays when provisioning new applications due to a fragmented process requiring multiple JIRA tickets across various platform teams (compute, storage, networking, databases). This creates:

- **Innovation Bottleneck**: Teams wait weeks for basic resources
- **Cognitive Overhead**: Engineers navigate complex internal processes instead of building software
- **Coordination Friction**: Multiple handoffs between platform teams with no unified view
- **Lost Opportunity**: Delayed time-to-market and reduced competitive advantage

### The Solution Architecture

The Platform Automation Orchestrator (PAO) serves as the central capability within the Integration and Delivery Plane of our Reference Architecture. It provides:

- **Document-Driven Convergence**: Platform teams define services through YAML documents in a central catalog
- **Self-Service Portal**: Developers request services through a unified interface
- **Progressive Enhancement**: Teams start with manual JIRA fulfillment and evolve to automation at their own pace
- **Non-Disruptive Integration**: Works within existing organizational structure without requiring reorganization

### Value Proposition

**Immediate Impact**: Reduce provisioning from weeks to hours for JIRA-based services  
**Future State**: Reduce provisioning to minutes for fully automated services  
**Organizational Benefit**: Platform teams maintain ownership while developers gain self-service

For full strategic context see [whitepaper.md](whitepaper.md). For catalog specifications see [catalog.md](catalog.md).

## Architectural Overview

### Position in Reference Architecture

PAO operates within the **Integration and Delivery Plane**, serving as the orchestration hub that connects:

- **Developer Control Plane**: Where developers interact via portal or CLI
- **Resource Plane**: Where actual infrastructure provisioning occurs
- **Security & Compliance Plane**: For policy enforcement and secrets management
- **Monitoring & Logging Plane**: For observability and audit trails

### Core Architectural Principles

1. **Document-Driven Design**: All service definitions exist as versioned YAML documents
2. **Catalog-Centric**: The catalog repository is the single source of truth for available services
3. **Stateless Processing**: Each request is self-contained with all necessary context
4. **Progressive Enhancement**: Manual processes evolve to automation without disruption
5. **Team Autonomy**: Platform teams maintain control over their service definitions
6. **Fail-Safe Operations**: Failures require human intervention - no automatic recovery that could cause damage

### Service Boundaries

**What PAO Owns**:
- Request orchestration and state management
- Variable substitution and template processing
- JIRA ticket creation and tracking
- Catalog synchronization from GitHub
- API gateway for developer interactions

**What PAO Does Not Own**:
- Infrastructure provisioning (delegates to platform teams)
- Service implementation details (owned by platform teams)
- Approval workflows (handled in JIRA)
- Resource lifecycle management (owned by platform teams)
- Cost management and billing (separate systems)

## Document-Driven Convergence Model

### The Convergence Point

The catalog repository (`platform-automation-repository`) serves as the convergence point where:

1. **Platform Teams Contribute**: Each team defines their services as YAML documents
2. **Schema Enforcement**: All documents conform to CatalogItem or CatalogBundle schemas
3. **Service Discovery**: PAO consumes these documents to build the service catalog
4. **Dynamic Forms**: Input definitions generate forms in the developer portal
5. **Fulfillment Templates**: Action definitions determine how requests are processed

### Catalog Document Types

**CatalogItem**: Individual service offerings
- Metadata: Identity, ownership, and classification
- Input Form: Dynamic field definitions with validation
- Fulfillment Actions: JIRA tickets (Q3) or automated APIs (future)

**CatalogBundle**: Composite service packages
- Components: References to multiple CatalogItems
- Dependencies: Execution order and relationships
- Orchestration: Sequential processing with JIRA linking

### Progressive Enhancement Model

```
Phase 1 (Q3): Manual JIRA
├── All services use JIRA tickets
├── Platform teams fulfill manually
└── Hours instead of weeks

Phase 2 (Q4): Mixed Mode  
├── Some services automated
├── Others remain JIRA-based
└── Teams migrate at own pace

Phase 3 (Future): Full Automation
├── Most services automated
├── JIRA for exceptions
└── Minutes instead of hours
```

### Ownership Model

- **Platform Teams**: Own service definitions in their catalog categories
- **Architecture Team**: Owns schema definitions and governance
- **DevX Team**: Owns bundles and cross-domain integration
- **PAO Service**: Owns orchestration but not implementation

## API Design Specification

### RESTful API Architecture

The service exposes a RESTful API organized into logical resource collections:

**Catalog Resources** (`/api/v1/catalog`)
- `GET /catalog` - List available services with filtering
- `GET /catalog/{item-id}` - Get service details and form schema
- `GET /catalog/{item-id}/form` - Get rendered form definition
- `POST /catalog/refresh` - Force catalog synchronization

**Request Resources** (`/api/v1/requests`)
- `POST /requests` - Submit new service request
- `GET /requests` - List user's requests with filtering
- `GET /requests/{request-id}` - Get request details
- `GET /requests/{request-id}/status` - Get current status
- `GET /requests/{request-id}/logs` - Get execution logs
- `POST /requests/{request-id}/retry` - Retry failed request
- `POST /requests/{request-id}/abort` - Abort failed request
- `POST /requests/{request-id}/escalate` - Escalate to support

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

**Authentication & Authorization**
- Identity federation through organizational IAM
- Request signing for API authentication
- Team-based access control via group membership
- Catalog items specify allowed teams

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

**Error Categories**:
- **4xx Client Errors**: Validation failures, authorization issues
- **5xx Server Errors**: Service failures, integration issues

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

### Q3 Foundation: Synchronous JIRA Processing

The initial implementation focuses on replacing multi-week delays with same-day service through centralized JIRA ticket creation.

**Processing Pipeline**:

1. **Request Reception**
   - API endpoint receives service request
   - Request includes catalog item ID and form data
   - Correlation ID generated for tracing

2. **Validation Stage**
   - Schema validation against catalog definition
   - Required field verification
   - Pattern matching for field constraints
   - Team authorization check

3. **Variable Resolution**
   - Parse template for variable references
   - Resolve variables from four namespaces
   - Apply transformation functions if specified
   - Generate final content strings

4. **JIRA Ticket Creation**
   - Connect to appropriate JIRA instance
   - Create ticket with resolved templates
   - Capture ticket key for reference
   - Handle creation failures gracefully

5. **State Persistence**
   - Store request with JSONB data
   - Record action execution details
   - Create audit log entries
   - Return response to client

**Synchronous Constraints**:
- Complete within HTTP timeout (30 seconds)
- No background processing in Q3
- Direct JIRA API calls without queuing
- Immediate user feedback

### Request State Machine

```
[submitted] ──→ [in_progress] ──→ [completed]
                      │
                      ↓
                  [failed] ──→ [aborted]
                      │
                      ↓
                  [escalated]
```

**State Definitions**:
- `submitted`: Request received and validated
- `in_progress`: Actions being executed
- `completed`: All actions successful
- `failed`: Action execution failed
- `aborted`: User chose to abandon
- `escalated`: Transferred to manual support

### Bundle Orchestration

For CatalogBundles, the orchestrator:

1. **Component Resolution**: Load referenced CatalogItems
2. **Dependency Ordering**: Sort components by dependencies
3. **Sequential Execution**: Process components in order
4. **JIRA Linking**: Create "blocks/blocked by" relationships
5. **Output Accumulation**: Build `.output` namespace progressively
6. **Failure Handling**: Stop on first failure

## Variable Substitution Engine

### Four-Namespace Variable System

The orchestrator maintains a hierarchical namespace aligned with catalog.md specifications:

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
- Templates can only access defined namespaces
- No dynamic namespace creation
- No cross-request variable access
- Bundle components share `.current` namespace

**Progressive Enhancement**:
- `.output` namespace builds sequentially
- Later actions see earlier outputs
- Failed actions don't populate outputs
- Retry clears previous outputs

## Integration Patterns

### GitHub Catalog Integration

The service maintains synchronization with the catalog repository through event-driven updates:

**Webhook Processing**:
1. GitHub sends webhook on repository changes
2. Service validates webhook signature
3. Filters for relevant file changes (*.yaml in catalog/bundles)
4. Validates documents against schema
5. Updates internal catalog cache
6. Persists to database for durability

**Catalog Loading Strategy**:
- Initial load on service startup
- Event-driven updates via webhooks
- Manual refresh endpoint for recovery
- In-memory cache with TTL
- Database persistence for durability

**CODEOWNERS Enforcement**:
- Service reads CODEOWNERS file
- Maps teams to catalog categories
- Enforces access control on updates
- Validates team membership for requests

### JIRA Integration Architecture

**Multi-Instance Support**:
- Configure multiple JIRA instances
- Route by project key in templates
- Instance-specific authentication
- Connection pooling per instance

**Ticket Creation Pattern**:
1. Resolve template variables
2. Build ticket payload (summary, description)
3. Add custom fields if specified
4. Create ticket via REST API
5. Capture ticket key and URL
6. Handle errors with context

**Status Synchronization**:
- No background polling or caching
- Real-time queries on status requests
- Map JIRA states to request states
- Return current state to caller

### Future Integration Patterns

**REST API Actions** (Q4+):
- Configurable endpoints and methods
- Header and body templating
- Response capture for `.output`
- Circuit breaker for resilience

**Terraform Integration** (Future):
- Plan generation from templates
- State management patterns
- Output capture for dependencies
- Rollback coordination

**GitHub Workflows** (Future):
- Workflow dispatch triggers
- Input parameter mapping
- Run status tracking
- Output artifact processing

## Data Architecture

### Persistence Strategy

The service uses a relational database with JSONB for flexibility:

**Core Entities**:

1. **Requests Table**
   - Request ID (UUID primary key)
   - Catalog item reference
   - User information and teams
   - Status and state machine
   - Request data (JSONB)
   - Correlation ID for tracing
   - Timestamps and audit fields

2. **Request Actions Table**
   - Links to parent request
   - Action index for ordering
   - Action type and configuration
   - Execution status and output
   - External references (JIRA keys)
   - Error details if failed

3. **Catalog Cache Table**
   - Catalog item definitions
   - Version and git SHA
   - Category and ownership
   - Full definition (JSONB)
   - Last synchronized timestamp

4. **Audit Logs Table**
   - Correlation ID linking
   - Event type and data
   - User and system context
   - Immutable audit trail

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
- Audit logs: 1 year minimum
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

**Monitoring Patterns**:
- RED metrics (Rate, Errors, Duration)
- Business metrics (requests/day)
- Integration health tracking
- Database performance monitoring
- Cache hit rates

**Alerting Rules**:
- Service availability
- Error rate thresholds
- Response time degradation
- Integration failures
- Database connection issues

### Security Patterns

**Authentication & Authorization**:
- Federated identity management
- API authentication patterns
- Team-based access control
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
- **Provisioning Time**: Weeks → Hours (Q3), Hours → Minutes (Q4+)
- **Developer Satisfaction**: NPS score > 50
- **Platform Adoption**: 80% of teams onboarded within 6 months
- **Service Coverage**: 50+ services in catalog within 1 year

**Operational Metrics**:
- Request volume growth rate
- Average time to fulfillment
- Automation percentage
- Error rate by service
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

**Q3 2025 (JIRA Only)**:
- 10-50 requests/day
- 5-10 concurrent users
- 20-30 catalog items
- 3-5 platform teams

**Q4 2025 (Mixed Mode)**:
- 100-200 requests/day
- 20-30 concurrent users
- 50-70 catalog items
- 10-15 platform teams

**2026 (Scaled Adoption)**:
- 500-1000 requests/day
- 50-100 concurrent users
- 100+ catalog items
- All platform teams

## Evolution Strategy

### Q3 2025: Foundation (JIRA-Only)

**Objectives**:
- Eliminate multi-week delays
- Prove document-driven model
- Establish platform adoption
- Build team confidence

**Deliverables**:
- Core orchestrator service
- JIRA ticket automation
- Basic catalog with 20+ services
- Developer portal integration

### Q4 2025: Automation Introduction

**Objectives**:
- Enable automated provisioning
- Mixed manual/automated mode
- Expand service coverage
- Improve developer experience

**Capabilities**:
- REST API action type
- Terraform integration
- Parallel action execution
- Enhanced error handling

### 2026: Platform Maturity

**Advanced Orchestration**:
- Conditional workflows
- Approval gates
- Multi-cloud support
- Cost governance

**Intelligence Layer**:
- Recommendation engine
- Anomaly detection
- Predictive analytics
- Capacity planning

**Enterprise Features**:
- ServiceNow integration
- Compliance frameworks
- Financial management
- Advanced RBAC

### Long-Term Vision

**Platform as a Product**:
- Self-service everything
- Zero-touch provisioning
- Intelligent automation
- Developer delight

**Organizational Impact**:
- Innovation acceleration
- Reduced cognitive load
- Platform team efficiency
- Competitive advantage

### Migration Strategy

**Incremental Adoption**:
1. Start with simple services
2. Add complexity gradually
3. Automate when ready
4. Maintain backward compatibility

**Team Enablement**:
1. Training and documentation
2. Dedicated support channel
3. Success stories sharing
4. Continuous improvement

**Risk Mitigation**:
1. Fallback to manual process
2. Gradual rollout by team
3. Extensive testing
4. Clear rollback procedures