# Platform Automation Orchestrator Development Roadmap

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Table of Contents

- [Q3 2025: Foundation Epic](#q3-2025-foundation-epic)
  - [Success Metrics & Work Summary](#success-metrics--work-summary)
  - [Ordered Work Series](#ordered-work-series)
- [Q4 2025: Production Epic](#q4-2025-production-epic)
  - [Success Metrics & Work Summary](#success-metrics--work-summary-1)
  - [Ordered Work Series](#ordered-work-series-1)
- [Future Work Beyond Q4 2025](#future-work-beyond-q4-2025)
- [Proposals](#proposals)
  - [Database Schema Design Approach](#database-schema-design-approach)
  - [Error Handling Strategy Across Components](#error-handling-strategy-across-components)
  - [Variable Substitution Implementation Approach](#variable-substitution-implementation-approach)

*Last Updated: 2025-08-18 04:12:00 +0000 (UTC)*

## Q3 2025: Foundation Epic 🚧 CURRENT (Aug-Oct)

**Epic Goal**: Establish working foundation with manual JIRA fulfillment

**Value Delivered**: Platform teams define services in the catalog, users request services, and fulfillment occurs through JIRA actions

**Note**: Q3 uses synchronous request processing only. SQS background processing will be introduced in Q4 for production scalability.

**Success Metrics & Work Summary**:
- **Catalog**: GitHub repository with schemas, validation scripts, and 3 test YAML catalog items (EKS, PostgreSQL, Parameter Store) defining JIRA ticket templates
- **Service**: Core REST API with 19 endpoints, JIRA integration for ticket creation, PostgreSQL database, with all test catalog items working
- **DevCtl**: CLI with AWS SigV4 authentication covering all service endpoints, enabling developers to request services and receive JIRA tickets


### Ordered Work Series

**External Dependencies**:
- **Database Team Request**: PostgreSQL Aurora cluster for PAO service data storage (Multi-AZ, 50GB storage, db.t3.medium) - **2 week lead time required**
- **JIRA Configuration**: Project PLATFORM with issue types (Task, Story, Bug), custom fields for correlation ID
- **GitHub Repository**: platform-catalog repository with webhook endpoint configuration

**Internal Infrastructure Setup**:
- **AWS Parameter Store Terraform**: Create Parameter Store paths for secret storage (JIRA tokens, GitHub tokens)

- **Catalog Work**: Create GitHub repository structure with `.github/CODEOWNERS`, `.gitignore`, and `README.md`
- **Catalog Work**: Implement JSON schemas (`schema/catalog-item.json`, `schema/catalog-bundle.json`, `schema/common-types.json`)
- **Catalog Work**: Set up GitHub Actions workflow (`.github/workflows/validate-catalog.yml`) with branch protection
- **Service Work**: Set up PostgreSQL database schema (requests, request_actions tables)
- **Service Work**: Implement core REST API framework with Phase 1 health endpoints (/api/v1/health, /api/v1/health/ready, /api/v1/version)
- **Service Work**: Configure JIRA integration with API tokens, project setup, and required issue types
- **DevCtl Work**: Initialize Go CLI project with AWS SigV4 authentication
- **DevCtl Work**: Implement Phase 1 commands (devctl health check, devctl health ready, devctl version)
- **Documentation Work**: Add platform team onboarding process and catalog contribution workflow sections to existing repository files (no new documentation files)
- **Catalog Work**: Create 3 test catalog YAML files (`catalog/compute/eks-application.yaml`, `catalog/databases/postgresql-standard.yaml`, `catalog/security/parameterstore-standard.yaml`)
- **Catalog Work**: Create initial templates (`templates/catalog-item-template.yaml`, `templates/jira-action-template.yaml`)
- **Service Work**: Implement Phase 2 catalog APIs (/api/v1/catalog, /api/v1/catalog/items/{item_id}, /api/v1/catalog/items/{item_id}/schema, /api/v1/catalog/refresh) with GitHub integration and in-memory caching
- **Service Work**: Implement Phase 3 validation APIs (/api/v1/validate/catalog-item, /api/v1/validate/request, /api/v1/preview/form, /api/v1/test/variables) with variable substitution engine (6+ scopes)
- **Service Work**: Implement Phase 4 request submission APIs (/api/v1/requests POST/GET, /api/v1/requests/{request_id}) with JIRA ticket creation and audit logging
- **DevCtl Work**: Implement Phase 2 catalog commands (devctl catalog list/get/refresh) and Phase 3 validation commands (devctl validate catalog-item, devctl preview form, devctl test variables)
- **DevCtl Work**: Implement Phase 4 request commands (devctl request submit/list/get)
- **Catalog Work**: Implement validation scripts (`scripts/validate-catalog.sh`, `scripts/validate-all.sh`, `scripts/test-template.sh`, `scripts/validate-changed.sh`)
- **Catalog Work**: Create test fixtures (`tests/valid/example-catalog-item.yaml`, `tests/invalid/missing-required-fields.yaml`, `tests/invalid/invalid-naming-conventions.yaml`)
- **Service Work**: Implement Phase 5 request management APIs (/api/v1/requests/{request_id}/status, /api/v1/requests/{request_id}/logs, /api/v1/requests/{request_id}/retry, /api/v1/requests/{request_id}/abort) with JIRA status polling
- **DevCtl Work**: Implement Phase 5 commands (devctl request status/logs with --watch/--follow options, devctl request retry/abort)
- **Testing Work**: Test end-to-end workflows and provide feedback for improvements
- **Catalog Work**: Implement integration test script (`scripts/integration-test.sh`)
- **Catalog Work**: Finalize templates and add governance sections to existing files
- **Catalog Work**: Complete integration testing with service endpoints
- **Service Work**: Implement Phase 6 advanced APIs (/api/v1/requests/{request_id}/escalate, /api/v1/requests/{request_id}/escalation, /api/v1/webhooks/github) with manual escalation and GitHub webhook processing
- **Service Work**: Implement error handling, retry logic with exponential backoff, and circuit breaker patterns
- **DevCtl Work**: Implement Phase 6 commands (devctl request escalate) with advanced error handling and user-friendly messages
- **Testing Work**: Conduct user acceptance testing and gather feedback from early platform team adopters
- **Integration Work**: End-to-end testing of complete workflow with performance validation
- **Service Work**: Performance optimization and service observability implementation
- **DevCtl Work**: Binary compilation, distribution setup, and installation instructions as part of DevCtl Phase 6 completion
- **Catalog Work**: Final validation rule refinements and catalog item polish

---

## Q4 2025: Production Epic 📋 PLANNED (Nov-Jan)

**Epic Goal**: Add automated fulfillment to proven manual workflows

**Value Delivered**: Developers can request services and receive automated provisioning (Terraform, REST API) while platform teams maintain manual fallback

**Success Metrics & Work Summary**:
- **Catalog**: Enhanced schemas for Terraform actions, 10+ production catalog items with automated fulfillment, platform team migration tools
- **Service**: Background workers, Terraform/REST API execution, fulfillment mode switching (manual ↔ automated), production hardening for 100+ concurrent requests
- **DevCtl**: Retry/abort/escalate commands, Terraform operations, batch processing, enabling 5+ platform teams to use automated provisioning

### Ordered Work Series

- **Catalog Work**: Enhance schema to support Terraform action types with repository mapping
- **Catalog Work**: Create Terraform action templates and validation rules
- **Service Work**: Implement background worker pool architecture (transition from synchronous to asynchronous)
- **Service Work**: Implement Terraform action execution framework with state management
- **Service Work**: Build REST API action type with authentication and retry logic
- **DevCtl Work**: Add retry, abort, and escalate commands as specified in roadmap gaps
- **DevCtl Work**: Implement Terraform-specific status tracking and log parsing
- **Documentation Work**: Add fulfillment mode switching strategy to existing service documentation
- **Catalog Work**: Create 5+ production-ready catalog YAML files with both manual and automated actions
- **Catalog Work**: Implement complex variable templating with secrets scope
- **Service Work**: Configure production infrastructure with Aurora PostgreSQL and caching layer
- **Service Work**: Implement service observability and alerting
- **Service Work**: Implement fulfillment mode switching logic
- **DevCtl Work**: Build Terraform operation commands (plan, apply, destroy)
- **DevCtl Work**: Add batch operations and export functionality
- **Testing Work**: Test automated provisioning workflows and create platform team training materials
- **Catalog Work**: Complete 10+ catalog YAML files across all categories
- **Catalog Work**: Implement platform team migration tools and training workflows
- **Service Work**: Performance optimization for 100+ concurrent requests
- **Service Work**: Implement advanced error handling and recovery suggestions
- **DevCtl Work**: Add automation testing tools and advanced debugging commands
- **DevCtl Work**: Implement performance monitoring and detailed diagnostics
- **Integration Work**: Onboard first 3 platform teams and gather feedback for improvements
- **Service Work**: Production hardening, security review, and compliance validation
- **Service Work**: Advanced authentication with role assumption
- **DevCtl Work**: Production CLI release with comprehensive logging and audit capabilities
- **DevCtl Work**: Cross-account authentication support
- **Catalog Work**: Final catalog validation and governance process refinement
- **Testing Work**: Complete user acceptance testing with 5+ platform teams
- **Integration Work**: Production launch preparation and monitoring setup
- **Integration Work**: Performance tuning and final optimizations
- **Service Work**: Production readiness and real-time monitoring setup
- **DevCtl Work**: CLI distribution and finalize installation instructions
- **Catalog Work**: Platform team onboarding automation and success metric tracking

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