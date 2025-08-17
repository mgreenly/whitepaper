# Platform Automation Orchestrator - Catalog Repository

## Table of Contents

- [Repository Structure](#repository-structure)
- [Naming Conventions](#naming-conventions)
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

## Naming Conventions

**Important**: This catalog uses specific naming conventions to ensure consistency and compatibility with the Go-based orchestrator service:

- **Type Names** (`kind` field): Use **PascalCase**
  - Examples: `CatalogItem`, `CatalogBundle`
  
- **Field Names**: Use **camelCase**
  - Examples: `catalogItem`, `instanceClass`, `contentTemplate`, `issueType`
  
- **File Names**: Use **kebab-case**
  - Examples: `database-postgresql-standard.yaml`, `compute-eks-containerapp.yaml`
  
- **IDs and References**: Use **kebab-case**
  - Examples: `database-postgresql-standard`, `bundle-webapp-production`

- **Terraform Resource/Module Names**: Use **snake_case** for HCL compatibility
  - Transform field values when creating Terraform identifiers
  - Example: `{{fields.appName}}` → `module "eks_app_{{replace(fields.appName, '-', '_')}}"`
  - Built-in modules should use underscores: `./modules/eks_app` not `./modules/eks-app`

These conventions align with Go language standards and cloud-native tooling (Kubernetes, Helm, etc.) for optimal compatibility. Terraform identifiers require special handling to ensure valid HCL syntax.

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
            issueType: Task
            summaryTemplate: "Provision {{fields.name}}"
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
    catalogItem: database-postgresql-standard
    config:
      instanceClass: "{{fields.dbSize}}"
      storageSize: "{{fields.dbStorage}}"
    outputs:
      - connectionString
      - host
      - port
  
  - id: secrets
    catalogItem: security-parameterstore-standard
    config:
      secretName: "{{fields.appName}}-secrets"
      secrets:
        - key: dbConnectionString
          value: "{{components.database.outputs.connectionString}}"
    outputs:
      - secretArn
  
  - id: application
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]
    config:
      appName: "{{fields.appName}}"
      containerImage: "{{fields.containerImage}}"
      replicas: "{{fields.replicas}}"
      environmentVariables:
        - name: DB_CONNECTION_SECRET
          value: "{{components.secrets.outputs.secretArn}}"

presentation:
  form:
    groups:
      - id: appConfig
        name: Application Configuration
        fields:
          - id: appName
            name: Application Name
            type: string
            required: true
          - id: containerImage
            name: Container Image
            type: string
            required: true
          - id: replicas
            name: Number of Replicas
            type: number
            default: 2
      
      - id: databaseConfig
        name: Database Configuration
        fields:
          - id: dbSize
            name: Database Size
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: dbStorage
            name: Storage (GB)
            type: number
            default: 100

fulfillment:
  orchestration:
    mode: sequential  # or parallel where dependencies allow
    errorHandling: stop  # stop, rollback, or continue
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
          - id: appName
            type: string
            required: true
          - id: containerImage
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
            summaryTemplate: "Deploy {{fields.appName}} to EKS"
  automatic:
    actions:
      - type: terraform
        config:
          contentTemplate: |
            module "eks_app_{{replace(fields.appName, '-', '_')}}" {
              source = "./modules/eks_app"
              name = "{{fields.appName}}"  # Keep original for display
              image = "{{fields.containerImage}}"
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
          - id: instanceName
            type: string
            required: true
          - id: instanceClass
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: storageSize
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
            summaryTemplate: "PostgreSQL: {{fields.instanceName}}"
  automatic:
    actions:
      - type: terraform
        config:
          contentTemplate: |
            module "rds_{{replace(fields.instanceName, '-', '_')}}" {
              source = "terraform-aws-modules/rds/aws"
              identifier = "{{fields.instanceName}}"  # AWS allows dashes
              engine = "postgres"
              instance_class = "{{fields.instanceClass}}"
              allocated_storage = {{fields.storageSize}}
            }
          outputs:
            - connectionString: "module.rds_{{replace(fields.instanceName, '-', '_')}}.db_connection_string"
            - host: "module.rds_{{replace(fields.instanceName, '-', '_')}}.db_endpoint"
            - port: "module.rds_{{replace(fields.instanceName, '-', '_')}}.db_port"
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
          - id: secretName
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
            summaryTemplate: "Create secrets: {{fields.secretName}}"
  automatic:
    actions:
      - type: terraform
        config:
          contentTemplate: |
            resource "aws_ssm_parameter" "{{replace(fields.secretName, '/', '_')}}" {
              name  = "/{{fields.secretName}}"  # Path format preserved
              type  = "SecureString"
              value = jsonencode({{json(fields.secrets)}})
            }
          outputs:
            - secretArn: "aws_ssm_parameter.{{replace(fields.secretName, '/', '_')}}.arn"
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
    catalogItem: database-postgresql-standard
    config:
      instanceName: "{{fields.appName}}-db"
      instanceClass: "{{fields.dbSize}}"
      storageSize: "{{fields.dbStorage}}"
    
  - id: secrets
    catalogItem: security-parameterstore-standard
    config:
      secretName: "{{fields.appName}}/secrets"
      secrets:
        - key: dbHost
          value: "{{components.database.outputs.host}}"
        - key: dbPort
          value: "{{components.database.outputs.port}}"
    
  - id: app
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]
    config:
      appName: "{{fields.appName}}"
      containerImage: "{{fields.containerImage}}"
      replicas: "{{fields.replicas}}"
      environmentVariables:
        - name: PARAM_STORE_PATH
          value: "{{components.secrets.outputs.secretArn}}"

presentation:
  form:
    groups:
      - id: application
        name: Application Settings
        fields:
          - id: appName
            name: Application Name
            type: string
            required: true
            validation:
              pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
          - id: containerImage
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
          - id: dbSize
            name: Database Size
            type: select
            required: true
            enum: [db.t3.small, db.t3.medium, db.t3.large]
            default: db.t3.medium
          - id: dbStorage
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
    errorHandling: stop
    rollbackOnFailure: true
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
    summaryTemplate: "{{fields.name}} request"
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
    contentTemplate: '{"name": "{{fields.name}}"}'
```

### 3. Terraform
```yaml
type: terraform
config:
  contentTemplate: |
    resource "aws_instance" "{{replace(fields.name, '-', '_')}}" {
      instance_type = "{{fields.instanceType}}"
    }
  filename: "{{replace(fields.name, '-', '_')}}.tf"
  repositoryMapping: "terraform_infrastructure"
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
    resourceName: "{{fields.name}}"
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
| **Output** | `{{output.actionId.field}}` | Previous action outputs |

### Functions

Built-in functions for data transformation:

- `{{uuid()}}` - Generate UUID
- `{{timestamp()}}` - Current timestamp
- `{{upper(string)}}` - Uppercase conversion
- `{{concat(str1, str2)}}` - String concatenation
- `{{replace(string, old, new)}}` - String replacement (useful for Terraform names)
- `{{json(object)}}` - JSON encoding
- `{{base64(string)}}` - Base64 encoding