# Platform Automation Orchestrator Development Roadmap

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

*Last Updated: August 17, 2025*

## Table of Contents

- [Q3 2025: Foundation Epic](#q3-2025-foundation-epic)
- [Q4 2025: Production Epic](#q4-2025-production-epic)

## Q3 2025: Foundation Epic 🚧 CURRENT (Aug-Oct)

**Epic Goal**: Establish working foundation with manual JIRA fulfillment

**Value Delivered**: Platform teams define services in the catalog, users request services, and fulfillment occurs through JIRA actions

**Success Metrics**:
- Schema specification complete with 100% validation coverage
- Core REST API deployed with <200ms response times and JIRA action type
- Test catalog items working: EKS app, PostgreSQL database, parameter store (all JIRA fulfillment)
- Developers can submit requests and receive JIRA tickets with proper variable substitution

### Catalog Focus
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

### Service Focus
- Core REST API with catalog ingestion, request submission, status tracking
- JIRA action execution framework with variable substitution
- Variable substitution system supporting 6+ scopes (fields, metadata, request, system, environment, outputs)
- PostgreSQL database schema for requests and audit logging

**Required API Endpoints (17 total)**:

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

*System Integration (1 endpoint)*:
- `/api/v1/metrics` - Prometheus metrics

**Service Implementation Tasks**:
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

### DevCtl Focus
**Lock-Step Development**: DevCtl must deliver CLI support for ALL Q3 Service and Catalog features simultaneously

- CLI commands for all 20 Service API endpoints (catalog browsing, request operations, health checks, platform team tools)
- Dynamic form generation and request submission with real-time validation
- Request tracking with status monitoring and log streaming capabilities
- AWS IAM authentication integration with SigV4 signing
- Platform team validation tools (catalog-item validation, form preview, variable testing)
- Integration testing capabilities for Service API verification

**Epic Success Criteria**: Developers can request EKS app + PostgreSQL + parameter store through CLI and receive JIRA tickets with proper variable substitution. All Service API endpoints are accessible and testable via DevCtl commands.

---

## Q4 2025: Production Epic 📋 PLANNED (Nov-Jan)

**Epic Goal**: Add automated fulfillment to proven manual workflows

**Value Delivered**: Developers can request services and receive automated provisioning (Terraform, REST API) while platform teams maintain manual fallback

**Success Metrics**:
- Production AWS deployment with monitoring, alerting, and high availability
- Test catalog items enhanced with automated actions (Terraform, REST API)
- Fulfillment mode switching operational (manual ↔ automated)
- Automated provisioning working for EKS app, PostgreSQL, parameter store
- 5+ platform teams can define services with automated and manual fulfillment options

### Catalog Focus
- Enhanced schema supporting Terraform action types with repository mapping
- 10+ production-ready catalog items for compute, database, storage, networking
- Platform team migration tools and training materials
- Complex variable templating patterns with secrets and outputs scope

### Service Focus
- Terraform action type with infrastructure provisioning capabilities
- Production AWS deployment with RDS, Redis, monitoring, alerting
- Fulfillment mode switching (seamless manual ↔ automated switching)
- Performance optimization supporting 100+ concurrent requests

### DevCtl Focus
**Lock-Step Development**: DevCtl must deliver CLI support for ALL Q4 Service enhancements simultaneously

- Advanced CLI features for Terraform action tracking, logs, and automated fulfillment monitoring
- Batch operations and CI/CD integration capabilities for automated provisioning workflows
- Enhanced platform team tools supporting automated action testing and troubleshooting
- Production-ready CLI with comprehensive error handling and recovery operations
- Advanced authentication and authorization features matching Service capabilities
- Performance monitoring and metrics collection CLI commands

**Epic Success Criteria**: Production platform with automated provisioning significantly reducing service delivery time and 5+ platform teams onboarded. All automated fulfillment capabilities are manageable and monitorable via DevCtl.