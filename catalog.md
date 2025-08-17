# Platform Automation Orchestrator - Catalog Repository

## Table of Contents

- [Repository Structure](#repository-structure)
  - [CODEOWNERS Configuration](#codeowners-configuration)
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
- [Validation and Testing](#validation-and-testing)
  - [Validation System](#validation-system)
  - [Testing Process](#testing-process)
  - [CI/CD Integration](#cicd-integration)

## Repository Structure

```
orchestrator-catalog-repo/
├── catalog/                    # Service definitions by category
│   ├── {category}/            # compute, databases, etc.
│   │   └── {service}.yaml     # Your service definition
├── schema/                     # JSON Schema specifications
│   ├── catalog-item-v2.json  # CatalogItem schema
│   ├── catalog-bundle-v2.json # CatalogBundle schema
│   └── common-types.json     # Shared type definitions
├── templates/                  # Starter templates for new services
├── scripts/                    # Validation and testing tools
│   ├── validate-catalog.sh   # Main validation script
│   ├── validate-all.sh       # Batch validation
│   └── test-template.sh      # Template testing
├── tests/                      # Test fixtures and examples
│   ├── valid/                 # Valid examples
│   └── invalid/               # Invalid examples with expected errors
└── .github/
    ├── workflows/             # CI/CD pipelines
    │   └── validate-catalog.yml # PR validation workflow
    └── CODEOWNERS             # Team ownership mapping
```

### CODEOWNERS Configuration

The repository uses GitHub's CODEOWNERS file to enforce team-based access control. Platform teams own and maintain their domain-specific services, while the Developer Experience team requires access across all domains to assist with catalog integration and troubleshooting.

**Access Control Strategy:**
- **Platform Teams**: Own their specific domain folders and service definitions
- **Developer Experience Team**: Requires access across all domains for catalog integration support
- **Architecture Team**: Owns the schema specifications and overall catalog design

Example `.github/CODEOWNERS` file:
```
# Default owners for everything in the repo
# Developer Experience team needs access to help all teams with catalog integration
*                                   @company/devx-team

# Schema and templates are owned by architecture team
/schema/                            @company/platform-architecture @company/devx-team
/templates/                         @company/platform-architecture @company/devx-team

# Platform teams own their respective catalog folders
# Each team can only modify services in their domain
/catalog/compute/                   @company/platform-compute-team @company/devx-team
/catalog/databases/                 @company/platform-database-team @company/devx-team
/catalog/messaging/                 @company/platform-messaging-team @company/devx-team
/catalog/networking/                @company/platform-networking-team @company/devx-team
/catalog/storage/                   @company/platform-storage-team @company/devx-team
/catalog/security/                  @company/platform-security-team @company/devx-team
/catalog/monitoring/                @company/platform-observability-team @company/devx-team

# Bundle definitions require architecture review
/catalog/solutions/                 @company/platform-architecture @company/devx-team

# CI/CD and validation scripts
/scripts/                           @company/devx-team
/.github/                           @company/devx-team
```

This configuration ensures:
1. Platform teams have autonomy over their services
2. DevX team can provide support across all domains
3. Schema changes require architecture review
4. No single team can accidentally break another team's services

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

- **Terraform Module Names**: Use **snake_case** for HCL compatibility
  - Transform field values when creating Terraform module identifiers
  - Example: `{{fields.appName}}` → `module "app_{{replace(fields.appName, '-', '_')}}"`
  - Module paths follow organization standards: `../modules/category/module_name`
  - Note: Templates primarily instantiate existing modules rather than defining resources

These conventions align with Go language standards and cloud-native tooling (Kubernetes, Helm, etc.) for optimal compatibility. Terraform identifiers require special handling to ensure valid HCL syntax.

## Schema Reference

**Important Note on Error Handling**: The catalog documents do not specify error handling behavior. All error handling, retry logic, and recovery mechanisms are the responsibility of the orchestrator service. When any action fails during execution, the service stops and requires manual intervention. Future phases may introduce automated recovery, but this is not part of the catalog specification.

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
            # Instantiate the centrally-managed EKS application module
            module "app_{{replace(fields.appName, '-', '_')}}" {
              source = "../modules/compute/eks_application"
              
              application_name = "{{fields.appName}}"
              container_image  = "{{fields.containerImage}}"
              replica_count    = {{fields.replicas}}
              namespace        = "{{fields.namespace}}"
              
              # Module handles all the complex EKS configuration
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
            # Use the organization's standard PostgreSQL RDS module
            module "db_{{replace(fields.instanceName, '-', '_')}}" {
              source = "../modules/data/postgresql_rds"
              
              instance_name     = "{{fields.instanceName}}"
              instance_class    = "{{fields.instanceClass}}"
              allocated_storage = {{fields.storageSize}}
              
              # Additional standard configurations handled by the module
              backup_retention_period = 7
              multi_az               = true
            }
            
            # Output values for use by other services
            output "db_connection_string" {
              value = module.db_{{replace(fields.instanceName, '-', '_')}}.connection_string
            }
            
            output "db_endpoint" {
              value = module.db_{{replace(fields.instanceName, '-', '_')}}.endpoint
            }
          outputs:
            - connectionString: "db_connection_string"
            - endpoint: "db_endpoint"
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
            # Use the organization's secrets management module
            module "secrets_{{replace(fields.secretName, '/', '_')}}" {
              source = "../modules/security/parameter_store"
              
              parameter_path = "/{{fields.secretName}}"
              secrets        = {{json(fields.secrets)}}
              
              # Module handles encryption and access policies
            }
            
            output "secret_arn" {
              value = module.secrets_{{replace(fields.secretName, '/', '_')}}.parameter_arn
            }
          outputs:
            - secretArn: "secret_arn"
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

**Note on Terraform Actions**: The Terraform action type generates small template files (`.tf`) that primarily instantiate pre-built, centrally-managed Terraform modules. These modules are maintained in separate infrastructure repositories and handle the complex implementation details. The catalog templates simply pass parameters to these modules, keeping the orchestrator focused on configuration rather than infrastructure implementation.

### 1. JIRA Ticket
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
  # Template generates a .tf file that instantiates pre-built modules
  # Assumes external Terraform modules exist in the infrastructure repository
  contentTemplate: |
    module "instance_{{replace(fields.name, '-', '_')}}" {
      source = "../modules/compute/ec2_instance"
      
      name          = "{{fields.name}}"
      instance_type = "{{fields.instanceType}}"
      environment   = "{{fields.environment}}"
      tags          = {{json(fields.tags)}}
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

## Validation and Testing

### Validation System

The catalog repository includes a comprehensive validation system to ensure all service definitions conform to the schema specifications. This system operates at multiple levels to catch errors before they reach the orchestrator service.

**Validation Components:**

1. **JSON Schema Definitions** (`/schema/` directory)
   - `catalog-item-v2.json` - Schema for individual service definitions
   - `catalog-bundle-v2.json` - Schema for composite service bundles
   - `common-types.json` - Shared type definitions and constraints

2. **Validation Scripts** (`/scripts/` directory)
   - `validate-catalog.sh` - Main validation script
   - `validate-single.sh` - Validates individual YAML files
   - `validate-all.sh` - Batch validation for entire directories

3. **Test Fixtures** (`/tests/` directory)
   - Valid examples that should pass validation
   - Invalid examples with expected error messages
   - Edge cases for comprehensive testing

**What Gets Validated:**

- **Structural Compliance**: YAML structure matches schema requirements
- **Naming Conventions**: All identifiers follow specified patterns (camelCase, kebab-case, etc.)
- **Required Fields**: All mandatory fields are present with valid values
- **Type Constraints**: Field values match their declared types
- **Template Syntax**: Variable references use correct scope and syntax
- **Cross-References**: Bundle components reference existing CatalogItems
- **Action Configurations**: Each action type has required parameters

### Testing Process

Platform teams follow a structured testing process before submitting catalog changes:

**Local Validation Workflow:**

```bash
# 1. Validate a single service definition
./scripts/validate-catalog.sh catalog/databases/postgresql-standard.yaml

# 2. Validate all services in a category
./scripts/validate-catalog.sh catalog/databases/

# 3. Run comprehensive validation before commit
./scripts/validate-all.sh

# 4. Test with sample data (dry run)
./scripts/test-template.sh catalog/databases/postgresql-standard.yaml sample-data.json
```

**Validation Output:**

The validation scripts provide clear, actionable feedback:
- **Success**: Green checkmark with "Valid" status
- **Errors**: Red X with specific error location (file:line:column)
- **Warnings**: Yellow warning for non-critical issues
- **Suggestions**: Blue info markers for improvements

Example error output:
```
✗ catalog/databases/postgresql-invalid.yaml
  Line 15: Field 'instanceClass' should use camelCase (found: instance_class)
  Line 22: Missing required field 'manual.actions'
  Line 38: Invalid variable reference '{{field.name}}' (should be '{{fields.name}}')
```

### CI/CD Integration

All catalog changes are automatically validated through GitHub Actions before merge.

**Pull Request Validation** (`.github/workflows/validate-catalog.yml`):

```yaml
name: Validate Catalog
on:
  pull_request:
    paths:
      - 'catalog/**'
      - 'schema/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup validation environment
        run: |
          npm install -g ajv-cli
          pip install pyyaml jsonschema
      
      - name: Validate changed files
        run: |
          ./scripts/validate-changed.sh ${{ github.event.pull_request.base.sha }}
      
      - name: Run integration tests
        run: |
          ./scripts/integration-test.sh
      
      - name: Post validation results
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            // Post validation results as PR comment
```

**Merge Protection:**

- Pull requests cannot merge without passing validation
- CODEOWNERS approval required for respective domain changes
- Schema changes trigger additional architecture review
- Breaking changes require major version bump

**Continuous Validation:**

A nightly job validates the entire catalog to catch any drift or corruption:
```bash
# Runs at 2 AM UTC daily
0 2 * * * ./scripts/validate-all.sh --report-to-slack
```

This comprehensive validation system ensures catalog integrity while allowing teams to work independently within their domains.