# Platform Automation Orchestrator - Catalog Repository

**Repository Name**: `platform-automation-repository`  
**GitHub Location**: `github.com/company/platform-automation-repository`

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Note on Implementation

This document serves as architectural guidance and conceptual inspiration for engineering teams developing catalog repository systems. It is not intended as a precise implementation specification or detailed blueprint. Engineering teams should interpret these concepts, adapt the proposed patterns to their specific technical environment and organizational requirements, and develop their own detailed work plans accordingly. While implementation approaches may vary, the core architectural concepts, data structures, and operational patterns described herein should be represented in the final system design to ensure consistency with the overall platform vision.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Naming Conventions](#naming-conventions)
- [Schema Versioning](#schema-versioning)
- [Schema Reference](#schema-reference)
- [Field Types](#field-types)
- [Action Types](#action-types)
- [Templates and Variables](#templates-and-variables)
- [Examples](#examples)
- [Validation and Testing](#validation-and-testing)
- [Platform Team Onboarding](#platform-team-onboarding)
- [Governance Process](#governance-process)
- [Implementation Guidance](#implementation-guidance)
- [Future Enhancements](#future-enhancements)

## Repository Structure

The Platform Automation Orchestrator catalog repository (`platform-automation-repository`) follows a structured layout designed to organize service definitions, validation tools, and governance processes. This structure ensures clear separation of concerns and enables effective collaboration between platform teams.

- [CODEOWNERS Configuration](#codeowners-configuration)

```
platform-automation-repository/
├── catalog/                          # Service definitions by category
│   ├── compute/                      # Compute services (EKS containers)
│   │   └── *.yaml                    # Service definitions
│   ├── databases/                    # Database services (Aurora PostgreSQL)
│   │   └── *.yaml                    # Service definitions
│   ├── security/                     # Security services (Parameter Store)
│   │   └── *.yaml                    # Service definitions
│   └── bundles/                      # Composite service bundles (CatalogBundles)
│       └── *.yaml                    # CatalogBundle definitions
├── schema/                           # JSON Schema specifications
│   ├── catalog-item.json             # CatalogItem schema definition
│   ├── catalog-bundle.json           # CatalogBundle schema definition
│   └── common-types.json             # Shared type definitions and patterns
├── templates/                        # Starter templates for new services
│   ├── catalog-item-template.yaml    # Basic CatalogItem template
│   ├── catalog-bundle-template.yaml  # Basic CatalogBundle template
│   └── jira-action-template.yaml     # JIRA action configuration template
├── scripts/                          # Validation and testing tools
│   ├── validate-catalog.sh           # Main validation script (Ruby)
│   ├── validate-single.sh            # Single file validation
│   ├── validate-all.sh               # Batch validation for directories
│   ├── validate-changed.sh           # Validate only changed files in PR
│   ├── test-template.sh              # Test template with sample data
│   └── integration-test.sh           # End-to-end integration testing
├── tests/                            # Test fixtures and examples
│   ├── valid/                        # Valid examples for testing
│   │   ├── example-catalog-item.yaml
│   │   ├── example-catalog-bundle.yaml
│   │   └── cross-component-references.yaml
│   └── invalid/                      # Invalid examples with expected errors
│       ├── missing-required-fields.yaml
│       ├── invalid-naming-conventions.yaml
│       └── circular-dependencies.yaml
├── .github/                          # GitHub configuration
│   ├── workflows/                    # CI/CD pipelines
│   │   └── validate-catalog.yml      # PR validation workflow
│   └── CODEOWNERS                    # Team ownership and access control
├── README.md                         # Repository overview and quick start
└── .gitignore                        # Git ignore patterns for temp files
```

### CODEOWNERS Configuration

Use GitHub's CODEOWNERS file to enforce team-based access control and ensure appropriate review processes for catalog changes.

**Recommended Access Control Strategy:**
- **Platform Teams**: Own their specific domain folders (e.g., `/catalog/databases/`, `/catalog/compute/`)
- **Developer Experience Team**: Provide cross-domain support for catalog integration
- **Architecture Team**: Own schema specifications and overall catalog design patterns

**Key Considerations:**
- Ensure platform teams have autonomy over their service definitions
- Provide support teams access across domains for troubleshooting and integration assistance  
- Require architecture review for schema changes and bundle definitions
- Prevent accidental cross-team service modifications through proper path-based ownership

## Naming Conventions

The catalog enforces specific naming conventions to ensure consistency and compatibility with the Go-based orchestrator service. These conventions align with Go language standards and cloud-native tooling for optimal compatibility.

**Important**: All naming conventions must be followed precisely for proper integration:

- **Type Names** (`kind` field): Use **PascalCase**
  - Examples: `CatalogItem`, `CatalogBundle`
  
- **Field Names**: Use **camelCase**
  - Examples: `catalogItem`, `instanceClass`, `contentTemplate`, `issueType`
  
- **File Names**: Use **kebab-case**
  - Examples: `database-aurora-postgresql-standard.yaml`, `compute-eks-containerapp.yaml`
  
- **IDs and References**: Use **kebab-case**
  - Examples: `database-aurora-postgresql-standard`, `bundle-webapp-production`

These conventions align with Go language standards and cloud-native tooling (Kubernetes, Helm, etc.) for optimal compatibility.

## Schema Versioning

All catalog documents must declare their schema version using `schemaVersion`. This ensures compatibility and enables safe schema evolution.

**Current Version**: `catalog/v1`

```yaml
schemaVersion: catalog/v1
kind: CatalogItem
```

**Maturity Levels**:
- `v1` - Stable, production-ready with backward compatibility
- `v2pre1` - Development version, features may change
- `v2pre2` - Later development version, closer to stable
- `v2` - Next stable version

**Version Support**: We support the current stable version plus one previous version during transitions. Deprecation processes will be defined in future phases as needed.

## Schema Reference

The catalog schema defines two primary document types that platform teams use to define their service offerings. The schema follows a hierarchical structure where CatalogBundles orchestrate multiple CatalogItems into complete bundles.

- [CatalogBundle - Composite Service](#catalogbundle---composite-service)
- [CatalogItem - Individual Service](#catalogitem---individual-service)

**Important Note on Error Handling**: The catalog documents do not specify error handling behavior. All error handling, retry logic, and recovery mechanisms are the responsibility of the orchestrator service. When any action fails during execution, the service stops and requires manual intervention. Future phases may introduce automated recovery, but this is not part of the catalog specification.

**Current Scope**: Initially, all services use manual fulfillment via JIRA tickets. The `automatic` fulfillment sections shown in examples are for future automated provisioning capabilities.

### CatalogBundle - Composite Service

A CatalogBundle combines multiple CatalogItems into a single deployable bundle. It orchestrates the provisioning of multiple services with proper dependency management and metadata reference between components.

**Design Note**: This simplified model eliminates dynamic output generation between components for clarity and maintainability. All computed values (connection strings, generated IDs, etc.) are created within the final fulfillment template rather than being passed between components. This design choice could be reconsidered in future versions if complex inter-component data flows become necessary.

**Metadata Constants**: The metadata section can only contain constant data - no variable interpretation occurs. Any placeholder syntax (like `{instanceName}`) in metadata values are literal strings that can be processed by consuming applications, not by the orchestrator itself.

**Component Configuration**: Components only specify catalog item references and dependencies. All field values and variable substitution occur exclusively within the fulfillment templates of the referenced catalog items, not in the component configuration.

**Bundle Behavior:**
Bundles create multiple JIRA tickets (one per component) and establish JIRA linking relationships based on the `dependsOn` configuration. The orchestrator:
1. Creates all component JIRA tickets using each CatalogItem's template
2. Adds JIRA issue links of type "blocks/is blocked by" based on dependencies
3. Returns a bundle request with links to all created tickets

```yaml
schemaVersion: catalog/v1
kind: CatalogBundle

metadata:
  id: bundle-{bundle}-{variant}  # e.g., bundle-webapp-standard
  name: Display Name
  description: Complete bundle description
  version: 1.0.0
  category: bundles
  owner:
    team: platform-architecture-team
    contact: architecture@company.com

components:
  - id: database
    catalogItem: database-aurora-postgresql-standard  # References existing CatalogItem
    dependsOn: []
  
  - id: secrets
    catalogItem: security-parameterstore-standard
    dependsOn: [database]  # JIRA ticket will be linked as "blocked by" database ticket
  
  - id: application
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]  # Creates JIRA blocking links to both

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
      parentTicket: false  # Currently: No parent epic; Future: Optional epic creation
```

### CatalogItem - Individual Service

```yaml
schemaVersion: catalog/v1
kind: CatalogItem

metadata:
  id: {category}-{service}-{variant}  # e.g., database-aurora-postgresql-standard
  name: Display Name
  description: 50-500 character description
  version: 1.0.0
  category: databases  # Must match a repository folder
  owner:
    team: platform-{category}-team
    contact: team@company.com
  connectionTemplate: "host={instanceName}.cluster-xyz.us-west-2.rds.amazonaws.com;port=5432;database=postgres"
  parameterPath: "/{secretName}"

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
            summaryTemplate: "Provision {{.input.config.name}}"
  
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
                "service": "{{.output.currentItem.metadata.id}}",
                "name": "{{.input.config.name}}"
              }
```

## Field Types

Fields define the user input interface for catalog items and bundles. Each field type provides specific validation rules and generates corresponding UI elements in the developer portal. Platform teams use these field types to create dynamic forms that collect the necessary information for service provisioning.

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

Action types define how the orchestrator fulfills service requests. Each action type represents a different integration method that platform teams can use to automate or manage their service provisioning workflows.

**Current Implementation**: The initial implementation supports JIRA action types only. REST API action types will be introduced in future releases. Additional action types (Terraform, GitHub Workflows) are also planned for future releases.

**Important Note on Error Handling**: Action type configurations do not specify error handling, retry logic, timeouts, or recovery mechanisms. All error handling is the responsibility of the orchestrator service implementation. When actions fail, the service determines the appropriate response (retry, abort, escalate, etc.).

- [JIRA Ticket](#jira-ticket)
- [REST API](#rest-api)
- [Git Commit](#git-commit)
- [GitHub Workflow](#github-workflow)

### JIRA Ticket

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
    summaryTemplate: "{{.input.config.name}} request"
    descriptionTemplate: |
      Requesting: {{.input.config.name}}
      Type: {{.output.currentItem.metadata.name}}
      User: {{.system.user.email}}
      Request ID: {{.system.requestId}}
      
      Configuration:
      {{#each .input.config}}
      - {{@key}}: {{this}}
      {{/each}}
    issueType: Task
    priority: "{{.input.config.priority}}"
    labels:
      - platform-automation
      - "{{.output.currentItem.metadata.category}}"
    customFields:
      customfield_10001: "{{.input.config.costCenter}}"
      customfield_10002: "{{.input.config.environment}}"
```

**Variable Substitution in JIRA:**
- String variables are inserted as-is
- Arrays are formatted as comma-separated lists
- Objects are formatted as JSON in code blocks
- Null/undefined variables are replaced with empty strings
- JIRA markup characters are automatically escaped

**JIRA Status Handling:**
- The orchestrator does not track or store JIRA ticket status
- When a status request is made via API or CLI, the service queries JIRA in real-time
- Each status check makes a fresh API call to JIRA to get current ticket state
- Platform teams update ticket status in JIRA as work progresses
- No polling or caching of JIRA status occurs

### REST API

**Required Fields:**
- `endpoint.url`: Target API endpoint URL
- `endpoint.method`: HTTP method (GET, POST, PUT, DELETE, PATCH)

**Optional Fields:**
- `headers`: HTTP headers with variable substitution support
- `body.type`: Request body format (json, form-data, text)
- `body.contentTemplate`: Template for request body with variable substitution
- `retry.attempts`: Number of retry attempts (default: 0)
- `retry.backoff`: Backoff strategy (linear, exponential)
- `timeout`: Request timeout in seconds
- `authentication`: Authentication configuration (bearer, basic, api-key)

```yaml
type: rest-api
config:
  endpoint:
    url: "https://api.internal.com/provision"
    method: POST
  headers:
    Content-Type: application/json
    X-API-Key: "{{.system.environment.apiKey}}"
  body:
    type: json
    contentTemplate: |
      {
        "name": "{{.input.basic.name}}",
        "type": "{{.input.basic.instanceType}}",
        "owner": "{{.system.user.email}}"
      }
  retry:
    attempts: 3
    backoff: exponential
  timeout: 30
```

**Response Handling:**
- Success responses (2xx) mark the action as completed
- Client errors (4xx) mark the action as failed without retry
- Server errors (5xx) trigger retry logic if configured
- Response data is not captured or stored for variable substitution
- Content-Type header determines response parsing for logging purposes only

### Git Commit

**Status**: Planned for future release

**Required Fields:**
- `repository`: Repository identifier (e.g., owner/repo)
- `branch`: Target branch for the commit
- `files`: Array of file modifications with path, contentTemplate, and operation (create/update/delete)
- `commitMessage`: Template for the commit message

**Optional Fields:**
- `mergeStrategy`: How to handle the merge (fast-forward, merge-commit, squash) - defaults to fast-forward
- `createPullRequest`: Create pull request instead of direct commit (boolean)
- `pullRequestTitle`: Template for pull request title
- `pullRequestBody`: Template for pull request description
- `assignees`: Array of GitHub usernames to assign
- `reviewers`: Array of GitHub usernames to request review from

```yaml
type: git-commit
config:
  repository: "company/infrastructure"
  branch: "main"
  commitMessage: "Deploy {{.input.application.appName}} to {{.input.application.environment}}"
  mergeStrategy: "squash"
  createPullRequest: false
  files:
    - path: "apps/{{.input.application.appName}}/config.yaml"
      operation: "update"
      contentTemplate: |
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: {{.input.application.appName}}-config
        data:
          environment: {{.input.application.environment}}
          replicas: "{{.input.application.replicas}}"
```

**Git Operations:**
- File operations support create, update, and delete operations
- Content templates support full variable substitution
- Atomic commits ensure all file changes succeed or fail together
- Branch protection rules are respected and may cause action failure
- Pull request mode enables approval workflows for sensitive changes

### GitHub Workflow

**Status**: Planned for future release

**Required Fields:**
- `repository`: Repository identifier
- `workflowFile`: Workflow file path (e.g., .github/workflows/deploy.yml)
- `ref`: Git reference to trigger on (branch/tag)

**Optional Fields:**
- `inputs`: Key-value pairs for workflow inputs with variable substitution
- `waitForCompletion`: Wait for workflow completion (boolean) - defaults to false
- `timeout`: Maximum wait time for workflow completion in seconds
- `failOnWorkflowFailure`: Mark action as failed if workflow fails (boolean) - defaults to true

```yaml
type: github-workflow
config:
  repository: "company/deployment-workflows"
  workflowFile: ".github/workflows/deploy-app.yml"
  ref: "main"
  waitForCompletion: true
  timeout: 1800
  inputs:
    app_name: "{{.input.application.appName}}"
    environment: "{{.input.application.environment}}"
    image_tag: "{{.input.application.imageTag}}"
    replicas: "{{.input.application.replicas}}"
```

**Workflow Integration:**
- Workflows must be configured to accept `workflow_dispatch` triggers
- Input parameters are validated against workflow input schema
- Workflow run URLs are captured for status tracking and debugging
- Failed workflows provide detailed error information and logs
- Long-running workflows can optionally be tracked to completion

## Templates and Variables

The orchestrator maintains a map of named values organized by dot-separated paths. Catalog definitions reference these values using `{{.namespace.path.to.value}}` syntax for content generation.

**How it works**: User form data populates `.input` paths, system context populates `.system` paths, and static metadata from catalog items populates `.output` paths. Components can only reference constant metadata values, not runtime-generated data.

**Variable Syntax**: `{{.namespace.path.to.value}}`

### Namespace Structure

**Three Top-Level Namespaces**:

| Namespace | Purpose | Population Timing | Access Pattern |
|-----------|---------|-------------------|----------------|
| `.input` | User form data | Request submission | `{{.input.groupId.fieldId}}` |
| `.output` | Static metadata from catalog items | Catalog loading | `{{.output.itemName.metadata.path}}` |
| `.system` | Platform context & environment | Request processing | `{{.system.timestamp}}` |

### Output Namespace Organization

The `.output` namespace contains static metadata from catalog items:

```
.output
├── itemName                      # Catalog item metadata
│   └── metadata                  # Static metadata section
│       ├── connectionTemplate    # Template strings
│       ├── parameterPath         # Static paths
│       └── version               # Version info
├── bundleName                    # Bundle metadata (if any)
│   └── metadata
│       └── description           # Bundle-level static data
```

### Path Examples

**Input Paths** (user form data):
```
{{.input.application.appName}}          # From application form group
{{.input.database.dbSize}}              # From database form group  
{{.input.config.instanceName}}          # From config form group
```

**Output Paths** (static metadata):
```
{{.output.database.metadata.connectionTemplate}}   # Static template from item
{{.output.webappStack.metadata.description}}       # Static data from bundle
{{.output.secrets.metadata.parameterPath}}         # Static path template
```

**System Paths** (platform context):
```
{{.system.timestamp}}
{{.system.requestId}} 
{{.system.user.email}}
{{.system.platform.account}}
{{.system.platform.region}}
```

### Scoping Rules

Access to namespace paths is strictly controlled by component type:

- **CatalogItem Fulfillment**: Can reference `.input.*` and `.system.*` for user data and platform context
- **CatalogBundle Components**: No variable interpretation - only catalog item references and dependencies
- **Action Templates**: Can reference all paths available in their execution context

**Important**: Only static metadata can be referenced via `.output.*.metadata.*` paths. No dynamic runtime values are available. All variable substitution occurs exclusively within fulfillment action templates.

## Examples

This section provides comprehensive examples demonstrating the catalog schema in practice. Examples progress from complete bundle examples to individual service definitions, illustrating the hierarchical structure and integration patterns.

- [Complete Bundle Example](#complete-bundle-example)
- [EKS Container Application](#eks-container-application)
- [Aurora PostgreSQL Database](#aurora-postgresql-database)
- [AWS Parameter Store](#aws-parameter-store)

### Complete Bundle Example

```yaml
schemaVersion: catalog/v1
kind: CatalogBundle

metadata:
  id: bundle-webapp-production
  name: Production Web Application Stack
  description: Complete web application with database and secrets management
  version: 2.0.0
  category: bundles

components:
  - id: database
    catalogItem: database-aurora-postgresql-standard
    
  - id: secrets
    catalogItem: security-parameterstore-standard
    dependsOn: [database]
    
  - id: app
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]

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
schemaVersion: catalog/v1
kind: CatalogItem

metadata:
  id: compute-eks-containerapp
  name: EKS Container Application
  description: Deploy containerized application to EKS cluster
  version: 1.0.0
  category: compute
  defaultNamespace: "applications"
  clusterEndpoint: "https://k8s.company.internal"

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
            summaryTemplate: "Deploy {{.input.basic.appName}} to EKS"
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
                "applicationName": "{{.input.basic.appName}}",
                "containerImage": "{{.input.basic.containerImage}}",
                "replicas": {{.input.basic.replicas}},
                "namespace": "{{.output.currentItem.metadata.defaultNamespace}}"
              }
```

### Aurora PostgreSQL Database

```yaml
schemaVersion: catalog/v1
kind: CatalogItem

metadata:
  id: database-aurora-postgresql-standard
  name: Aurora PostgreSQL Database
  description: Managed Aurora PostgreSQL instance with backups
  version: 1.0.0
  category: databases
  connectionTemplate: "host={instanceName}.cluster-xyz.us-west-2.rds.amazonaws.com;port=5432;database=postgres"
  defaultPort: "5432"

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
            summaryTemplate: "Aurora PostgreSQL: {{.input.config.instanceName}}"
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
                "instanceName": "{{.input.config.instanceName}}",
                "instanceClass": "{{.input.config.instanceClass}}",
                "allocatedStorage": {{.input.config.storageSize}},
                "engine": "postgres",
                "backupRetention": 7,
                "multiAZ": true
              }
```

### AWS Parameter Store

```yaml
schemaVersion: catalog/v1
kind: CatalogItem

metadata:
  id: security-parameterstore-standard
  name: AWS Parameter Store Secrets
  description: Secure secret storage in AWS Parameter Store
  version: 1.0.0
  category: security
  parameterPath: "/{secretName}"
  kmsKeyId: "alias/parameter-store-key"

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
            summaryTemplate: "Create secrets: {{.input.config.secretName}}"
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
                "parameterPath": "/{{.input.config.secretName}}",
                "secrets": {{json(.input.config.secrets)}},
                "type": "SecureString"
              }
```

## Validation and Testing

The `platform-automation-repository` catalog repository implements a comprehensive validation and testing framework to ensure service definitions meet quality standards and schema requirements. This multi-layered approach catches errors early and maintains catalog integrity across all platform teams.

- [Validation System](#validation-system)
- [Testing Process](#testing-process)
- [CI/CD Integration](#cicd-integration)

### Validation System

The `platform-automation-repository` repository includes a comprehensive validation system to ensure all service definitions conform to the schema specifications. This system operates at multiple levels to catch errors before they reach the orchestrator service.

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
./scripts/validate-catalog.sh catalog/databases/aurora-postgresql-standard.yaml

# 2. Validate all services in a category
./scripts/validate-catalog.sh catalog/databases/

# 3. Run comprehensive validation before commit
./scripts/validate-all.sh

# 4. Test with sample data (dry run)
./scripts/test-template.sh catalog/databases/aurora-postgresql-standard.yaml sample-data.json
```

**Validation Output:**

The validation scripts provide clear, actionable feedback:
- **Success**: Green checkmark with "Valid" status
- **Errors**: Red X with specific error location (file:line:column)
- **Warnings**: Yellow warning for non-critical issues
- **Suggestions**: Blue info markers for improvements

Example error output:
```
✗ catalog/databases/aurora-postgresql-invalid.yaml
  Line 15: Field 'instanceClass' should use camelCase (found: instance_class)
  Line 22: Missing required field 'manual.actions'
  Line 38: Invalid variable reference '{{field.name}}' (should be '{{.input.config.name}}')
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

**Catalog Synchronization:**

The orchestrator service stays synchronized with the `platform-automation-repository` GitHub repository through webhooks:

- **Repository**: `github.com/company/platform-automation-repository`
- **Push Events**: When changes are merged to the main branch of `platform-automation-repository`, GitHub sends a webhook to the PAO service
- **Webhook Endpoint**: The service exposes `/api/v1/webhooks/github` to receive catalog update notifications from `platform-automation-repository`
- **Validation**: The service validates incoming catalog changes against the schema before accepting them
- **Cache Invalidation**: Successfully validated changes trigger cache refresh in the service
- **Fallback**: Manual catalog refresh available via `/api/v1/catalog/refresh` endpoint if needed

This comprehensive validation system ensures catalog integrity while allowing teams to work independently within their domains.

## Platform Team Onboarding

The onboarding process enables platform teams to contribute services to the catalog systematically. This structured approach ensures teams understand governance requirements, validation processes, and best practices before contributing their first service definition.

- [Prerequisites](#prerequisites)
- [Onboarding Process](#onboarding-process)
- [Support Resources](#support-resources)

### Prerequisites

Before a platform team can contribute to the catalog, they must:

1. **JIRA Project Setup**
   - Have a dedicated JIRA project or shared project with appropriate permissions
   - Define standard issue types (Task, Story, Bug) 
   - Configure any custom fields needed for their services

2. **GitHub Access**
   - Request addition to appropriate GitHub team for the `platform-automation-repository` repository
   - Team lead submits PR to add team to CODEOWNERS for their category folder in `platform-automation-repository`
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
   - Initial: JIRA-only; Future: Add automation

### Support Resources
- Slack: #platform-catalog-help
- Documentation: Internal wiki catalog guide
- Examples: Review existing services in `/catalog/`

## Governance Process

The governance process establishes standards and procedures for catalog contributions, ensuring quality, consistency, and proper review workflows. This process balances team autonomy with architectural oversight and quality assurance.

- [Pull Request Requirements](#pull-request-requirements)
- [Service Naming Standards](#service-naming-standards)
- [Review Checklist](#review-checklist)

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
- service: Descriptive service name (aurora-postgresql, eks, s3)
- variant: Differentiator (standard, enterprise, dev)
- Example: `database-aurora-postgresql-enterprise`

**Display Names:**
- Use title case
- Be descriptive but concise
- Include key differentiator
- Example: "Aurora PostgreSQL Database - Enterprise"

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

This section provides technical implementation details for teams setting up and maintaining the `platform-automation-repository` catalog repository infrastructure. It covers schema definitions, validation scripts, test frameworks, and supporting tools necessary for a production-ready catalog.

- [JSON Schema Files](#json-schema-files)
- [Ruby Validation Scripts](#ruby-validation-scripts)
- [Test Files](#test-files)
- [Templates](#templates)
- [Other Files](#other-files)

### JSON Schema Files
- Use JSON Schema Draft-07
- `catalog-item.json`: Require metadata (id, name, description, version, category, owner), presentation.form.groups, fulfillment.strategy.mode, fulfillment.manual.actions
- `catalog-bundle.json`: Require metadata, components array with catalogItem references, presentation, fulfillment.orchestration
- `common-types.json`: Define enums for categories (compute, databases, bundles, security, etc.), field types (string, number, select, etc.), action types (jira-ticket, rest-api); patterns for IDs (kebab-case), variable syntax (`^\{\{\.[a-zA-Z]+(\.[a-zA-Z]+)*\}\}$`)

### Ruby Validation Scripts

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

### Test Files
- `valid/`: Include examples with all field types, both action types (jira-ticket, rest-api), cross-component references
- `invalid/missing-required-fields.yaml`: Omit metadata.id, fulfillment.manual.actions
- `invalid/invalid-naming-conventions.yaml`: Use snake_case for fields, PascalCase for IDs

### Templates
- Include minimal valid structure with TODO comments
- `catalog-item-template.yaml`: Basic metadata, one field, one JIRA action
- `jira-action-template.yaml`: Project, issueType, summaryTemplate with variable examples

### Other Files
- `README.md`: Link to catalog.md, quick start commands, troubleshooting
- `.gitignore`: `*.tmp`, `.DS_Store`, `node_modules/`, `vendor/`, test output files

## Future Enhancements

This section outlines potential catalog capabilities and enhancements for future releases. These enhancements represent the evolution path for the catalog system as the platform matures and adoption grows.

- [Advanced Action Types](#advanced-action-types)
- [Enhanced Bundle Capabilities](#enhanced-bundle-capabilities)
- [Advanced Governance Features](#advanced-governance-features)
- [Developer Experience Improvements](#developer-experience-improvements)
- [Platform Intelligence](#platform-intelligence)

The following catalog capabilities are potential future enhancements:

### Advanced Action Types
- **Webhook Action**: Generic outbound webhook invocation for external system notifications
- **ServiceNow Integration**: Direct integration with ServiceNow for enterprise ITSM
- **Slack/Teams Notifications**: Direct messaging integration for status updates
- **Email Notifications**: SMTP-based email actions for approvals and notifications

### Enhanced Bundle Capabilities
- **Parallel Execution**: Execute independent components simultaneously
- **Conditional Components**: Components that only deploy based on field values or conditions
- **Rollback Support**: Automatic rollback of all components if any fail
- **Cross-Bundle Dependencies**: Reference outputs from other bundle deployments

### Advanced Governance Features
- **Approval Workflows**: Multi-step approval chains before provisioning
- **Cost Estimation**: Automatic cost calculation for requested resources
- **Quota Management**: Team-based quotas and resource limits
- **Compliance Scanning**: Automatic security and compliance validation

### Developer Experience Improvements
- **GitOps Integration**: Manage requests through Git pull requests
- **IDE Extensions**: VS Code and IntelliJ plugins for catalog development
- **Dry Run Mode**: Preview what would be provisioned without creating resources
- **Request Templates**: Save and share common request configurations

### Platform Intelligence
- **Recommendation Engine**: Suggest optimal configurations based on usage patterns
- **Anomaly Detection**: Identify unusual request patterns or potential issues
- **Performance Analytics**: Track provisioning times and optimization opportunities
- **Dependency Mapping**: Visualize relationships between catalog items and deployments
