# Orchestrator Catalog Repository

## Overview

This repository serves as the central document store for the Platform Automation Orchestrator (PAO), where platform teams define their service offerings through structured YAML documents. These catalog items are consumed by the orchestrator to generate a unified service catalog and automate service fulfillment.

## Repository Structure

```
/
├── README.md                 # Repository overview and quick start guide
├── repo.md                  # This file - detailed documentation
├── schema/                  # JSON schemas for validation
│   └── catalog-item.schema.yaml
├── catalog/                 # Service catalog definitions
│   ├── README.md           # Catalog overview and categories
│   ├── compute/            # Compute services
│   │   └── README.md
│   ├── databases/          # Database services
│   │   └── README.md
│   ├── messaging/          # Messaging and event services
│   │   └── README.md
│   ├── networking/         # Network services
│   │   └── README.md
│   ├── storage/            # Storage services
│   │   └── README.md
│   ├── security/           # Security services
│   │   └── README.md
│   ├── monitoring/         # Monitoring and observability
│   │   └── README.md
│   └── other/              # Miscellaneous services
│       └── README.md
├── templates/              # Example templates
│   └── catalog-item.template.yaml
└── .github/
    └── workflows/          # CI/CD for validation
        └── validate.yaml
```

## Catalog Item Schema

Each catalog item is defined in a YAML file with the following structure:

### Root Structure
```yaml
# Required: Metadata about the catalog item
header:
  id: string                    # Unique identifier (e.g., "compute-container-app")
  name: string                  # Display name
  description: string           # Service description
  version: string               # Schema version (e.g., "1.0.0")
  category: string              # Category (compute, databases, etc.)
  owner: string                 # Platform team owner
  tags: [string]                # Optional tags for search/filtering
  sla:                          # Optional SLA definitions
    provisioning_time: string   # Expected provisioning time (e.g., "2 hours")
    support_level: string       # Support tier (e.g., "tier-1", "tier-2")

# Required: User interface definition
presentation:
  groups:                       # Logical groupings of fields
    - id: string                # Group identifier
      name: string              # Display name
      description: string       # Group description
      order: integer            # Display order (1-based)
      collapsible: boolean      # Optional: Can group be collapsed
      fields:                   # Fields within the group
        - id: string            # Field identifier
          name: string          # Display label
          description: string   # Help text
          type: string          # Field type (see Field Types below)
          order: integer        # Display order within group
          required: boolean     # Is field required
          default: any          # Optional default value
          validation:           # Optional validation rules
            pattern: string     # Regex pattern for strings
            min: number         # Minimum value/length
            max: number         # Maximum value/length
            enum: [any]         # Allowed values for selection
          conditional:          # Optional conditional display
            field: string       # Field ID to check
            operator: string    # Comparison operator (eq, ne, gt, lt, in)
            value: any          # Value to compare against

# Required: Service fulfillment definition
fulfillment:
  manual:                       # Required: Manual fulfillment process
    description: string         # Overview of manual process
    actions:                    # Sequential list of actions
      - type: string            # Action type (see Action Types below)
        config: object          # Type-specific configuration
        
  automatic:                    # Optional: Automated fulfillment
    actions:                    # Sequential list of actions
      - type: string            # Action type
        config: object          # Type-specific configuration
        retry:                  # Optional retry configuration
          attempts: integer     # Number of retry attempts
          delay: integer        # Delay between retries (seconds)
        rollback:               # Optional rollback action
          type: string
          config: object
```

### Field Types

The presentation layer supports the following field types:

- **string**: Single-line text input
- **text**: Multi-line text input
- **integer**: Whole number input
- **number**: Decimal number input
- **boolean**: Checkbox/toggle
- **selection**: Single choice from list
- **multi-selection**: Multiple choices from list
- **date**: Date picker
- **datetime**: Date and time picker
- **email**: Email address input
- **url**: URL input
- **password**: Masked text input
- **file**: File upload
- **json**: JSON editor
- **yaml**: YAML editor

### Action Types

Actions define how services are fulfilled:

#### 1. JIRA Ticket (`jira-ticket`)
```yaml
type: jira-ticket
config:
  project: string               # JIRA project key
  issue_type: string            # Issue type (Story, Task, etc.)
  summary_template: string      # Title template with variables
  description_template: string  # Description template
  assignee: string              # Optional assignee
  labels: [string]              # Optional labels
  custom_fields:                # Custom field mappings
    field_name: value
```

#### 2. REST API Call (`rest-api`)
```yaml
type: rest-api
config:
  method: string                # HTTP method (GET, POST, PUT, DELETE)
  url: string                   # API endpoint URL
  headers:                      # Optional headers
    key: value
  body_template: string         # Request body template
  authentication:               # Optional auth config
    type: string                # basic, bearer, oauth2
    config: object              # Auth-specific config
  success_codes: [integer]      # Expected success HTTP codes
  response_mapping:             # Optional response field mapping
    field: json_path
```

#### 3. Terraform Generation (`terraform`)
```yaml
type: terraform
config:
  repository: string            # Target Git repository
  branch: string                # Target branch
  path: string                  # Path within repository
  module: string                # Terraform module to use
  variables:                    # Module variables
    key: value_or_template
  backend:                      # Optional backend config
    type: string
    config: object
```

#### 4. GitHub Workflow (`github-workflow`)
```yaml
type: github-workflow
config:
  repository: string            # GitHub repository
  workflow_id: string           # Workflow file name or ID
  ref: string                   # Branch/tag/SHA
  inputs:                       # Workflow input parameters
    key: value
```

#### 5. Webhook (`webhook`)
```yaml
type: webhook
config:
  url: string                   # Webhook URL
  method: string                # HTTP method
  headers: object               # Optional headers
  body_template: string         # Body template
  signature:                    # Optional signature config
    algorithm: string           # HMAC algorithm
    secret_ref: string          # Secret reference
```

## Variable Substitution

Templates support variable substitution using `{{variable_name}}` syntax:

- `{{fields.field_id}}`: User input from presentation fields
- `{{header.id}}`: Catalog item metadata
- `{{request.id}}`: Unique request identifier
- `{{request.timestamp}}`: Request timestamp
- `{{request.user}}`: Requesting user information
- `{{env.VARIABLE}}`: Environment variables

## Validation Rules

1. **File Format**: All catalog items must be valid YAML files with `.yaml` extension
2. **JSON Compatibility**: YAML must be within the JSON-compatible subset (no anchors, aliases, or complex types)
3. **Required Fields**: `header`, `presentation`, and `fulfillment.manual` are mandatory
4. **Unique IDs**: All IDs must be unique within their scope
5. **Order Values**: Order values must be positive integers
6. **Field References**: Conditional and variable references must point to existing fields

## Governance

### Contribution Process

1. **Branch Strategy**: Create feature branches for new catalog items
2. **Naming Convention**: Files named as `{service-type}-{variant}.yaml` (e.g., `container-app-standard.yaml`)
3. **Validation**: All PRs must pass schema validation
4. **Review**: Platform team owner approval required for their category
5. **Documentation**: README in category folder must be updated

### Quality Standards

- Clear, descriptive field names and help text
- Comprehensive validation rules to prevent errors
- Manual fulfillment instructions must be complete and actionable
- Automated actions must include error handling and rollback procedures
- SLA commitments must be realistic and measurable

### Version Management

- Use semantic versioning for catalog items
- Breaking changes require major version bump
- Maintain backward compatibility when possible
- Document migration path for breaking changes

## Examples

### Simple Container Application
```yaml
header:
  id: compute-container-app-simple
  name: Container Application
  description: Deploy a containerized application to our platform
  version: 1.0.0
  category: compute
  owner: platform-compute-team
  tags: [container, kubernetes, application]
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
          description: Full container image path (e.g., myregistry.io/app:tag)

fulfillment:
  manual:
    description: Manual provisioning via JIRA ticket
    actions:
      - type: jira-ticket
        config:
          project: PLATFORM
          issue_type: Task
          summary_template: "Provision Container App: {{fields.app_name}}"
          description_template: |
            Please provision a new container application:
            - Name: {{fields.app_name}}
            - Environment: {{fields.environment}}
            - Image: {{fields.container_image}}
            
  automatic:
    actions:
      - type: terraform
        config:
          repository: platform-infrastructure
          branch: main
          path: environments/{{fields.environment}}/apps
          module: container-app
          variables:
            name: "{{fields.app_name}}"
            image: "{{fields.container_image}}"
```

## Best Practices

1. **Start Simple**: Begin with manual fulfillment and evolve to automation
2. **User-Centric Design**: Focus on developer experience in presentation layer
3. **Progressive Enhancement**: Add fields and automation incrementally
4. **Error Messages**: Provide clear, actionable error messages
5. **Documentation**: Maintain comprehensive documentation for each service
6. **Testing**: Include test cases for both presentation and fulfillment
7. **Monitoring**: Define success metrics and monitoring for automated fulfillment

## Support

For questions or issues:
- Create an issue in this repository
- Contact the Platform Team via Slack: #platform-support
- Review the FAQ in the wiki