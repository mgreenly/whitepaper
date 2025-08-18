# Platform Automation Orchestrator Development Roadmap

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Table of Contents

- [Q3 2025: Foundation Epic](#q3-2025-foundation-epic)
  - [Catalog Work](#catalog-work)
  - [Service Work](#service-work)
  - [DevCtl Work](#devctl-work)
  - [Ordered Work Series](#ordered-work-series)
- [Q4 2025: Production Epic](#q4-2025-production-epic)
  - [Catalog Work](#catalog-work-1)
  - [Service Work](#service-work-1)
  - [DevCtl Work](#devctl-work-1)
  - [Ordered Work Series](#ordered-work-series-1)
- [Future Work Beyond Q4 2025](#future-work-beyond-q4-2025)
- [Proposals](#proposals)
  - [Database Schema Design Approach](#database-schema-design-approach)
  - [Error Handling Strategy Across Components](#error-handling-strategy-across-components)
  - [Variable Substitution Implementation Approach](#variable-substitution-implementation-approach)

*Last Updated: 2025-08-18 03:12:43 +0000 (UTC)*

## Q3 2025: Foundation Epic 🚧 CURRENT (Aug-Oct)

**Epic Goal**: Establish working foundation with manual JIRA fulfillment

**Value Delivered**: Platform teams define services in the catalog, users request services, and fulfillment occurs through JIRA actions

**Note**: Q3 uses synchronous request processing only. SQS background processing will be introduced in Q4 for production scalability.

**Success Metrics**:
- Schema specification complete with validation coverage
- Core REST API deployed with JIRA action type
- Test catalog items working: EKS app, PostgreSQL database, parameter store for secrets (all JIRA fulfillment)
- Developers can submit requests and Platform Teams receive properly formatted JIRA tickets

### Catalog Work
- Complete CatalogItem schema specification with validation rules
- GitHub repository with CI/CD, CODEOWNERS enforcement, automated validation
- Test catalog items: EKS app, PostgreSQL database, parameter store (all JIRA fulfillment)
- Document minimal platform team onboarding process
- Document catalog contribution workflows

**Catalog Repository Files to Create**:
- `.github/CODEOWNERS`
- `.github/workflows/validate-catalog.yml`
- `schema/catalog-item.json`
- `schema/catalog-bundle.json`
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
- `catalog/compute/eks-application.yaml`
- `catalog/databases/postgresql-standard.yaml`
- `catalog/security/parameterstore-standard.yaml`
- `README.md`
- `.gitignore`

### Service Work
- Core REST API with catalog ingestion, request submission, status tracking
- JIRA action execution framework with variable substitution
- Variable substitution system supporting 6+ scopes (fields, metadata, request, system, environment, outputs)
- PostgreSQL database schema for requests and audit logging

**Required API Endpoints (19 total)**:

*Core User Journey (12 endpoints)*:
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

*System Health (3 endpoints)*:
- `/api/v1/health` - Service health status
- `/api/v1/health/ready` - Readiness probe
- `/api/v1/version` - Service version info

*Platform Team Tools (3 endpoints)*:
- `/api/v1/validate/catalog-item` - Validate service definition
- `/api/v1/preview/form` - Preview form generation
- `/api/v1/test/variables` - Test variable substitution

*System Integration (1 endpoint)*:
- `/api/v1/webhooks/github` - GitHub webhook handler

**Service Implementation Tasks**:
1. **Core Infrastructure Setup**
   - PostgreSQL database schema (requests, request_actions tables)
   - In-memory caching layer integration
   - Environment configuration and secrets management

2. **Catalog Management Implementation** 
   - GitHub webhook processing for catalog updates
   - Catalog item parsing and validation
   - Schema-to-form generation logic
   - Catalog refresh and caching mechanisms

3. **Request Lifecycle Engine**
   - Request submission and validation pipeline
   - Status tracking and state management
   - Synchronous request processing (Q3: no background queuing)
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
   - All 19 REST endpoints with proper error handling
   - Request validation and response formatting
   - Pagination support for list endpoints
   - Health checks and service monitoring

### DevCtl Work
**Lock-Step Development**: DevCtl must deliver CLI support for ALL Q3 Service and Catalog features simultaneously

**Core Subcommands and Options Required**:

1. **Catalog Management (`devctl catalog`)**:
   - `catalog list` - Browse available services with filters (--category, --owner, --limit, --cursor)
   - `catalog get <item-id>` - Service details with options (--schema, --examples)
   - `catalog refresh` - Force catalog refresh with options (--wait, --timeout)

2. **Request Operations (`devctl request`)**:
   - `request submit <item-id>` - Submit requests with options (--config, --field, --dry-run, --wait, --follow-logs)
   - `request list` - List user requests with filters (--status, --catalog-item, --since, --limit)
   - `request get <request-id>` - Request details with options (--logs, --actions)
   - `request status <request-id>` - Status tracking with options (--watch, --interval)
   - `request logs <request-id>` - Log streaming with options (--follow, --tail, --action)

3. **System Health (`devctl health`)**:
   - `health check` - System health with options (--components, --detailed)
   - `health ready` - Readiness probe
   - `version` - Service version with options (--full)

4. **Platform Team Tools (`devctl validate`)**:
   - `validate catalog-item <file>` - Validate definitions with options (--strict, --schema-version)
   - `preview form <file>` - Form preview with options (--render, --interactive)
   - `test variables <file>` - Variable testing with options (--input, --show-all, --action)

**Global Options Required**:
- Authentication: --endpoint, --region, --profile
- Output: --output (json/yaml/table), --verbose, --debug, --no-color
- Performance: --timeout

**AWS IAM Integration**: SigV4 signing, automatic SSO session detection, profile management

**Epic Success Criteria**: Developers can request EKS app + PostgreSQL + parameter store through CLI and receive JIRA tickets with proper variable substitution. All Service API endpoints are accessible and testable via DevCtl commands.

### Ordered Work Series

**External Dependencies**:
- **Database Team Request**: PostgreSQL Aurora cluster (Multi-AZ, 50GB storage, db.t3.medium) - **2 week lead time required**
- **Self-Managed Setup**: AWS Parameter Store configuration for secret storage paths (JIRA tokens, GitHub tokens)
- **JIRA Configuration**: Project PLATFORM with issue types (Task, Story, Bug), custom fields for correlation ID
- **GitHub Repository**: platform-catalog repository with webhook endpoint configuration

**1. Foundation Setup**
- **Catalog Work**: Create GitHub repository structure with CODEOWNERS and basic validation. Implement JSON schemas for CatalogItem and CatalogBundle with validation rules. Set up GitHub repository with branch protection and webhook configuration.
- **Service Work**: Provision PostgreSQL Aurora cluster with IAM authentication and required schema. Set up in-memory caching infrastructure. Implement core REST API framework with health endpoints. Configure JIRA integration with API tokens, project setup, and required issue types.
- **DevCtl Work**: Initialize Go CLI project with AWS SigV4 authentication. Implement global options and basic command structure.
- **Documentation Work**: Document minimal platform team onboarding process and catalog contribution workflows.

**2. Core Functionality**
- **Catalog Work**: Complete 3 test catalog items (EKS app, PostgreSQL, parameter store) with JIRA action templates. Implement CI/CD pipeline with automated validation.
- **Service Work**: Build catalog ingestion from GitHub with validation. Implement request submission pipeline with JSONB storage and correlation ID tracking.
- **DevCtl Work**: Implement `catalog list/get/refresh` commands with pagination. Build request submission commands with config file support.

**3. Action Framework**
- **Catalog Work**: Enhance validation scripts with Ruby implementation. Create comprehensive test fixtures for valid/invalid examples.
- **Service Work**: Implement JIRA action framework with variable substitution (6+ scopes). Build status tracking and external reference management.
- **DevCtl Work**: Complete request management commands (list, get, status, logs). Implement platform team validation tools.
- **Testing Work**: Test end-to-end workflows and provide feedback for improvements.

**4. Integration & Polish**
- **Catalog Work**: Finalize templates and governance documentation. Complete integration testing with service endpoints.
- **Service Work**: Implement error handling, retry logic, and manual escalation workflows. Complete API endpoint coverage with proper error responses.
- **DevCtl Work**: Add advanced options (watch, follow-logs, filtering). Implement comprehensive error handling and user-friendly messages.
- **Testing Work**: Conduct user acceptance testing and gather feedback from early platform team adopters.

**5. Testing & Deployment**
- **Integration Work**: End-to-end testing of complete workflow. Deploy to staging environment and conduct load testing.
- **Service Work**: Performance optimization and monitoring setup.
- **DevCtl Work**: Release preparation and installation documentation. CLI distribution setup.
- **Catalog Work**: Final validation rule refinements and documentation updates.

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

### Catalog Work
- Enhanced schema supporting Terraform action types with repository mapping
- 10+ production-ready catalog items for compute, database, storage, networking
- Platform team migration tools and training materials
- Complex variable templating patterns with secrets and outputs scope

### Service Work
- Terraform action type with infrastructure provisioning capabilities
- Production EKS deployment with Aurora PostgreSQL, caching layer, monitoring, alerting
- Background worker pool implementation (Q4: transition from synchronous to asynchronous)
- Fulfillment mode switching (seamless manual ↔ automated switching)
- Performance optimization supporting 100+ concurrent requests

### DevCtl Work
**Lock-Step Development**: DevCtl must deliver CLI support for ALL Q4 Service enhancements simultaneously

**Enhanced Subcommands and Options for Q4**:

1. **Extended Request Operations**:
   - `request retry <request-id>` - Retry failed actions with options (--action, --force)
   - `request abort <request-id>` - Abort failed requests with confirmation
   - `request escalate <request-id>` - Escalate to manual support with context
   - Enhanced `request logs` with Terraform-specific log parsing and filtering

2. **Terraform Action Support**:
   - Enhanced `request status` with Terraform plan/apply progress tracking
   - `request terraform <request-id>` - Terraform-specific operations (--plan, --apply, --destroy)
   - Infrastructure state viewing and validation commands

3. **Batch Operations and Automation**:
   - `request batch submit` - Bulk request submission with options (--config-dir, --parallel)
   - `request export` - Export request data for CI/CD integration (--format, --filter)
   - Pipeline-friendly output formats and exit codes

4. **Enhanced Platform Team Tools**:
   - `validate terraform <file>` - Terraform action validation
   - `test automation <file>` - End-to-end automation testing
   - `debug request <request-id>` - Advanced troubleshooting and diagnostics

5. **Production Operations**:
   - Enhanced error handling with recovery suggestions
   - Performance monitoring commands with detailed diagnostics
   - Advanced authentication with role assumption and cross-account support
   - Comprehensive logging and audit trail capabilities

**Epic Success Criteria**: Production platform with automated provisioning significantly reducing service delivery time and 5+ platform teams onboarded. All automated fulfillment capabilities are manageable and monitorable via DevCtl.

### Ordered Work Series

**1. Terraform Integration Foundation**
- **Catalog Work**: Enhance schema to support Terraform action types with repository mapping. Create Terraform action templates and validation rules.
- **Service Work**: Implement background worker pool architecture (transition from synchronous to asynchronous). Implement Terraform action execution framework with state management. Build REST API action type with authentication and retry logic.
- **DevCtl Work**: Add retry, abort, and escalate commands. Implement Terraform-specific status tracking and log parsing.
- **Documentation Work**: Design fulfillment mode switching strategy and create migration documentation.

**2. Production Infrastructure**
- **Catalog Work**: Create 5+ production-ready catalog items with both manual and automated actions. Implement complex variable templating with secrets scope.
- **Service Work**: Deploy production EKS infrastructure with Aurora PostgreSQL, caching layer, monitoring, and alerting. Implement fulfillment mode switching logic.
- **DevCtl Work**: Build Terraform operation commands (plan, apply, destroy). Add batch operations and export functionality.
- **Testing Work**: Test automated provisioning workflows and provide platform team training materials.

**3. Performance & Automation**
- **Catalog Work**: Complete 10+ catalog items across all categories. Implement platform team migration tools and training workflows.
- **Service Work**: Performance optimization for 100+ concurrent requests. Implement advanced error handling and recovery suggestions.
- **DevCtl Work**: Add automation testing tools and advanced debugging commands. Implement performance monitoring and detailed diagnostics.
- **Integration Work**: Onboard first 3 platform teams and gather feedback for improvements.

**4. Production Hardening**
- **Service Work**: Production deployment hardening, security review, and compliance validation. Advanced authentication with role assumption.
- **DevCtl Work**: Production CLI release with comprehensive logging and audit capabilities. Cross-account authentication support.
- **Catalog Work**: Final catalog validation and governance process refinement.
- **Testing Work**: Complete user acceptance testing with 5+ platform teams.

**5. Launch & Optimization**
- **Integration Work**: Production launch preparation and monitoring setup. Performance tuning and final optimizations.
- **Service Work**: Production deployment and real-time monitoring setup.
- **DevCtl Work**: CLI distribution and user documentation finalization.
- **Catalog Work**: Platform team onboarding automation and success metric tracking.

---

## Future Work Beyond Q4 2025

Potential areas for future platform evolution include multi-cloud support, enterprise marketplace, AI-powered automation, and advanced compliance frameworks.

**Future Problems (Not Addressed in Q3/Q4)**:
- Change management process for schema updates
- User feedback collection mechanism

---

## Proposals

### Database Schema Design Approach

**Proposal**: Use a hybrid approach combining structured tables for core request tracking with JSONB columns for flexible action configuration and user input data. This provides both query performance for status tracking and flexibility for diverse catalog item requirements.

**Rationale**: 
- Structured columns (request_id, status, created_at) enable efficient indexing and querying
- JSONB columns (request_data, action_config, error_context) provide schema flexibility
- PostgreSQL JSONB performance and indexing capabilities support complex queries when needed

### Error Handling Strategy Across Components

**Proposal**: Implement a three-tier error handling strategy:
1. **Component-Level**: Each component (Catalog, Service, DevCtl) handles its domain-specific errors with appropriate recovery
2. **Integration-Level**: Standardized error codes and correlation IDs for cross-component error tracking
3. **User-Level**: Consistent error formatting and actionable error messages across all interfaces

**Rationale**: 
- Enables independent component development while maintaining integration coherence
- Correlation IDs provide end-to-end traceability for debugging
- Standardized error codes enable DevCtl to provide intelligent error handling and suggestions

### Variable Substitution Implementation Approach

**Proposal**: Use a template engine with explicit scoping and validation phases:
1. **Parse Phase**: Extract all variable references and validate syntax
2. **Scope Resolution**: Validate all variables can be resolved within available scopes
3. **Substitution Phase**: Apply template engine with validated context data
4. **Post-Processing**: Apply transformation functions (upper, lower, concat, etc.)

**Rationale**:
- Pre-validation prevents runtime template failures
- Explicit scoping prevents accidental data leakage between contexts
- Transformation functions provide necessary flexibility for different action types
- Clear separation of concerns enables easier testing and debugging