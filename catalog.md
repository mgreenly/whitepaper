# Orchestrator Catalog Repository Design Document

## Executive Summary

This document defines the complete design for the Orchestrator Catalog Repository, the central document store for the Platform Automation Orchestrator (PAO). This repository enables platform teams to define their service offerings through structured YAML documents that drive both the developer portal interface and automated fulfillment processes.

## Repository Architecture

### Directory Structure
```
orchestrator-catalog-repo/
├── README.md                    # Repository overview and quick start
├── schema/                      # Validation schemas
│   └── catalog-item.schema.yaml
├── catalog/                     # Service definitions organized by category
│   ├── README.md               # Catalog overview
│   ├── compute/                # Container, VMs, serverless, batch
│   ├── databases/              # PostgreSQL, MySQL, MongoDB, Redis
│   ├── messaging/              # Queues, streams, pub/sub, notifications
│   ├── networking/             # Load balancers, DNS, CDN, VPN
│   ├── storage/                # Object, file, block, backup
│   ├── security/               # IAM, secrets, certificates, compliance
│   ├── monitoring/             # Logging, metrics, tracing, alerts
│   └── other/                  # Miscellaneous services
├── templates/                   # Starter templates
│   └── catalog-item.template.yaml
└── .github/
    └── workflows/              # Validation automation
        └── validate.yaml
```

## Catalog Item Schema

### Core Structure

Each catalog item is a YAML document with three main sections:

```yaml
header:      # Metadata about the service
presentation: # User interface definition  
fulfillment:  # Service provisioning logic
```

### 1. Header Section

Defines service metadata and ownership:

```yaml
header:
  id: string                    # Unique identifier (e.g., "compute-container-app")
  name: string                  # Display name for users
  description: string           # Service description
  version: string               # Semantic version (1.0.0)
  category: string              # Category placement
  owner: string                 # Platform team owner
  tags: [string]                # Search/filter tags
  sla:                          # Service level agreements
    provisioning_time: string   # Expected time (e.g., "2 hours")
    support_level: string       # Support tier (tier-1, tier-2, tier-3)
```

### 2. Presentation Section

Defines the user interface for collecting service parameters:

```yaml
presentation:
  groups:                       # Logical field groupings
    - id: string               # Group identifier
      name: string             # Display name
      description: string      # Group purpose
      order: integer           # Display sequence (1-based)
      collapsible: boolean     # Can be collapsed in UI
      fields:                  # Input fields
        - id: string           # Field identifier
          name: string         # Display label
          description: string  # Help text
          type: string         # Field type (see below)
          order: integer       # Display order
          required: boolean    # Is mandatory
          default: any         # Default value
          validation:          # Validation rules
            pattern: string    # Regex pattern
            min: number        # Minimum value/length
            max: number        # Maximum value/length
            enum: [any]        # Allowed values
          conditional:         # Show/hide logic
            field: string      # Field to check
            operator: string   # Comparison (eq, ne, gt, lt, in)
            value: any         # Value to compare
```

#### Supported Field Types

- **string**: Single-line text input
- **text**: Multi-line text area
- **integer**: Whole number input
- **number**: Decimal number input
- **boolean**: Checkbox/toggle switch
- **selection**: Single choice dropdown
- **multi-selection**: Multiple choice selection
- **date**: Date picker
- **datetime**: Date and time picker
- **email**: Email address with validation
- **url**: URL with validation
- **password**: Masked text input
- **file**: File upload
- **json**: JSON editor with syntax validation
- **yaml**: YAML editor with syntax validation

### 3. Fulfillment Section

Defines how services are provisioned:

```yaml
fulfillment:
  manual:                      # Required: fallback process
    description: string        # Process overview
    actions:                   # Sequential actions
      - type: string          # Action type
        config: object        # Type-specific configuration
        
  automatic:                   # Optional: automation
    actions:                   # Sequential actions
      - type: string          # Action type
        config: object        # Configuration
        retry:                # Retry logic
          attempts: integer   # Max retries
          delay: integer      # Seconds between
        rollback:             # Failure recovery
          type: string        # Rollback action
          config: object      # Rollback config
```

## Action Types

### 1. JIRA Ticket Creation
```yaml
type: jira-ticket
config:
  project: string              # JIRA project key
  issue_type: string           # Issue type (Task, Story)
  summary_template: string     # Title with variables
  description_template: string # Body with variables
  assignee: string             # Optional assignee
  labels: [string]             # Issue labels
  custom_fields:               # Custom field mapping
    field_name: value
```

### 2. REST API Call
```yaml
type: rest-api
config:
  method: string               # HTTP method (GET, POST, PUT, DELETE)
  url: string                  # Endpoint URL
  headers:                     # HTTP headers
    key: value
  body_template: string        # Request body template
  authentication:              # Auth configuration
    type: string               # basic, bearer, oauth2
    config: object             # Auth-specific settings
  success_codes: [integer]     # Expected HTTP codes
  response_mapping:            # Extract response fields
    field: json_path
```

### 3. Terraform Generation
```yaml
type: terraform
config:
  repository: string           # Git repository
  branch: string               # Target branch
  path: string                 # Directory path
  module: string               # Terraform module
  variables:                   # Module inputs
    key: value_or_template
  backend:                     # State backend
    type: string
    config: object
```

### 4. GitHub Workflow Trigger
```yaml
type: github-workflow
config:
  repository: string           # GitHub repository
  workflow_id: string          # Workflow file/ID
  ref: string                  # Branch/tag/SHA
  inputs:                      # Workflow inputs
    key: value
```

### 5. Webhook
```yaml
type: webhook
config:
  url: string                  # Webhook URL
  method: string               # HTTP method
  headers: object              # HTTP headers
  body_template: string        # Body template
  signature:                   # HMAC signature
    algorithm: string          # Signature algorithm
    secret_ref: string         # Secret reference
```

## Variable Substitution System

Templates support variable interpolation using `{{variable_name}}` syntax:

- `{{fields.field_id}}` - User input values from presentation fields
- `{{header.id}}` - Catalog item metadata
- `{{request.id}}` - Unique request identifier
- `{{request.timestamp}}` - Request submission time
- `{{request.user}}` - Requesting user information
- `{{env.VARIABLE}}` - Environment variables
- `{{response.action_name.field}}` - Previous action responses

## Validation Requirements

1. **YAML Format**: All catalog items must be valid YAML within JSON-compatible subset
2. **No Complex YAML**: No anchors, aliases, or non-JSON types
3. **Required Sections**: `header`, `presentation`, and `fulfillment.manual` are mandatory
4. **Unique IDs**: All identifiers must be unique within scope
5. **Positive Orders**: Order values must be positive integers
6. **Valid References**: Field references must point to existing fields
7. **Action Dependencies**: Actions can reference previous action outputs

## Governance Model

### Contribution Process

1. **Branch Strategy**: Feature branches for new catalog items
2. **Naming Convention**: `{service-type}-{variant}.yaml` (e.g., `container-app-standard.yaml`)
3. **Validation**: Automated schema validation on all PRs
4. **Review**: Platform team owner approval required
5. **Documentation**: Category README must be updated

### Quality Standards

- Clear, user-friendly field names and descriptions
- Comprehensive validation to prevent runtime errors
- Complete manual fulfillment instructions
- Error handling and rollback procedures for automation
- Realistic and measurable SLA commitments

### Version Management

- Semantic versioning for all catalog items
- Breaking changes require major version increment
- Backward compatibility maintained when possible
- Migration guides for breaking changes

## Example: Container Application Service

```yaml
header:
  id: compute-container-app
  name: Container Application
  description: Deploy a containerized application to Kubernetes
  version: 1.0.0
  category: compute
  owner: platform-compute-team
  tags: [container, kubernetes, microservice]
  sla:
    provisioning_time: 2 hours
    support_level: tier-1

presentation:
  groups:
    - id: basic
      name: Basic Configuration
      order: 1
      fields:
        - id: app_name
          name: Application Name
          type: string
          order: 1
          required: true
          validation:
            pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
            
        - id: environment
          name: Environment
          type: selection
          order: 2
          required: true
          validation:
            enum: [development, staging, production]
            
        - id: container_image
          name: Container Image
          type: string
          order: 3
          required: true

    - id: resources
      name: Resource Configuration
      order: 2
      fields:
        - id: cpu_request
          name: CPU Cores
          type: number
          order: 1
          required: true
          default: 0.5
          validation:
            min: 0.1
            max: 4

fulfillment:
  manual:
    description: Manual provisioning via JIRA
    actions:
      - type: jira-ticket
        config:
          project: PLATFORM
          issue_type: Task
          summary_template: "Deploy {{fields.app_name}} to {{fields.environment}}"
          description_template: |
            Application: {{fields.app_name}}
            Environment: {{fields.environment}}
            Image: {{fields.container_image}}
            CPU: {{fields.cpu_request}} cores
            
  automatic:
    actions:
      - type: terraform
        config:
          repository: platform-infrastructure
          branch: main
          path: "environments/{{fields.environment}}/apps"
          module: kubernetes-deployment
          variables:
            name: "{{fields.app_name}}"
            image: "{{fields.container_image}}"
            cpu_request: "{{fields.cpu_request}}"
```

## Implementation Strategy

### Phase 1: Foundation
- Establish repository structure
- Define and validate schema
- Create initial templates
- Set up CI/CD validation

### Phase 2: Platform Onboarding
- Migrate existing manual processes
- Create catalog items for each platform team
- Establish review and approval workflows
- Document team-specific patterns

### Phase 3: Progressive Automation
- Start with manual JIRA fulfillment
- Gradually add automated actions
- Implement retry and rollback logic
- Monitor success rates

### Phase 4: Integration
- Connect to developer portal
- Implement real-time synchronization
- Add request tracking
- Enable status notifications

## Best Practices

### For Platform Teams
1. **Start Simple**: Begin with manual fulfillment, automate incrementally
2. **User Focus**: Design presentation layer for developer experience
3. **Clear Documentation**: Provide comprehensive field descriptions
4. **Validation First**: Prevent errors through proper validation
5. **Monitor Usage**: Track adoption and success metrics

### For Catalog Design
1. **Consistent Naming**: Use clear, consistent field identifiers
2. **Logical Grouping**: Organize fields into intuitive groups
3. **Progressive Disclosure**: Use conditional fields for advanced options
4. **Sensible Defaults**: Provide good defaults for optional fields
5. **Error Messages**: Write helpful validation error messages

### For Automation
1. **Idempotency**: Ensure actions can be safely retried
2. **Error Handling**: Plan for failure scenarios
3. **Rollback Strategy**: Define recovery procedures
4. **State Tracking**: Maintain accurate state information
5. **Audit Trail**: Log all actions for troubleshooting

## Success Metrics

- **Provisioning Time**: Reduce from weeks to hours
- **Automation Rate**: 95% of common services automated
- **Catalog Coverage**: All platform teams represented
- **Developer Satisfaction**: Measured through surveys
- **Error Rate**: Less than 5% fulfillment failures

## Security Considerations

1. **Secret Management**: Never store secrets in catalog items
2. **Access Control**: RBAC for catalog modifications
3. **Audit Logging**: Track all catalog changes
4. **Input Validation**: Prevent injection attacks
5. **Encryption**: Secure sensitive configuration data

## Migration Path

For existing services:
1. Document current manual process
2. Create catalog item with manual fulfillment
3. Test with pilot users
4. Add automation incrementally
5. Monitor and optimize

## Conclusion

This Orchestrator Catalog Repository design provides a robust, extensible foundation for the Platform Automation Orchestrator. By standardizing service definitions while allowing progressive enhancement, it enables platform teams to modernize at their own pace while delivering immediate value to developers through a unified self-service experience.