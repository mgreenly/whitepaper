# Platform Automation Orchestrator - Catalog Repository

## Table of Contents

- [Repository Structure](#repository-structure)
- [Schema Reference](#schema-reference)
  - [Minimal Service Definition](#minimal-service-definition)
- [Field Types](#field-types)
- [Action Types](#action-types)
- [Templates and Variables](#templates-and-variables)
  - [Variable System](#variable-system)
  - [Functions](#functions)
  - [Conditionals](#conditionals)

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

## Field Types

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

## Action Types

### 1. JIRA Ticket (Manual Fallback)
```yaml
type: jira-ticket
config:
  ticket:
    project: PLATFORM
    summary_template: "{{fields.name}} request"
```

### 2. REST API
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

### 3. Terraform
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

### 4. GitHub Workflow
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

### 5. Webhook
```yaml
type: webhook
config:
  endpoint:
    url: "{{env.WEBHOOK_URL}}"
    method: POST
  body:
    template: '{"resource": "{{fields.name}}"}'
```

## Templates and Variables

### Variable System

Variables allow dynamic content insertion throughout catalog definitions. Variables are replaced at runtime when requests are processed.

| Scope | Example | Description |
|-------|---------|-------------|
| **User Input** | `{{fields.name}}` | Form field values submitted by users |
| **Metadata** | `{{metadata.id}}` | Service metadata from catalog definition |
| **Request** | `{{request.user.email}}` | Request context information |
| **System** | `{{system.date}}` | System-generated variables |
| **Environment** | `{{env.API_KEY}}` | Environment variables from orchestrator |
| **Secrets** | `{{secrets.DB_PASSWORD}}` | Secret values from vault |
| **Output** | `{{output.action_id.field}}` | Previous action outputs |

### Functions

Built-in functions for data transformation:

- `{{uuid()}}` - Generate UUID
- `{{timestamp()}}` - Current timestamp
- `{{upper(string)}}` - Uppercase conversion
- `{{concat(str1, str2)}}` - String concatenation
- `{{json(object)}}` - JSON encoding
- `{{base64(string)}}` - Base64 encoding

### Conditionals

Conditional logic for dynamic behavior:

```yaml
{{#if fields.environment == "production"}}
  priority: high
{{else}}
  priority: normal
{{/if}}
```