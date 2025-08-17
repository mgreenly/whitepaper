# Platform Automation Orchestrator - Catalog Repository Design

## Table of Contents

- [Executive Summary](#executive-summary)
- [Strategic Context](#strategic-context)
- [Repository Architecture](#repository-architecture)
- [Catalog Item Schema v2.0](#catalog-item-schema-v20)
- [Action Types Reference](#action-types-reference)
- [Variable System & Templating](#variable-system--templating)
- [Governance Framework](#governance-framework)
- [Implementation Roadmap](#implementation-roadmap)
- [Best Practices](#best-practices)
- [Success Metrics](#success-metrics)
- [Migration Strategy](#migration-strategy)
- [Complete Examples](#complete-examples)

## Executive Summary

The Orchestrator Catalog Repository serves as the document-driven convergence point for the Platform Automation Orchestrator (PAO), transforming fragmented multi-week provisioning into streamlined self-service. Operating within the Integration and Delivery Plane of our five-plane reference architecture, this repository houses structured YAML catalog definitions following Schema v2.0 specifications. These definitions serve triple purposes: generating dynamic developer portal interfaces, defining multi-action fulfillment workflows, and providing enterprise governance metadata. By enabling platform teams to collaborate through unified catalog definitions while maintaining full ownership and control, we achieve 90%+ provisioning time reduction (weeks to hours) while respecting operational constraints including September-January restricted change periods.

## Strategic Context

### Business Imperative
Our organization's innovation capacity is constrained by 2-3 week provisioning delays across compute, database, messaging, networking, storage, security, and monitoring teams. The catalog repository addresses this by:
- Creating a single convergence point for all platform service definitions
- Enabling self-service provisioning through standardized Schema v2.0 specifications
- Supporting progressive enhancement from manual JIRA tickets to fully automated fulfillment
- Respecting operational constraints including restricted change periods
- Maintaining team autonomy while enabling collaboration

### Architectural Alignment
The catalog repository operates as the foundation for PAO within our five-plane reference architecture:
- **Developer Control Plane**: Catalog definitions generate sophisticated portal interfaces
- **Integration and Delivery Plane**: PAO consumes catalog for orchestration logic
- **Security and Compliance Plane**: Catalog enforces policies and compliance metadata
- **Monitoring and Logging Plane**: Catalog defines observability requirements
- **Resource Plane**: Catalog orchestrates provisioning across all infrastructure domains

## Repository Architecture

### Core Design Principles

1. **Document-Driven Convergence**: Platform teams collaborate through YAML definitions without organizational restructuring
2. **Schema v2.0 Compliance**: Comprehensive 1700+ line specification with strict validation
3. **Progressive Enhancement**: Teams evolve from manual to automated at their own pace
4. **Binary Fulfillment Model**: Services operate in either manual OR fully automated mode (no partial automation)
5. **Sequential Execution**: All actions execute in strict sequential order for predictability
6. **Enterprise Governance**: Built-in support for compliance, security, and audit requirements
7. **GitOps Workflow**: Version-controlled with CODEOWNERS enforcement and automated validation

### Directory Structure

```
orchestrator-catalog-repo/
├── README.md                           # Quick start guide
├── GOVERNANCE.md                       # Contribution guidelines
├── schema/
│   ├── catalog-item.schema.json       # Core Schema v2.0 specification
│   ├── action-types/                  # Action-specific schemas
│   │   ├── jira-ticket.schema.json
│   │   ├── rest-api.schema.json
│   │   ├── terraform.schema.json
│   │   ├── github-workflow.schema.json
│   │   ├── webhook.schema.json
│   │   ├── approval-workflow.schema.json
│   │   └── cost-estimation.schema.json
│   └── extensions/                    # Future extension points
├── catalog/                            # Service definitions by category
│   ├── _index.yaml                    # Catalog metadata
│   ├── compute/                       # Compute services
│   ├── databases/                     # Database services
│   ├── messaging/                     # Messaging services
│   ├── networking/                    # Network services
│   ├── storage/                       # Storage services
│   ├── security/                      # Security services
│   └── monitoring/                    # Observability services
├── templates/                          # Starter templates
│   ├── minimal-service.yaml
│   ├── full-featured-service.yaml
│   └── migration-guide.yaml
├── scripts/                            # Utility scripts
│   ├── validate-catalog.sh
│   ├── generate-docs.py
│   └── migrate-service.py
├── tests/                              # Test fixtures
└── .github/
    ├── CODEOWNERS                      # Ownership mapping
    └── workflows/                      # CI/CD pipelines
```

## Catalog Item Schema v2.0

### Core Document Structure

```yaml
version: "2.0"
kind: CatalogItem

metadata:                               # Service metadata
  id: string                           # Unique identifier
  name: string                         # Display name
  description: string                  # Service description (50-500 chars)
  version: string                      # Semantic version
  category: string                     # Primary category
  owner:
    team: string                       # Platform team identifier
    contact: string                    # Contact email
    escalation: string                 # Escalation path
  tags: [string]                       # Search tags
  visibility:
    environments: [string]             # Available environments
    teams: [string]                    # Authorized teams
    require_approval: boolean          # Approval requirement
  sla:
    provisioning_time: string          # Expected time
    support_level: string              # Support tier
    availability: string               # Uptime commitment
  cost:
    estimate_enabled: boolean
    base_cost: number
    unit_cost: object
  compliance:
    data_classification: string        # Data sensitivity
    regulatory_requirements: [string]  # SOC2, HIPAA, etc.
    audit_logging: boolean

presentation:                          # UI/UX definition
  display:
    icon: string
    color: string
    documentation_url: string
  
  form:
    layout: string                     # wizard, single-page, tabbed
    submit_text: string
    confirmation_required: boolean
    
  groups:                              # Field groups
    - id: string
      name: string
      description: string
      order: integer
      collapsible: boolean
      conditional:                     # Group visibility logic
        field: string
        operator: string               # eq, ne, gt, lt, gte, lte, in, not_in, contains
        value: any
      
      fields:                          # Field definitions
        - id: string
          name: string
          type: string                 # 10+ field types supported
          required: boolean
          validation:
            pattern: string
            min: number
            max: number
            enum: [any]
            messages: object
          conditional:                 # Field visibility
            field: string
            operator: string
            value: any
          datasource:                  # Dynamic data
            type: string               # api, static, reference
            config: object

fulfillment:                          # Provisioning definition
  strategy:
    mode: string                       # manual, automatic, hybrid
    priority: string
    timeout: integer
  
  prerequisites:                       # Pre-execution checks
    - type: string
      config: object
      required: boolean
  
  manual:                              # Manual fallback (required)
    description: string
    instructions: string
    actions:
      - type: jira-ticket
        config: object
  
  automatic:                           # Automated fulfillment
    state_management:
      enabled: boolean
      backend: string                  # dynamodb, postgresql
    
    actions:                           # Automation actions (sequential execution)
      - id: string
        name: string
        type: string                   # 7+ action types
        order: integer                 # Sequential execution order
        
        config: object                 # Type-specific configuration
        
        conditions:                    # Execution conditions
          - field: string
            operator: string
            value: any
        
        dependencies:
          wait_for: [string]
          require_success: boolean
        
        retry:
          enabled: boolean
          attempts: integer
          delay: integer
          backoff: string              # linear, exponential, fibonacci
        
        circuit_breaker:
          enabled: boolean
          failure_threshold: integer
          timeout: integer
        
        error_handling:
          strategy: string             # fail, continue, retry, fallback
          fallback_action: string
        
        rollback:
          enabled: boolean
          automatic: boolean
        
        output:
          capture: boolean
          fields: object
  
  notifications:
    on_start:
      enabled: boolean
      channels: [string]
    on_success:
      enabled: boolean
      template: string
    on_failure:
      enabled: boolean
      escalation_after: integer

lifecycle:                             # Lifecycle management
  deprecation:
    deprecated: boolean
    sunset_date: string
    migration_path: string
  maintenance:
    windows: [object]
  versioning:
    strategy: string
    compatibility: string

monitoring:                            # Observability
  metrics:
    enabled: boolean
    endpoints: [string]
  logging:
    enabled: boolean
    level: string
    retention: integer
  health_checks:
    - name: string
      type: string
      config: object
      interval: integer
```

## Action Types Reference

### 1. JIRA Ticket Creation
```yaml
type: jira-ticket
config:
  connection:
    instance: string                   # JIRA instance
    use_default: boolean
  ticket:
    project: string
    issue_type: string
    summary_template: string           # Supports variables
    description_template: string
  fields:
    assignee: string
    priority: string
    labels: [string]
    custom_fields: object
  workflow:
    transition_on_create: string
    expected_resolution_time: integer
```

### 2. REST API Integration
```yaml
type: rest-api
config:
  endpoint:
    url: string                        # Supports variables
    method: string                    # GET, POST, PUT, DELETE, PATCH
    timeout: integer
  authentication:
    type: string                       # none, basic, bearer, oauth2, api-key
    credentials: object
  body:
    type: string                       # json, xml, form, raw
    content_template: string
  response:
    expected_status: [integer]
  parsing:
    extract:                           # Extract fields from response
      - path: string                   # JSONPath or XPath
        name: string
        required: boolean
  circuit_breaker:
    enabled: boolean
    failure_threshold: integer
```

### 3. Terraform Configuration
```yaml
type: terraform
config:
  repository:
    url: string                        # Git repository URL
    branch: string                     # Target branch for PR/commit
    path: string                       # Path in repository for config
  module:
    source: string                     # Module source (git, registry, local)
    version: string                    # Module version
    name: string                       # Module name
  variables: object                    # Module variables
  workspace:
    name: string                       # Terraform workspace name
  backend:
    type: string                       # s3, azurerm, gcs, remote
    config: object                     # Backend configuration
  commit:
    message: string                    # Commit message template
    author: string                     # Author name
    auto_merge: boolean                # Auto-merge PR if checks pass
```

### 4. GitHub Workflow Dispatch
```yaml
type: github-workflow
config:
  repository:
    owner: string
    name: string
  workflow:
    id: string                         # Workflow ID or filename
    ref: string                        # Git ref
  inputs: object                       # Workflow inputs
  authentication:
    type: string                       # token, app
    token_ref: string
    app_id: string
  monitoring:
    wait_for_completion: boolean
    timeout: integer
```

### 5. Webhook Invocation
```yaml
type: webhook
config:
  endpoint:
    url: string
    method: string
  headers: object
  body:
    type: string
    template: string
  signature:                           # HMAC signing
    enabled: boolean
    algorithm: string
    secret_ref: string
    header_name: string
```

### 6. Approval Workflow (Enterprise)
```yaml
type: approval-workflow
config:
  workflow:
    name: string
    description: string
  stages:
    - name: string
      order: integer
      approvers:
        type: string                   # users, groups, dynamic
        list: [string]
        minimum_approvals: integer
      timeout:
        duration: integer
        action: string                 # approve, reject, escalate
```

### 7. Cost Estimation (Enterprise)
```yaml
type: cost-estimation
config:
  provider:
    type: string                       # aws, azure, gcp, custom
    region: string
  resources:
    - type: string
      quantity: integer
      specifications: object
  pricing:
    model: string
    include_tax: boolean
    currency: string
```

## Variable System & Templating

### Variable Scopes
```yaml
# User Input
{{fields.field_id}}                   # Form field values
{{fields.nested.field}}                # Nested field access

# Metadata
{{metadata.id}}                        # Service ID
{{metadata.owner.team}}                # Owner team
{{metadata.category}}                  # Service category

# Request Context
{{request.id}}                         # Unique request ID
{{request.user.email}}                 # User email
{{request.user.department}}            # User department
{{request.environment}}                # Target environment

# System Variables
{{system.date}}                        # Current date
{{system.uuid}}                        # Random UUID
{{system.region}}                      # Deployment region

# Environment & Secrets
{{env.VARIABLE_NAME}}                  # Environment variable
{{secrets.SECRET_NAME}}                # Secret value

# Action Outputs
{{output.action_id.field}}             # Previous action output
{{output.action_id.status}}            # Action status

# Functions
{{uuid()}}                             # Generate UUID
{{timestamp()}}                        # Current timestamp
{{concat(str1, str2)}}                 # String concatenation
{{upper(string)}}                      # Uppercase
{{json(object)}}                       # JSON encode
{{base64(string)}}                     # Base64 encode
```

### Conditional Logic
```yaml
# If-Then-Else
{{#if fields.environment == "production"}}
  High priority deployment
{{else}}
  Standard deployment
{{/if}}

# Switch Statement
{{#switch fields.tier}}
  {{#case "gold"}}
    Premium resources
  {{#case "silver"}}
    Standard resources
  {{#default}}
    Basic resources
{{/switch}}

# Loops
{{#each fields.servers as server}}
  Server: {{server.name}} ({{server.ip}})
{{/each}}
```

## Governance Framework

### Repository Governance

#### CODEOWNERS Structure
```yaml
# Global owners
* @platform-architecture-team

# Category owners
/catalog/compute/ @platform-compute-team
/catalog/databases/ @platform-database-team
/catalog/messaging/ @platform-messaging-team
/catalog/networking/ @platform-networking-team
/catalog/storage/ @platform-storage-team
/catalog/security/ @platform-security-team
/catalog/monitoring/ @platform-observability-team

# Schema ownership
/schema/ @platform-architecture-team
```

#### Contribution Workflow
1. Create feature branch: `service/team-name/service-name`
2. Copy template and define service
3. Validate locally: `./scripts/validate-catalog.sh`
4. Submit PR with automated validation
5. Owner team approval required
6. Architecture review for new patterns
7. Staging deployment (automatic)
8. Production deployment (manual approval)

### Quality Standards

#### Service Definition Standards
- **Naming**: `{category}-{service}-{variant}` (e.g., `database-postgresql-standard`)
- **Documentation**: Minimum 50 character descriptions with examples
- **Validation**: All required fields must have validation rules
- **SLA**: Realistic provisioning times based on metrics
- **Progressive Enhancement**: Clear migration path from manual to automated

#### Compliance Requirements
- No secrets in catalog items (use references only)
- Data classification in metadata
- Regulatory requirement tags (SOC2, HIPAA)
- Audit logging configuration
- RBAC for catalog modifications

## Best Practices

### For Platform Teams
1. **Start Simple**: Begin with manual JIRA fulfillment
2. **Iterate**: Add automation incrementally
3. **User-Centric**: Use clear, non-technical language
4. **Robust Error Handling**: Plan for failure scenarios
5. **Performance**: Optimize action sequences

### For Catalog Maintainers
1. **Consistency**: Enforce naming conventions
2. **Documentation First**: Document before implementing
3. **Testing Rigor**: Validate all scenarios
4. **Continuous Improvement**: Monitor usage metrics

## Success Metrics

### Performance Targets
- **API Response Time**: <200ms catalog operations
- **Request Processing**: 95% within SLA
- **System Availability**: 99.9% uptime
- **Throughput**: 1000+ concurrent requests

### Business Impact
- **Provisioning Time**: 90%+ reduction (weeks to hours)
- **Platform Adoption**: 100% teams with 1+ service
- **Developer Satisfaction**: >4.5/5 rating
- **Automation Rate**: 80%+ services automated

### Operational Excellence
- **Error Rate**: <5% failure rate
- **Security Compliance**: Zero incidents
- **Documentation**: 100% coverage
- **Support Resolution**: <24 hours

## Migration Strategy

### Progressive Enhancement Path
```yaml
# Phase 1: Manual Only
fulfillment:
  manual:
    actions:
      - type: jira-ticket

# Phase 2: Hybrid (Binary Choice)
fulfillment:
  manual:
    actions:
      - type: jira-ticket
  automatic:
    actions:
      - type: terraform
      - type: rest-api

# Phase 3: Fully Automated (Default)
fulfillment:
  automatic:
    actions:
      - type: terraform
      - type: rest-api
      - type: webhook
```

### Migration Process
1. **Discovery**: Document current processes
2. **Definition**: Create catalog items
3. **Testing**: Validate in sandbox
4. **Enhancement**: Add automation
5. **Optimization**: Continuous improvement

## Complete Examples

### PostgreSQL Database Service (Abbreviated)
```yaml
version: "2.0"
kind: CatalogItem

metadata:
  id: database-postgresql-standard
  name: PostgreSQL Database
  description: Provision a managed PostgreSQL database with automatic backups
  version: 2.1.0
  category: databases
  owner:
    team: platform-database-team
    contact: platform-db@company.com
  sla:
    provisioning_time: 4 hours
    support_level: tier-1

presentation:
  form:
    layout: wizard
  groups:
    - id: basic_config
      name: Basic Configuration
      fields:
        - id: instance_name
          name: Instance Name
          type: string
          required: true
          validation:
            pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"

fulfillment:
  strategy:
    mode: hybrid
    priority: normal
  
  manual:
    actions:
      - type: jira-ticket
        config:
          ticket:
            project: PLATFORM
  
  automatic:
    actions:
      - id: provision-database
        type: terraform
        config:
          repository:
            url: "https://github.com/company/terraform-configs"
            branch: "main"
            path: "databases/{{fields.environment}}"
          module:
            source: "terraform-aws-modules/rds/aws"
            version: "5.0.0"
            name: "rds-postgresql"
          variables:
            instance_identifier: "{{fields.instance_name}}"
          commit:
            message: "Provision PostgreSQL database {{fields.instance_name}}"
            auto_merge: true
```

## Conclusion

The Orchestrator Catalog Repository provides the document-driven foundation for transforming our developer experience from fragmented multi-week provisioning to streamlined self-service. By establishing Schema v2.0 specifications, governance processes, and progressive enhancement paths, we enable platform teams to modernize at their own pace while delivering immediate value through 90%+ provisioning time reduction. This design respects operational constraints, leverages existing systems, and provides a clear path toward full automation, positioning our platform as a strategic accelerator for innovation.