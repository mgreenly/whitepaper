# Platform Automation Orchestrator Development Roadmap

*Last Updated: August 17, 2025*

## Table of Contents

- [Q3 2025: Foundation Epic](#q3-2025-foundation-epic)
- [Q4 2025: Production Epic](#q4-2025-production-epic)

## Q3 2025: Foundation Epic 🚧 CURRENT (Aug-Oct)

**Epic Goal**: Establish working foundation with manual JIRA fulfillment

**Value Delivered**: Platform teams can define services in catalog and developers can request them via manual JIRA tickets

**Success Metrics**:
- Schema specification complete with 100% validation coverage
- Core REST API deployed with <200ms response times and JIRA action type
- Developer portal rendering dynamic forms with working request submission
- Test catalog items working: EKS app, PostgreSQL database, parameter store (all JIRA fulfillment)
- Developers can submit requests and receive JIRA tickets with proper variable substitution

### Catalog Team Focus (2 people)
- Complete CatalogItem schema specification with validation rules
- GitHub repository with CI/CD, CODEOWNERS enforcement, automated validation
- Test catalog items: EKS app, PostgreSQL database, parameter store (all JIRA fulfillment)
- Governance model and platform team contribution workflows

**Catalog Repository Files to Create**:
- `.github/CODEOWNERS`
- `.github/workflows/validate-catalog.yml`
- `schema/catalog-item-v2.json`
- `schema/catalog-bundle-v2.json`
- `schema/common-types.json`
- `scripts/validate-catalog.sh`
- `scripts/validate-all.sh`
- `scripts/test-template.sh`
- `scripts/validate-changed.sh`
- `scripts/integration-test.sh`
- `tests/valid/example-catalog-item.yaml`
- `tests/invalid/missing-required-fields.yaml`
- `tests/invalid/invalid-naming-conventions.yaml`
- `templates/catalog-item-template.yaml`
- `templates/jira-action-template.yaml`
- `catalog/compute/eks-containerapp.yaml`
- `catalog/databases/postgresql-standard.yaml`
- `catalog/security/parameterstore-standard.yaml`
- `README.md`
- `.gitignore`

### Service Team Focus (3-4 people)
- Core REST API with catalog ingestion, request submission, status tracking
- JIRA action execution framework with variable substitution
- Variable substitution system supporting 6+ scopes (fields, metadata, request, system, environment, outputs)
- PostgreSQL database schema for requests and audit logging

**Required API Endpoints (20 total)**:

*Core User Journey (16 endpoints)*:
- `/api/v1/catalog` - Browse available services
- `/api/v1/catalog/items/{item_id}` - Service details
- `/api/v1/catalog/items/{item_id}/schema` - Dynamic form schema
- `/api/v1/validate/request` - Validate user input before submission
- `/api/v1/requests` - Submit/list service requests
- `/api/v1/requests/{request_id}` - Request details
- `/api/v1/requests/{request_id}/status` - Current status
- `/api/v1/requests/{request_id}/logs` - Execution logs
- `/api/v1/requests/{request_id}/retry` - Retry failed action
- `/api/v1/requests/{request_id}/abort` - Abort failed request
- `/api/v1/requests/{request_id}/escalate` - Escalate to manual support
- `/api/v1/requests/{request_id}/escalation` - Escalation details
- `/api/v1/catalog/refresh` - Force catalog refresh
- `/api/v1/health` - Service health status
- `/api/v1/health/ready` - Readiness probe
- `/api/v1/version` - Service version info

*Platform Team Tools (3 endpoints)*:
- `/api/v1/validate/catalog-item` - Validate service definition
- `/api/v1/preview/form` - Preview form generation
- `/api/v1/test/variables` - Test variable substitution

*System Integration (4 endpoints)*:
- `/api/v1/metrics` - Prometheus metrics
- `/api/v1/webhooks/github` - GitHub events
- `/api/v1/webhooks/jira` - JIRA status updates
- `/api/v1/webhooks/terraform` - Terraform notifications

**Service Team Implementation Tasks**:
1. **Core Infrastructure Setup**
   - PostgreSQL database schema (requests, request_actions tables)
   - Redis caching layer integration
   - AWS Lambda deployment framework
   - Environment configuration and secrets management

2. **Catalog Management Implementation** 
   - GitHub webhook processing for catalog updates
   - Catalog item parsing and validation
   - Schema-to-form generation logic
   - Catalog refresh and caching mechanisms

3. **Request Lifecycle Engine**
   - Request submission and validation pipeline
   - Status tracking and state management
   - Request queuing and processing architecture
   - Audit logging and correlation IDs

4. **JIRA Action Framework**
   - JIRA API integration with authentication
   - Variable substitution engine (6+ scopes)
   - Template processing and ticket creation
   - Status polling and webhook handling

5. **Error Handling and Recovery**
   - Circuit breaker implementation for external calls
   - Retry logic with exponential backoff
   - Failure context preservation
   - Manual escalation workflow

6. **API Endpoint Implementation**
   - All 20 REST endpoints with proper error handling
   - Request validation and response formatting
   - Pagination support for list endpoints
   - Health checks and metrics export

### DevCtl Team Focus (1-2 people)
- Developer portal with dynamic form generation from catalog schema
- Request tracking and JIRA ticket status display
- AWS IAM authentication integration
- Basic CLI for catalog browsing and request submission

**Epic Success Criteria**: Developers can request EKS app + PostgreSQL + parameter store through portal/CLI and receive JIRA tickets with proper variable substitution

---

## Q4 2025: Production Epic 📋 PLANNED (Nov-Jan)

**Epic Goal**: Add automated fulfillment to proven manual workflows

**Value Delivered**: Developers can request services and receive automated provisioning (Terraform, REST API, webhooks) while platform teams maintain manual fallback

**Success Metrics**:
- Production AWS deployment with monitoring, alerting, and high availability
- Test catalog items enhanced with automated actions (Terraform, REST API, webhooks)
- Fulfillment mode switching operational (manual ↔ automated)
- <1 hour automated provisioning time for EKS app, PostgreSQL, parameter store
- 5+ platform teams can define services with automated and manual fulfillment options

### Catalog Team Focus
- Enhanced schema supporting Terraform action types with repository mapping
- 10+ production-ready catalog items for compute, database, storage, networking
- Platform team migration tools and training materials
- Complex variable templating patterns with secrets and outputs scope

### Service Team Focus
- Terraform action type with infrastructure provisioning capabilities
- Production AWS deployment with RDS, Redis, monitoring, alerting
- Fulfillment mode switching (seamless manual ↔ automated switching)
- Performance optimization supporting 100+ concurrent requests

### DevCtl Team Focus
- Advanced portal features supporting Terraform action tracking and logs
- CLI automation capabilities for batch operations and CI/CD integration
- Self-service tools for platform teams (validation, testing, troubleshooting)
- Documentation integration with auto-generated API docs

**Epic Success Criteria**: Production platform reducing single service provisioning from weeks to <1 hour with 5+ platform teams onboarded