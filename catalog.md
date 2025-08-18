# Platform Automation Orchestrator - Catalog Repository

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Table of Contents

- [Repository Structure](#repository-structure)
  - [CODEOWNERS Configuration](#codeowners-configuration)
- [Naming Conventions](#naming-conventions)
- [Schema Reference](#schema-reference)
  - [CatalogBundle - Composite Service](#catalogbundle---composite-service)
  - [CatalogItem - Individual Service](#catalogitem---individual-service)
- [Field Types](#field-types)
- [Action Types](#action-types)
  - [JIRA Ticket](#1-jira-ticket)
  - [REST API](#2-rest-api)
  - [Future Action Types](#future-action-types)
- [Templates and Variables](#templates-and-variables)
  - [Variable System](#variable-system)
  - [Functions](#functions)
- [Examples](#examples)
  - [Complete Bundle Example](#complete-bundle-example)
  - [EKS Container Application](#eks-container-application)
  - [PostgreSQL Database](#postgresql-database)
  - [AWS Parameter Store](#aws-parameter-store)
- [Validation and Testing](#validation-and-testing)
  - [Validation System](#validation-system)
  - [Testing Process](#testing-process)
  - [CI/CD Integration](#cicd-integration)
- [Implementation Guidance](#implementation-guidance)

## Repository Structure

```
orchestrator-catalog-repo/
├── catalog/                    # Service definitions by category
│   ├── {category}/            # compute, databases, etc.
│   │   └── {service}.yaml     # Your service definition
├── schema/                     # JSON Schema specifications
│   ├── catalog-item.json      # CatalogItem schema
│   ├── catalog-bundle.json    # CatalogBundle schema
│   └── common-types.json      # Shared type definitions
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

**Q3 2025 Scope**: In Q3, all services use manual fulfillment via JIRA tickets. The `automatic` fulfillment sections shown in examples are for Q4 and beyond.

### CatalogBundle - Composite Service

A CatalogBundle combines multiple CatalogItems into a single deployable solution. It orchestrates the provisioning of multiple services with proper dependency management and variable passing between components.

**Q3 Bundle Behavior:**
In Q3, bundles create multiple JIRA tickets (one per component) and establish JIRA linking relationships based on the `dependsOn` configuration. The orchestrator:
1. Creates all component JIRA tickets using each CatalogItem's template
2. Adds JIRA issue links of type "blocks/is blocked by" based on dependencies
3. Returns a bundle request with links to all created tickets

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
    catalogItem: database-postgresql-standard  # References existing CatalogItem
    config:
      # Override default field values from the referenced CatalogItem
      instanceClass: "{{fields.dbSize}}"
      storageSize: "{{fields.dbStorage}}"
    outputs:  # Q4: Outputs for automated provisioning
      - connectionString
      - host
      - port
  
  - id: secrets
    catalogItem: security-parameterstore-standard
    dependsOn: [database]  # JIRA ticket will be linked as "blocked by" database ticket
    config:
      secretName: "{{fields.appName}}-secrets"
      secrets:
        # Q4: Will reference outputs; Q3: Manual instructions in JIRA
        - key: dbConnectionString
          value: "{{components.database.outputs.connectionString}}"
    outputs:
      - secretArn
  
  - id: application
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]  # Creates JIRA blocking links to both
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

fulfillment:
  orchestration:
    mode: sequential  # Components are processed in order
    jiraLinking:
      linkType: blocks  # JIRA link type for dependencies
      parentTicket: false  # Q3: No parent epic; Q4: Optional epic creation
```

### CatalogItem - Individual Service

```yaml
kind: CatalogItem

metadata:
  id: {category}-{service}-{variant}  # e.g., database-postgresql-standard
  name: Display Name
  description: 50-500 character description
  version: 1.0.0
  category: databases  # Must match a repository folder
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
  
  automatic:
    actions:
      - type: rest-api
        config:
          endpoint:
            url: "https://api.platform.internal/provision"
            method: POST
          body:
            type: json
            contentTemplate: |
              {
                "service": "{{metadata.id}}",
                "name": "{{fields.name}}"
              }
```

## Field Types

Fields define the user input interface. Each field type has specific validation and display characteristics:

| Type | Use Case | Validation | UI Element |
|------|----------|------------|------------|
| `string` | Text input | pattern, min/max length | Text field |
| `number` | Numeric values | min/max, step | Number input |
| `boolean` | Yes/No choices | - | Checkbox |
| `select` | Single choice | enum values | Dropdown |
| `multiselect` | Multiple choices | enum values | Multi-select |
| `date` | Date picker | min/max date | Date picker |
| `file` | File upload | size, type | File upload |
| `textarea` | Multi-line text | min/max length | Text area |
| `password` | Sensitive data | pattern, strength | Password field |
| `email` | Email addresses | format validation | Email input |

**Field Definition Structure:**
```yaml
fields:
  - id: fieldName           # Unique identifier (camelCase)
    name: Display Name      # User-friendly label
    type: string           # Field type from table above
    required: true         # Optional, default false
    default: "value"       # Optional default value
    description: "Help"    # Optional help text
    validation:            # Optional validation rules
      pattern: "^[a-z]+$"  # Regex for string types
      min: 1               # Minimum for numbers
      max: 100             # Maximum for numbers
      enum: [a, b, c]      # Allowed values for select types
```

## Action Types

**Current Implementation**: The Q3 2025 Foundation Epic supports JIRA and REST API action types. Additional action types (Terraform, GitHub Workflows) are planned for future releases.

### 1. JIRA Ticket

**Required Fields:**
- `project`: JIRA project key (e.g., PLATFORM, DBA, COMPUTE)
- `issueType`: Valid issue type for the project (e.g., Task, Story, Bug)
- `summaryTemplate`: Template for ticket summary (max 255 characters)

**Optional Fields:**
- `descriptionTemplate`: Detailed ticket description with variable substitution
- `priority`: Ticket priority (Critical, High, Medium, Low) - defaults to Medium
- `labels`: Array of labels to apply to the ticket
- `components`: JIRA components to assign
- `epicKey`: Epic to link this ticket to
- `customFields`: Map of custom field IDs to values

```yaml
type: jira-ticket
config:
  ticket:
    project: PLATFORM
    summaryTemplate: "{{fields.name}} request"
    descriptionTemplate: |
      Requesting: {{fields.name}}
      Type: {{metadata.name}}
      User: {{request.user.email}}
      Request ID: {{request.id}}
      
      Configuration:
      {{#each fields}}
      - {{@key}}: {{this}}
      {{/each}}
    issueType: Task
    priority: "{{fields.priority}}"
    labels:
      - platform-automation
      - "{{metadata.category}}"
    customFields:
      customfield_10001: "{{fields.costCenter}}"
      customfield_10002: "{{fields.environment}}"
```

**Variable Substitution in JIRA:**
- String variables are inserted as-is
- Arrays are formatted as comma-separated lists
- Objects are formatted as JSON in code blocks
- Null/undefined variables are replaced with empty strings
- JIRA markup characters are automatically escaped

### 2. REST API
```yaml
type: rest-api
config:
  endpoint:
    url: "https://api.internal.com/provision"
    method: POST
  headers:
    Content-Type: application/json
    X-API-Key: "{{env.API_KEY}}"
  body:
    type: json
    contentTemplate: |
      {
        "name": "{{fields.name}}",
        "type": "{{fields.instanceType}}",
        "owner": "{{request.user.email}}"
      }
  retry:
    attempts: 3
    backoff: exponential
```

### Future Action Types

The following action types are planned for Q4 2025 and beyond:
- **Terraform**: Infrastructure provisioning via `.tf` template generation
- **GitHub Workflow**: Trigger GitHub Actions for complex automation
- **AWS Lambda**: Direct Lambda function invocation
- **CloudFormation**: AWS stack provisioning

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
| **Components** | `{{components.database.outputs.host}}` | Bundle component outputs |

### Functions

Built-in functions for data transformation:

- `{{uuid()}}` - Generate UUID
- `{{timestamp()}}` - Current timestamp
- `{{upper(string)}}` - Uppercase conversion
- `{{concat(str1, str2)}}` - String concatenation
- `{{replace(string, old, new)}}` - String replacement (useful for Terraform names)
- `{{json(object)}}` - JSON encoding
- `{{base64(string)}}` - Base64 encoding

## Examples

### Complete Bundle Example

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

### EKS Container Application

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
      - type: rest-api
        config:
          endpoint:
            url: "https://eks.platform.internal/api/deploy"
            method: POST
          body:
            type: json
            contentTemplate: |
              {
                "applicationName": "{{fields.appName}}",
                "containerImage": "{{fields.containerImage}}",
                "replicas": {{fields.replicas}},
                "namespace": "{{fields.namespace}}"
              }
```

### PostgreSQL Database

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
      - type: rest-api
        config:
          endpoint:
            url: "https://database.platform.internal/api/provision"
            method: POST
          body:
            type: json
            contentTemplate: |
              {
                "instanceName": "{{fields.instanceName}}",
                "instanceClass": "{{fields.instanceClass}}",
                "allocatedStorage": {{fields.storageSize}},
                "engine": "postgres",
                "backupRetention": 7,
                "multiAZ": true
              }
          outputs:
            - connectionString
            - endpoint
```

### AWS Parameter Store

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
      - type: rest-api
        config:
          endpoint:
            url: "https://secrets.platform.internal/api/create"
            method: POST
          body:
            type: json
            contentTemplate: |
              {
                "parameterPath": "/{{fields.secretName}}",
                "secrets": {{json(fields.secrets)}},
                "type": "SecureString"
              }
          outputs:
            - secretArn
```

## Validation and Testing

### Validation System

The catalog repository includes a comprehensive validation system to ensure all service definitions conform to the schema specifications. This system operates at multiple levels to catch errors before they reach the orchestrator service.

**Validation Components:**

1. **JSON Schema Definitions** (`/schema/` directory)
   - `catalog-item.json` - Schema for individual service definitions
   - `catalog-bundle.json` - Schema for composite service bundles
   - `common-types.json` - Shared type definitions and constraints

2. **Validation Scripts** (`/scripts/` directory) - **All scripts written in Ruby**
   - `validate-catalog.sh` - Main validation script
   - `validate-single.sh` - Validates individual YAML files
   - `validate-all.sh` - Batch validation for entire directories
   - `validate-changed.sh` - Validates only changed files in PR

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
          gem install json_schemer psych
      
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

This comprehensive validation system ensures catalog integrity while allowing teams to work independently within their domains.

## Platform Team Onboarding

### Prerequisites
Before a platform team can contribute to the catalog, they must:

1. **JIRA Project Setup**
   - Have a dedicated JIRA project or shared project with appropriate permissions
   - Define standard issue types (Task, Story, Bug) 
   - Configure any custom fields needed for their services

2. **GitHub Access**
   - Request addition to appropriate GitHub team
   - Team lead submits PR to add team to CODEOWNERS for their category folder
   - Complete catalog training (self-paced documentation review)

### Onboarding Process

1. **Initial Setup** (Day 1)
   - Platform team lead contacts DevX team
   - DevX team provides starter kit with templates
   - Team added to GitHub and CODEOWNERS

2. **First Service Definition** (Days 2-3)
   - Copy template from `/templates/catalog-item-template.yaml`
   - Modify for team's first service (typically simplest offering)
   - Run local validation: `./scripts/validate-single.sh my-service.yaml`
   - Submit PR for review

3. **Review Process**
   - DevX team reviews for schema compliance
   - Architecture team reviews if new patterns introduced
   - Must pass automated validation
   - Merge upon approval

4. **Iteration and Expansion** (Ongoing)
   - Add more services incrementally
   - Evolve from simple to complex offerings
   - Q3: JIRA-only; Q4: Add automation

### Support Resources
- Slack: #platform-catalog-help
- Documentation: Internal wiki catalog guide
- Examples: Review existing services in `/catalog/`

## Governance Process

### Pull Request Requirements

**All Changes:**
- Must pass automated validation via GitHub Actions
- Must have CODEOWNERS approval
- Must include test coverage for new patterns

**Breaking Changes:**
- Require 2 approvals (domain team + architecture team)
- Must include migration guide
- Version number must increment major version

### Service Naming Standards

**CatalogItem IDs:** `{category}-{service}-{variant}`
- category: Must match folder name (compute, databases, etc.)
- service: Descriptive service name (postgresql, eks, s3)
- variant: Differentiator (standard, enterprise, dev)
- Example: `database-postgresql-enterprise`

**Display Names:**
- Use title case
- Be descriptive but concise
- Include key differentiator
- Example: "PostgreSQL Database - Enterprise"

### Review Checklist

Platform team reviewers should verify:
- [ ] Schema validation passes
- [ ] Naming conventions followed
- [ ] JIRA project/issue types are valid
- [ ] Variable substitution syntax is correct
- [ ] Description is 50-500 characters
- [ ] Required fields are marked appropriately
- [ ] Default values are sensible
- [ ] Field validation patterns are tested


## Implementation Guidance

### JSON Schema Files (`/schema/`)
- Use JSON Schema Draft-07
- `catalog-item.json`: Require metadata (id, name, description, version, category, owner), presentation.form.groups, fulfillment.strategy.mode, fulfillment.manual.actions
- `catalog-bundle.json`: Require metadata, components array with catalogItem references, presentation, fulfillment.orchestration
- `common-types.json`: Define enums for categories (compute, databases, security, etc.), field types (string, number, select, etc.), action types (jira-ticket, rest-api); patterns for IDs (kebab-case), variable syntax (`^\{\{[a-z]+\.[a-zA-Z]+\}\}$`)

### Ruby Validation Scripts (`/scripts/`)

**Core Requirements:**
- Use `json_schemer` gem for JSON Schema validation
- Use `psych` for YAML parsing with safe loading
- Exit codes: 0 (success), 1 (validation error), 2 (system error)
- Output format: `filename:line:column: error message`

**validate-single.sh Implementation:**
```ruby
#!/usr/bin/env ruby
require 'json_schemer'
require 'psych'
require 'pathname'

file_path = ARGV[0]
begin
  content = Psych.safe_load_file(file_path)
  kind = content['kind']
  schema_file = "schema/catalog-#{kind.downcase}.json"
  schema = JSON.parse(File.read(schema_file))
  schemer = JSONSchemer.schema(schema)
  
  errors = schemer.validate(content).to_a
  if errors.empty?
    puts "✓ #{file_path}: Valid"
    exit 0
  else
    errors.each do |error|
      puts "✗ #{file_path}:#{error['data_pointer']}: #{error['error']}"
    end
    exit 1
  end
rescue => e
  puts "✗ #{file_path}: #{e.message}"
  exit 2
end
```

**validate-changed.sh Implementation:**
```bash
#!/bin/bash
BASE_SHA=${1:-HEAD~1}
CHANGED_FILES=$(git diff --name-only $BASE_SHA -- 'catalog/**/*.yaml')

if [ -z "$CHANGED_FILES" ]; then
  echo "No catalog files changed"
  exit 0
fi

ERRORS=0
for file in $CHANGED_FILES; do
  if [ -f "$file" ]; then
    ./scripts/validate-single.sh "$file"
    if [ $? -ne 0 ]; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo "Validation failed for $ERRORS file(s)"
  exit 1
fi
```

**Additional Validations:**
- Bundle components must reference existing CatalogItems
- Variable references must use valid scopes and syntax
- JIRA project keys must be uppercase
- Field IDs must be unique within a form group
- Circular dependencies in bundles are prohibited

### Test Files (`/tests/`)
- `valid/`: Include examples with all field types, both action types (jira-ticket, rest-api), cross-component references
- `invalid/missing-required-fields.yaml`: Omit metadata.id, fulfillment.manual.actions
- `invalid/invalid-naming-conventions.yaml`: Use snake_case for fields, PascalCase for IDs

### Templates (`/templates/`)
- Include minimal valid structure with TODO comments
- `catalog-item-template.yaml`: Basic metadata, one field, one JIRA action
- `jira-action-template.yaml`: Project, issueType, summaryTemplate with variable examples

### Other Files
- `README.md`: Link to catalog.md, quick start commands, troubleshooting
- `.gitignore`: `*.tmp`, `.DS_Store`, `node_modules/`, `vendor/`, test output files