# Platform Automation Orchestrator - Catalog Repository

## Table of Contents

- [Repository Structure](#repository-structure)
- [Schema Reference](#schema-reference)
  - [CatalogItem - Individual Service](#catalogitem---individual-service)
  - [CatalogBundle - Composite Service](#catalogbundle---composite-service)
  - [Example Bundle Components](#example-catalogitems-for-bundle-components)
- [Field Types](#field-types)
- [Action Types](#action-types)
- [Templates and Variables](#templates-and-variables)
  - [Variable System](#variable-system)
  - [Functions](#functions)

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

### CatalogItem - Individual Service

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

### CatalogBundle - Composite Service

A CatalogBundle combines multiple CatalogItems into a single deployable solution. It orchestrates the provisioning of multiple services with proper dependency management and variable passing between components.

```yaml
kind: CatalogBundle

metadata:
  id: bundle-{solution}-{variant}  # e.g., bundle-webapp-standard
  name: Display Name
  description: Complete solution description
  version: 1.0.0
  category: solutions
  owner:
    team: platform-architecture-team
    contact: architecture@company.com

components:
  - id: database
    catalog_item: database-postgresql-standard
    config:
      instance_class: "{{fields.db_size}}"
      storage_size: "{{fields.db_storage}}"
    outputs:
      - connection_string
      - host
      - port
  
  - id: secrets
    catalog_item: security-parameterstore-standard
    config:
      secret_name: "{{fields.app_name}}-secrets"
      secrets:
        - key: db_connection_string
          value: "{{components.database.outputs.connection_string}}"
    outputs:
      - secret_arn
  
  - id: application
    catalog_item: compute-eks-containerapp
    depends_on: [database, secrets]
    config:
      app_name: "{{fields.app_name}}"
      container_image: "{{fields.container_image}}"
      replicas: "{{fields.replicas}}"
      environment_variables:
        - name: DB_CONNECTION_SECRET
          value: "{{components.secrets.outputs.secret_arn}}"

presentation:
  form:
    groups:
      - id: app_config
        name: Application Configuration
        fields:
          - id: app_name
            name: Application Name
            type: string
            required: true
          - id: container_image
            name: Container Image
            type: string
            required: true
          - id: replicas
            name: Number of Replicas
            type: number
            default: 2
      
      - id: database_config
        name: Database Configuration
        fields:
          - id: db_size
            name: Database Size
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: db_storage
            name: Storage (GB)
            type: number
            default: 100

fulfillment:
  orchestration:
    mode: sequential  # or parallel where dependencies allow
    error_handling: stop  # stop, rollback, or continue
```

### Example CatalogItems for Bundle Components

#### EKS Container Application
```yaml
kind: CatalogItem

metadata:
  id: compute-eks-containerapp
  name: EKS Container Application
  description: Deploy containerized application to EKS cluster
  version: 1.0.0
  category: compute

presentation:
  form:
    groups:
      - id: basic
        fields:
          - id: app_name
            type: string
            required: true
          - id: container_image
            type: string
            required: true
          - id: replicas
            type: number
            default: 2

fulfillment:
  strategy:
    mode: automatic
  manual:
    actions:
      - type: jira-ticket
        config:
          ticket:
            project: COMPUTE
            summary_template: "Deploy {{fields.app_name}} to EKS"
  automatic:
    actions:
      - type: terraform
        config:
          content_template: |
            module "eks_app_{{fields.app_name}}" {
              source = "./modules/eks-app"
              name = "{{fields.app_name}}"
              image = "{{fields.container_image}}"
              replicas = {{fields.replicas}}
            }
```

#### PostgreSQL Database
```yaml
kind: CatalogItem

metadata:
  id: database-postgresql-standard
  name: PostgreSQL Database
  description: Managed PostgreSQL instance with backups
  version: 1.0.0
  category: databases

presentation:
  form:
    groups:
      - id: config
        fields:
          - id: instance_name
            type: string
            required: true
          - id: instance_class
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: storage_size
            type: number

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
      - type: terraform
        config:
          content_template: |
            module "rds_{{fields.instance_name}}" {
              source = "terraform-aws-modules/rds/aws"
              identifier = "{{fields.instance_name}}"
              engine = "postgres"
              instance_class = "{{fields.instance_class}}"
              allocated_storage = {{fields.storage_size}}
            }
          outputs:
            - connection_string: "module.rds_{{fields.instance_name}}.connection_string"
            - host: "module.rds_{{fields.instance_name}}.endpoint"
            - port: "module.rds_{{fields.instance_name}}.port"
```

#### AWS Parameter Store
```yaml
kind: CatalogItem

metadata:
  id: security-parameterstore-standard
  name: AWS Parameter Store Secrets
  description: Secure secret storage in AWS Parameter Store
  version: 1.0.0
  category: security

presentation:
  form:
    groups:
      - id: config
        fields:
          - id: secret_name
            type: string
            required: true
          - id: secrets
            type: multiselect
            description: Key-value pairs to store

fulfillment:
  strategy:
    mode: automatic
  manual:
    actions:
      - type: jira-ticket
        config:
          ticket:
            project: SECURITY
            summary_template: "Create secrets: {{fields.secret_name}}"
  automatic:
    actions:
      - type: terraform
        config:
          content_template: |
            resource "aws_ssm_parameter" "{{fields.secret_name}}" {
              name  = "/{{fields.secret_name}}"
              type  = "SecureString"
              value = jsonencode({{json(fields.secrets)}})
            }
          outputs:
            - secret_arn: "aws_ssm_parameter.{{fields.secret_name}}.arn"
```

### Example Complete Bundle
```yaml
kind: CatalogBundle

metadata:
  id: bundle-webapp-production
  name: Production Web Application Stack
  description: Complete web application with database and secrets management
  version: 2.0.0
  category: solutions

components:
  - id: database
    catalog_item: database-postgresql-standard
    config:
      instance_name: "{{fields.app_name}}-db"
      instance_class: "{{fields.db_size}}"
      storage_size: "{{fields.db_storage}}"
    
  - id: secrets
    catalog_item: security-parameterstore-standard
    config:
      secret_name: "{{fields.app_name}}/secrets"
      secrets:
        - key: db_host
          value: "{{components.database.outputs.host}}"
        - key: db_port
          value: "{{components.database.outputs.port}}"
    
  - id: app
    catalog_item: compute-eks-containerapp
    depends_on: [database, secrets]
    config:
      app_name: "{{fields.app_name}}"
      container_image: "{{fields.container_image}}"
      replicas: "{{fields.replicas}}"
      environment_variables:
        - name: PARAM_STORE_PATH
          value: "{{components.secrets.outputs.secret_arn}}"

presentation:
  form:
    groups:
      - id: application
        name: Application Settings
        fields:
          - id: app_name
            name: Application Name
            type: string
            required: true
            validation:
              pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
          - id: container_image
            name: Docker Image
            type: string
            required: true
          - id: replicas
            name: Replicas
            type: number
            default: 3
            validation:
              min: 1
              max: 10
      
      - id: database
        name: Database Settings
        fields:
          - id: db_size
            name: Database Size
            type: select
            required: true
            enum: [db.t3.small, db.t3.medium, db.t3.large]
            default: db.t3.medium
          - id: db_storage
            name: Storage (GB)
            type: number
            required: true
            default: 100
            validation:
              min: 20
              max: 1000

fulfillment:
  orchestration:
    mode: sequential
    error_handling: stop
    rollback_on_failure: true
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