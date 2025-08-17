# Platform Automation Orchestrator - Catalog Repository

## Table of Contents

- [Core Concepts](#core-concepts)
  - [Fulfillment Strategy](#fulfillment-strategy)
  - [Sequential Execution](#sequential-execution)
- [Repository Structure](#repository-structure)
- [Schema Reference](#schema-reference)
  - [Minimal Service Definition](#minimal-service-definition)
  - [Field Types](#field-types)
  - [Action Types](#action-types)
- [Variable System](#variable-system)
  - [Available Variables](#available-variables)
  - [Functions](#functions)
  - [Conditionals](#conditionals)
- [Progressive Enhancement Path](#progressive-enhancement-path)
- [Governance](#governance)
  - [CODEOWNERS Mapping](#codeowners-mapping)
  - [Approval Requirements](#approval-requirements)
- [Validation & Testing](#validation--testing)
  - [Pre-Commit Checklist](#pre-commit-checklist)
  - [Testing Strategy](#testing-strategy)
- [Common Patterns](#common-patterns)
  - [Multi-Environment Service](#multi-environment-service)
  - [Approval-Required Service](#approval-required-service)
  - [Cost-Aware Service](#cost-aware-service)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Success Metrics](#success-metrics)
  - [Service KPIs](#service-kpis)
  - [Platform KPIs](#platform-kpis)
- [Migration Guide](#migration-guide)
- [Quick Reference](#quick-reference)
- [Example: Complete PostgreSQL Service](#example-complete-postgresql-service)
- [Additional Resources](#additional-resources)

## Core Concepts

### Fulfillment Strategy
All services **MUST** define a manual fulfillment strategy. Automated fulfillment is optional but desired.

**Manual Strategy (Required)**
- Primary fallback mechanism
- Used before automation is ready
- Activated on automation errors

**Automated Strategy (Optional)**
- Progressive enhancement from manual
- Executes when fully defined and tested
- Stops and waits for human decision on failure

**Error Handling (Phase 1):**
- **Manual Completion**: Convert remaining actions to manual tickets
- **Human-Triggered Retry**: Operator can retry failed actions (unlimited attempts)
- **Skip**: Continue with next action (if non-critical)

*Note: Future phases will introduce automated retry policies and self-healing capabilities*

### Sequential Execution
All actions execute in strict order. Use `order` field to control sequence.

## Repository Structure

```
orchestrator-catalog-repo/
├── catalog/                    # Service definitions by category
│   ├── {category}/            # compute, databases, etc.
│   │   └── {service}.yaml     # Your service definition
├── schema/                     # Schema specifications
├── templates/                  # Starter templates
├── scripts/                    # Validation tools
└── .github/
    └── CODEOWNERS             # Team ownership mapping
```

## Schema Reference

### Minimal Service Definition

```yaml
kind: CatalogItem

metadata:
  id: {category}-{service}-{variant}  # e.g., database-postgresql-standard
  name: Display Name
  description: 50-500 character description
  version: 1.0.0
  category: databases
  owner:
    team: platform-{category}-team
    contact: team@company.com

presentation:
  form:
    groups:
      - id: config
        name: Configuration
        fields:
          - id: name
            name: Resource Name
            type: string
            required: true
            validation:
              pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"

fulfillment:
  strategy:
    mode: manual  # or automatic
  
  manual:
    actions:
      - type: jira-ticket
        config:
          ticket:
            project: PLATFORM
            issue_type: Task
            summary_template: "Provision {{fields.name}}"
```

### Field Types

| Type | Use Case | Validation |
|------|----------|------------|
| `string` | Text input | pattern, min/max length |
| `number` | Numeric values | min/max, step |
| `boolean` | Yes/No choices | - |
| `select` | Single choice | enum values |
| `multiselect` | Multiple choices | enum values |
| `date` | Date picker | min/max date |
| `file` | File upload | size, type |
| `textarea` | Multi-line text | min/max length |
| `password` | Sensitive data | pattern, strength |
| `email` | Email addresses | format validation |

### Action Types

#### 1. JIRA Ticket (Manual Fallback)
```yaml
type: jira-ticket
config:
  ticket:
    project: PLATFORM
    summary_template: "{{fields.name}} request"
```

#### 2. REST API
```yaml
type: rest-api
config:
  endpoint:
    url: "https://api.internal.com/provision"
    method: POST
  body:
    type: json
    content_template: '{"name": "{{fields.name}}"}'
```

#### 3. Terraform
```yaml
type: terraform
config:
  content_template: |
    resource "aws_instance" "{{fields.name}}" {
      instance_type = "{{fields.instance_type}}"
    }
  filename: "{{fields.name}}.tf"
  repository_mapping: "terraform-infrastructure"
```

#### 4. GitHub Workflow
```yaml
type: github-workflow
config:
  repository:
    owner: platform-team
    name: automation-workflows
  workflow:
    id: provision.yml
  inputs:
    resource_name: "{{fields.name}}"
```

#### 5. Webhook
```yaml
type: webhook
config:
  endpoint:
    url: "{{env.WEBHOOK_URL}}"
    method: POST
  body:
    template: '{"resource": "{{fields.name}}"}'
```

#### 6. Cost Estimation
```yaml
type: cost-estimation
config:
  provider:
    type: aws
    region: "{{fields.region}}"
  resources:
    - type: ec2_instance
      specifications:
        instance_type: "{{fields.instance_type}}"
```

## Variable System

### Available Variables

| Scope | Example | Description |
|-------|---------|-------------|
| **User Input** | `{{fields.name}}` | Form field values |
| **Metadata** | `{{metadata.id}}` | Service metadata |
| **Request** | `{{request.user.email}}` | Request context |
| **System** | `{{system.date}}` | System variables |
| **Environment** | `{{env.API_KEY}}` | Environment variables |
| **Secrets** | `{{secrets.DB_PASSWORD}}` | Secret values |
| **Output** | `{{output.action_id.field}}` | Previous action output |

### Functions

- `{{uuid()}}` - Generate UUID
- `{{timestamp()}}` - Current timestamp
- `{{upper(string)}}` - Uppercase conversion
- `{{concat(str1, str2)}}` - String concatenation
- `{{json(object)}}` - JSON encoding
- `{{base64(string)}}` - Base64 encoding

### Conditionals

```yaml
{{#if fields.environment == "production"}}
  priority: high
{{else}}
  priority: normal
{{/if}}
```

## Progressive Enhancement Path

### Phase 1: Manual Only
Start with JIRA ticket creation. No automation required.

### Phase 2: Hybrid Mode
Add automatic fulfillment alongside manual fallback.

### Phase 3: Full Automation
Remove manual option when confidence is high.

## Governance

### CODEOWNERS Mapping

```
/catalog/compute/        @platform-compute-team
/catalog/databases/      @platform-database-team
/catalog/messaging/      @platform-messaging-team
/catalog/networking/     @platform-networking-team
/catalog/storage/        @platform-storage-team
/catalog/security/       @platform-security-team
/catalog/monitoring/     @platform-observability-team
/schema/                 @platform-architecture-team
```

### Approval Requirements

1. **New Service**: Team owner + Architecture review
2. **Major Update**: Team owner approval
3. **Minor Update**: Auto-merge after validation
4. **Schema Change**: Architecture team only

## Validation & Testing

### Pre-Commit Checklist

- [ ] Schema validates: `./scripts/validate-catalog.sh {file}`
- [ ] No secrets in plaintext
- [ ] Documentation complete
- [ ] SLA defined
- [ ] Owner contact valid
- [ ] Manual fallback present

### Testing Strategy

1. **Local**: Validate schema compliance
2. **CI/CD**: Automated validation on PR
3. **Staging**: Test with real infrastructure
4. **Production**: Gradual rollout with monitoring

## Common Patterns

### Multi-Environment Service

```yaml
presentation:
  form:
    groups:
      - id: environment
        fields:
          - id: env
            type: select
            enum: [dev, staging, prod]

fulfillment:
  automatic:
    actions:
      - type: terraform
        conditions:
          - field: env
            operator: eq
            value: prod
        config:
          content_template: |
            # Production configuration
```

### Approval-Required Service

```yaml
metadata:
  visibility:
    require_approval: true
    
fulfillment:
  prerequisites:
    - type: approval
      config:
        approvers: ["manager@company.com"]
        timeout: 72h
```

### Cost-Aware Service

```yaml
metadata:
  cost:
    estimate_enabled: true
    base_cost: 100
    unit_cost:
      per_gb: 0.10
      
fulfillment:
  automatic:
    actions:
      - type: cost-estimation
        order: 1
      - type: terraform
        order: 2
        conditions:
          - field: output.cost-estimation.total
            operator: lt
            value: 1000
```

## Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| Schema validation fails | Check required fields and types |
| Variable not replaced | Verify variable scope and syntax |
| Action fails | Check retry and fallback configuration |
| Approval timeout | Configure escalation path |
| Cost exceeds budget | Add cost estimation action |

## Success Metrics

### Service KPIs
- **Provisioning Time**: Target < 4 hours
- **Automation Rate**: Target > 80%
- **Error Rate**: Target < 5%
- **User Satisfaction**: Target > 4.5/5

### Platform KPIs
- **Service Coverage**: 100% teams with 1+ service
- **Request Volume**: Track monthly growth
- **MTTR**: < 30 minutes for failures
- **Compliance**: 100% audit logging

## Migration Guide

### From Manual to Automated

1. **Document** current manual process
2. **Define** catalog item with manual mode
3. **Test** in staging environment
4. **Add** automation actions incrementally
5. **Monitor** success rate > 95%
6. **Switch** to automatic mode
7. **Remove** manual fallback (optional)

## Quick Reference

### File Naming Convention
`{category}-{service}-{variant}.yaml`

### Branch Naming
`service/{team-name}/{service-name}`

### Version Format
Semantic versioning: `MAJOR.MINOR.PATCH`

### Required Metadata Fields
- `id`, `name`, `description`, `version`, `category`, `owner.team`, `owner.contact`

### Required Fulfillment Fields
- `strategy.mode`, `manual.actions` (always required as fallback)

## Example: Complete PostgreSQL Service

```yaml
kind: CatalogItem

metadata:
  id: database-postgresql-standard
  name: PostgreSQL Database
  description: Managed PostgreSQL with automatic backups and monitoring
  version: 2.1.0
  category: databases
  owner:
    team: platform-database-team
    contact: db-team@company.com
  sla:
    provisioning_time: 4h
  cost:
    estimate_enabled: true
    base_cost: 50

presentation:
  form:
    layout: wizard
    groups:
      - id: basic
        name: Basic Configuration
        fields:
          - id: instance_name
            name: Instance Name
            type: string
            required: true
            validation:
              pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
          - id: instance_class
            name: Instance Size
            type: select
            required: true
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: storage_size
            name: Storage (GB)
            type: number
            required: true
            validation:
              min: 20
              max: 1000

fulfillment:
  strategy:
    mode: automatic
    
  manual:
    actions:
      - type: jira-ticket
        config:
          ticket:
            project: DBA
            summary_template: "PostgreSQL: {{fields.instance_name}}"
            
  automatic:
    actions:
      - id: estimate-cost
        type: cost-estimation
        order: 1
        config:
          provider:
            type: aws
            region: us-east-1
            
      - id: provision-db
        type: terraform
        order: 2
        config:
          content_template: |
            module "postgresql_{{fields.instance_name}}" {
              source         = "terraform-aws-modules/rds/aws"
              identifier     = "{{fields.instance_name}}"
              engine         = "postgres"
              instance_class = "{{fields.instance_class}}"
              allocated_storage = {{fields.storage_size}}
            }
          filename: "{{fields.instance_name}}.tf"
          repository_mapping: "terraform-databases"
          
      - id: notify-completion
        type: webhook
        order: 3
        config:
          endpoint:
            url: "{{env.NOTIFICATION_WEBHOOK}}"
          body:
            template: |
              {
                "service": "postgresql",
                "instance": "{{fields.instance_name}}",
                "status": "provisioned"
              }
```

## Additional Resources

- [Whitepaper](whitepaper.md) - Strategic context
- [Roadmap](roadmap.md) - Implementation timeline
- [Service Catalog](service.md) - Service details
- [API Documentation](/docs/api) - Technical reference
- [Support](platform-team@company.com) - Get help