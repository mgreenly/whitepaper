# Platform Automation Orchestrator Service

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Note on Implementation

This document serves as architectural guidance and conceptual inspiration for engineering teams developing catalog repository systems. It is not intended as a precise implementation specification or detailed blueprint. Engineering teams should interpret these concepts, adapt the proposed patterns to their specific technical environment and organizational requirements, and develop their own detailed work plans accordingly. While implementation approaches may vary, the core architectural concepts, data structures, and operational patterns described herein should be represented in the final system design to ensure consistency with the overall platform vision.

## Table of Contents

- [Overview](#overview)
- [Core API Specification](#core-api-specification)
- [Q3 Synchronous Processing Architecture](#q3-synchronous-processing-architecture)
- [Architecture & Technology Stack](#architecture--technology-stack)
- [Implementation Requirements](#implementation-requirements)
- [Performance & Success Metrics](#performance--success-metrics)
- [Deployment Architecture](#deployment-architecture)
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

The Platform Automation Orchestrator provides a comprehensive REST API with 19 endpoints organized into functional categories:

**Catalog Management** (4 endpoints)
- Browse services, get details, form schemas, force refresh

**Request Lifecycle** (9 endpoints)  
- Submit, list, get details, status, logs, retry, abort, escalate requests

**System Health** (3 endpoints)
- Health status, readiness probe, version info

**Platform Team Tools** (3 endpoints)
- Validate catalog items, preview forms, test variables

**System Integration** (1 endpoint)
- GitHub webhook handler for catalog synchronization

### Key API Patterns

**Authentication**: AWS IAM with SigV4 request signing. Users associated with teams through IAM groups, with catalog items specifying allowed teams for access control.

**Pagination**: Cursor-based pagination (limit/cursor parameters) with stateless base64-encoded tokens.

**Error Handling**: Standardized error codes including VALIDATION_ERROR, UNAUTHORIZED, RATE_LIMIT_EXCEEDED, INTERNAL_ERROR, EXTERNAL_SERVICE_ERROR, REQUEST_NOT_FOUND, ACTION_FAILED, INVALID_STATE_TRANSITION.

## Q3 Synchronous Processing Architecture

The Q3 Foundation Epic establishes synchronous request processing for JIRA-based fulfillment, providing the foundation for Q4's automated provisioning.

**Core Principles**:
- **Synchronous Processing**: All requests processed within HTTP handlers (3-5 seconds)
- **JIRA-Only Actions**: Single action type for manual fulfillment via JIRA tickets
- **Direct Database Integration**: PostgreSQL connection pooling without background workers
- **Real-time Status**: Direct JIRA API queries for status updates (no caching)

**Request Processing Flow**:
1. **Request Reception**: HTTP handler receives POST to `/api/v1/requests`
2. **Validation Pipeline**: Multi-stage validation (schema, business rules, authorization)
3. **Database Transaction**: Store request with correlation ID in single transaction
4. **JIRA Action Execution**: Synchronous JIRA API call with variable substitution
5. **State Update**: Update request status and store JIRA ticket reference
6. **Response**: Return request ID and JIRA ticket details to client

**State Transitions**:
- `submitted` → `in_progress` → `completed`/`failed`
- `failed` → `aborted`/`escalated`

**Variable Substitution System**:
Hierarchical scope resolution supporting 6+ core scopes (fields, metadata, request, system, environment, outputs). Multi-phase processing: parse, validate, resolve, transform, output. Pre-execution validation prevents runtime template failures.

**JIRA Integration Pattern**:
Multi-instance support with flexible authentication (API token, OAuth2). Real-time status queries without caching. Template processing for ticket creation with variable substitution.

**Data Model**:
Core entities (Request, RequestAction) with JSONB storage for flexible state. Database indexes optimized for user queries, status filtering, correlation tracking, and team-based access control. Complete audit trail with correlation ID tracking.

## Architecture & Technology Stack

### Core Design Principles

1. **Schema-Driven**: All services defined via schema YAML documents
2. **Smart Fulfillment**: Automated actions with manual fallback. No automatic error recovery; failures require human intervention
3. **Document-Driven Convergence**: Platform teams collaborate through central document store
4. **Progressive Enhancement**: Teams evolve from manual to automated at their own pace
5. **Container-First**: EKS deployment with persistent services and horizontal scaling

### Service Components

**Catalog Management Engine**: GitHub repository integration with webhook processing, schema validation, PostgreSQL persistence with in-memory caching, CODEOWNERS enforcement.

**Request Orchestration System**: Complete request lifecycle management, variable substitution with 6+ scopes, circuit breaker architecture, state tracking and audit trail.

**Multi-Action Fulfillment Engine**: JIRA, REST API, Terraform, GitHub workflows. Sequential execution with dependency management. Limited retry logic; failures require manual intervention.

### Technology Stack

**Runtime**: Go, HTTP router, OpenAPI 3.0, JSON Schema validation  
**Storage**: PostgreSQL 14+ with JSONB support  
**Integrations**: GitHub/GitLab APIs, JIRA REST API, AWS Parameter Store  
**Deployment**: EKS containers, Application Load Balancer, Helm charts

### Schema Integration & Dynamic Forms

PAO implements the catalog.md schema specification for metadata, presentation, fulfillment, lifecycle, and monitoring. Transforms catalog form definitions into dynamic web forms and CLI interfaces with field type mapping (string→text-input, number→number-input, boolean→checkbox, etc.).

**Form Validation Pipeline**: Client-side validation → Pre-submit validation → Server-side validation → Request creation → Background processing

### Action Types & JIRA Framework

**Supported Actions**: JIRA ticket creation (Q3), REST API integration, Terraform configuration, GitHub workflow dispatch (Q4+)

**JIRA Integration**: Multi-instance support with flexible authentication (API token, OAuth2). Template processing with variable substitution. Real-time status queries without caching. Status mapping from JIRA states to request states.

### Templating Engine Architecture

**Template Format**: Go Template Engine for native parsing, built-in functions, type-safe access, and extensible function registry.

**Three-Scope Variable Resolution**:
- **User Scope**: Form field responses with namespace isolation (`{{.User.GroupID_FieldID}}`)
- **System Scope**: Platform values (`{{.System.Timestamp}}`, `{{.System.RequestID}}`, `{{.System.UserEmail}}`)
- **Fulfillment Scope**: Action execution results with flat namespace (`{{.Fulfillment.KeyName}}`)

**Function Categories**: String (upper, lower, trim, replace), Encoding (base64, json, url), Generation (uuid, timestamp), Validation (required, matches), Platform (slugify, sanitize, hash)

**Context Management**: Immutable User/System scopes, mutable Fulfillment scope. Template compilation caching for performance. Sandboxed execution with timeout controls and output size limits.

### Variable System

**Core Variable Scopes**:
- `{{fields.field_id}}` - User form input values
- `{{metadata.id}}` - Service metadata (id, name, version, category, owner)
- `{{request.id}}` - Request context (id, user.email, user.teams, timestamp, correlation_id)
- `{{system.date}}` - System-generated variables (date, timestamp, uuid, hostname)
- `{{environment.VAR}}` - Environment variables
- `{{outputs.action_id.field}}` - Previous action outputs for chaining

**Template Processing**: Mustache-style syntax with nested object access, array indexing, conditionals, and iteration.

**Transformation Functions**: upper, lower, concat, replace, json, base64, uuid, timestamp

**Validation & Error Handling**: Pre-execution validation, missing variable detection, type checking, circular dependency detection, detailed error messages.

### Manual Failure Resolution

**Failure Context Preservation**: System preserves detailed failure information including partial state inventory, error context, cleanup guidance, and request metadata.

**Human Decision Options**: Retry failed action, abort request, or escalate to manual support via structured JIRA ticket.

**Status Workflow**: Failed requests remain in "failed" status until human decision. Retry keeps "failed" status until resolution. Abort changes to "aborted". Escalate changes to "escalated" with JIRA reference.

## Implementation Requirements

### Core Features

**API Endpoints**: Catalog browsing, request submission/tracking, health checks, dynamic form generation, platform team validation tools

**Action Types**: JIRA ticket creation with variable substitution, REST API calls, GitHub workflow dispatch, Terraform configuration management

**External Integrations**: GitHub repository integration, JIRA REST API, PostgreSQL database

**Reliability**: Circuit breaker architecture, limited retry logic, connection pooling. All failures require manual intervention; no automatic recovery.

### Request Processing Architecture

**Q3 Synchronous Processing**: Request validation → JIRA action execution (1-2s) → Database transaction → Immediate response

**Request States**: submitted → in_progress → completed/failed/aborted/escalated

**State Transition Rules**: Strict validation, audit logging, terminal states immutable. Only failed requests can be retried.

**Volume Expectations**: Very low volume service (10-50 requests/day, 100/hour peak, 5-10 concurrent users)

### GitHub Catalog Integration

**Catalog Synchronization**: GitHub webhooks trigger catalog updates. Webhook endpoint validates changes against schema, refreshes cache, updates PostgreSQL.

**Processing Flow**: Signature verification → Event parsing → File filtering → Asynchronous processing → Error isolation

**Cache Strategy**: In-memory cache with PostgreSQL persistence. Event-driven invalidation. CODEOWNERS enforcement for governance.

## Performance & Success Metrics

**Performance Targets**: API response < 500ms, request submission < 3s, 99.5% uptime, 100 requests/hour throughput, 5-10 concurrent users

**Business Impact**: Significant provisioning time reduction, high platform adoption, high developer satisfaction, high automation rate

**Operational Excellence**: Low error rate, strong security compliance, fast incident resolution, efficient support

## Deployment Architecture

**Recommendation**: EKS Container Deployment over AWS Lambda

**Cost Analysis**: EKS ~$1,536/year vs Lambda ~$2,500/year (including RDS Proxy). Annual savings of $814-$964.

**EKS Benefits**: No cold starts, consistent performance (sub-200ms), persistent connections, better observability, simplified operations (10-20 hours/year engineering savings)

**Lambda Issues**: Cold start latency (1-3s, 10-15% of requests), connection overhead, variable performance, complex debugging

**Volume Projections**: 3,100-10,400 requests/day current, growing to 15,000-20,000/day

**Implementation Strategy**: Deploy 2 API pods (1 vCPU + 2GB RAM), horizontal autoscaling (2-6 pods), persistent database connections, comprehensive monitoring

**Security & Compliance**: AWS IAM with SigV4 signing, audit logging with correlation IDs, AWS Parameter Store for secrets, request validation

## Service Configuration

**Container Requirements**: HTTP server on port 8080, health endpoints (/api/v1/health, /api/v1/health/ready), environment variables, graceful shutdown, 1-2 CPU cores, 2-4GB RAM

**Security**: AWS IAM with SigV4 signing, AWS Parameter Store for secrets, Aurora PostgreSQL with IAM auth

**Database Connection Pooling**: EKS-optimized settings (50 max open, 20 idle, 1h lifetime, 10m idle timeout)

**Caching Strategy**: In-memory with TTLs (catalog items: 1h, categories: 6h, request status: 5m, form schemas: 2h), 512MB max memory, LRU eviction

**Service Components**: API server (port 8080), catalog processor (5m intervals), request processor (10 workers), status updater (5m intervals)

**Configuration Management**: Environment variables with validation, AWS Parameter Store integration for secrets, structured configuration loading with defaults

## SQL Schema

### Core Tables

**requests**: Core request tracking with UUID primary key, catalog_item_id, user details, status (submitted/in_progress/completed/failed/aborted/escalated), request_data (JSONB), correlation_id for audit trail, escalation_ticket_id for manual support

**request_actions**: Individual action execution tracking with request_id foreign key, action_index for sequencing, action_type (jira-ticket in Q3), action_config (JSONB), status, output (JSONB), error_details, external_reference (JIRA ticket key)

**catalog_items**: GitHub repository cache with id, name, description, version, category, owner details, definition (JSONB), file_path, git_sha for synchronization

**audit_logs**: Complete audit trail with correlation_id, request_id/action_id references, event_type, event_data (JSONB), user context, source_system

### Database Features

**Indexes**: Optimized for user request queries, status filtering, correlation tracking, JIRA reference lookup, team-based access control (GIN index on user_teams array)

**Triggers**: Auto-update timestamps, audit logging for all request changes with correlation tracking

**Constraints**: Foreign key relationships with appropriate cascading, check constraints for data integrity, escalation validation

**Maintenance**: Automated cleanup for completed requests (90 days), audit logs (1 year), regular vacuum/analyze operations

**Migration Management**: Schema versioning table with version tracking, description, timestamps, and checksums

## Future Enhancements

### Q4 2025 and Beyond

**Advanced Action Types**: Terraform Cloud/Enterprise integration, AWS Lambda invocation, CloudFormation/CDK, Ansible playbooks, secure script execution

**Enhanced Orchestration**: Parallel action execution, conditional workflows, approval gates, automated rollback, circuit breaker patterns

**Developer Experience**: Real-time status updates (WebSocket), interactive debugging, request templates, bulk operations, dependency visualization

**Platform Team Tools**: Catalog analytics, A/B testing framework, validation sandbox, auto-generated documentation, cost estimation

**Security & Compliance**: Policy as Code (OPA), compliance reporting, secret rotation, access reviews, data classification

**Multi-Cloud & Hybrid**: Azure/GCP/on-premises support, cloud provider abstraction, hybrid workflows, cost optimization, disaster recovery

**AI & Machine Learning**: Intelligent recommendations, anomaly detection, predictive scaling, natural language processing, automated optimization

**Enterprise Integration**: ServiceNow bi-directional integration, Active Directory/LDAP, enterprise monitoring, compliance frameworks (SOC2, PCI-DSS, HIPAA), financial management

**Advanced Analytics**: End-to-end tracing, performance profiling, capacity planning, business metrics integration, custom dashboards

**Ecosystem Extensions**: Marketplace integration, plugin architecture, API gateway enhancements, event streaming, GraphQL support

### Technology Evolution

**Architecture Patterns**: Event-driven architecture, microservices decomposition, CQRS, saga pattern for distributed transactions

**Infrastructure**: Kubernetes deployment options, service mesh integration (Istio/Linkerd), GitOps patterns (ArgoCD/Flux), Infrastructure as Code (Pulumi/CDK)

**Data & Analytics**: Data lake integration, real-time stream processing (Kafka), machine learning pipelines (MLOps), time-series databases

**Implementation Phases**: Q4 2025 (Terraform, parallel execution), Q1 2026 (multi-cloud, AI), Q2 2026 (enterprise integrations), Q3 2026 (advanced analytics)