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
│   └── security/                     # Security services (Parameter Store)
│       └── *.yaml                    # Service definitions
├── bundles/                          # Composite service bundles (CatalogBundles)
│   └── *.yaml                        # CatalogBundle definitions
├── schema/                           # JSON Schema specifications
│   ├── catalog-item.json             # CatalogItem schema definition
│   ├── catalog-bundle.json           # CatalogBundle schema definition
│   └── common-types.json             # Shared type definitions and patterns
├── templates/                        # Starter templates for new services
│   ├── catalog-item-template.yaml    # Basic CatalogItem template
│   ├── catalog-bundle-template.yaml  # Basic CatalogBundle template
│   └── jira-action-template.yaml     # JIRA action configuration template
├── scripts/                          # Validation and testing tools
│   ├── validate-catalog.rb           # Main validation script (Ruby)
│   ├── validate-single.rb            # Single file validation
│   ├── validate-all.sh               # Batch validation wrapper script
│   ├── validate-changed.sh           # Validate only changed files in PR
│   ├── test-template.rb              # Test template with sample data
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
- **Developer Experience Team**: Own `/bundles/` folder and provide cross-domain support for catalog integration
- **Architecture Team**: Own schema specifications and overall catalog design patterns

**Key Considerations:**
- Ensure platform teams have autonomy over their service definitions
- Provide support teams access across domains for troubleshooting and integration assistance  
- Require architecture review for schema changes, bundle definitions, and new category creation
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
- `v2rc1` - Release candidate, closer to stable
- `v2` - Next stable version

**Version Support**: We support the current stable version plus one previous version during transitions. Deprecation processes will be defined as needed.

## Schema Reference

The catalog schema defines two primary document types that platform teams use to define their service offerings. The schema follows a hierarchical structure where CatalogBundles orchestrate multiple CatalogItems into complete bundles.

**Critical Schema Requirements**:

1. **Required Input Sections**: All catalog items and bundles must define input sections with at minimum the required `name` field as a top-level field outside any group
2. **Name Field Validation**: The `name` field must use the pattern `"^[a-z][a-z0-9-]{2,28}[a-z0-9]$"` and be marked as required
3. **Form Structure Uniqueness**: Group names must be unique within each catalog item or bundle, and field names must be unique within each group
4. **Variable Scoping**: Template variables use the syntax `{{.namespace.path.to.value}}` and are scoped by component type
5. **No Variable Substitution in Input**: The input section only supports static values - all variable substitution occurs during fulfillment processing

- [CatalogBundle - Composite Service](#catalogbundle---composite-service)
- [CatalogItem - Individual Service](#catalogitem---individual-service)

**Important Note on Error Handling**: The catalog documents do not specify error handling behavior. All error handling, retry logic, and recovery mechanisms are the responsibility of the orchestrator service. When any action fails during execution, the service stops and requires manual intervention.

The `automatic` fulfillment sections shown in examples demonstrate automated provisioning capabilities alongside manual JIRA fulfillment options.

### CatalogBundle - Composite Service

A CatalogBundle combines multiple CatalogItems into a single deployable bundle. It orchestrates the provisioning of multiple services with proper dependency management and metadata reference between components.

**Design Note**: Components are processed sequentially, with each component's fulfillment actions able to reference outputs generated by previous components. This enables complex inter-component data flows where later components can use connection strings, generated IDs, and other computed values from earlier components in their fulfillment templates.

**Metadata Constants**: The metadata section contains only static constant values - no variable substitution occurs. Any template-like syntax in metadata values are literal strings for reference purposes only, not processed by the orchestrator.

**Component Configuration**: Components specify catalog item references and dependencies. Variable substitution occurs within the fulfillment templates of the referenced catalog items, where each component can access all previous component outputs through the `.output` namespace.

**Bundle Input Forms**: Bundles must define their own input sections containing at minimum the required `name` field. Bundle forms may merge or reference fields from component catalog items, but this is the responsibility of the bundle author to design appropriately.

**Bundle Behavior:**
Bundles create multiple JIRA tickets (one per component) and establish JIRA linking relationships based on the `dependsOn` configuration. The orchestrator:
1. Creates component JIRA tickets in dependency order using each CatalogItem's template
2. Adds JIRA issue links of type "blocks/is blocked by" based on dependencies
3. Returns a bundle request with links to all created tickets

**Important Note on Dependencies**: The `dependsOn` field controls both execution order and JIRA issue linking. Components are processed in dependency order, with JIRA tickets created sequentially according to the dependency graph. JIRA issue links of type "blocks/is blocked by" are added based on dependency declarations. This approach allows platform teams to see relationships in JIRA and coordinate their work in the proper sequence. Teams can optionally configure JIRA workflow automation to enforce additional blocking behavior if needed for their specific services.

```yaml
schemaVersion: catalog/v1
kind: CatalogBundle

metadata:
  id: bundle-{name}-{variant}  # e.g., bundle-webapp-standard
  name: Display Name
  description: Complete bundle description
  version: 1.0.0
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

input:
  form:
    name: Bundle Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    description: "Unique identifier for this bundle deployment"
    groups:
      - id: basic
        name: Basic Configuration
        fields:
          - id: instanceName
            name: Database Instance Name
            type: string
            required: true
          - id: instanceClass
            name: Instance Class
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: secretName
            name: Secret Name
            type: string
            required: true
          - id: appName
            name: Application Name
            type: string
            required: true
          - id: containerImage
            name: Container Image
            type: string
            required: true
          - id: replicas
            name: Replica Count
            type: number
            default: 2

fulfillment:
  orchestration:
    mode: sequential  # Components are processed in order
    jiraLinking:
      linkType: blocks  # JIRA link type for dependencies
      parentTicket: false  # No parent epic; Optional epic creation in future versions
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
  connectionTemplate: "host=INSTANCENAME.cluster-xyz.us-west-2.rds.amazonaws.com;port=5432;database=postgres"
  parameterPath: "/SECRETNAME"

input:
  form:
    name: Resource Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    groups:
      - id: basic
        name: Basic Configuration
        fields:

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
            summaryTemplate: "Provision {{.current.basic.name}}"
  
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
                "service": "{{.metadata.database-aurora-postgresql-standard.id}}",
                "name": "{{.current.basic.name}}"
              }
```

## Field Types

Fields define the user input interface for catalog items and bundles. Each field type provides specific validation rules and generates corresponding UI elements in the developer portal. Platform teams use these field types to create dynamic input forms that collect the necessary information for service provisioning.

| Type | Use Case | Validation | UI Element |
|------|----------|------------|------------|
| `string` | Text input | pattern, min/max length | Text field |
| `number` | Numeric values | min/max, step | Number input |
| `boolean` | Yes/No choices | - | Checkbox |
| `select` | Single choice | enum (top-level) | Dropdown |
| `multiselect` | Multiple choices | enum (top-level) | Multi-select |
| `date` | Date picker | min/max date | Date picker |
| `file` | File upload | size, type | File upload |
| `textarea` | Multi-line text | min/max length | Text area |
| `password` | Sensitive data | pattern, strength | Password field |
| `email` | Email addresses | format validation | Email input |

**Form Definition Structure:**
```yaml
input:
  form:
    name: Display Name      # Required top-level name field (always required)
    type: string           # Always string for name field
    required: true         # Always required
    validation:            # Name field validation rules
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"  # Kebab-case pattern
    description: "Help"    # Optional help text for name field
    groups:                # Optional groups for additional fields
      - id: groupName      # Unique group identifier (camelCase)
        name: Group Label  # User-friendly group label
        fields:            # Fields within this group
          - id: fieldName  # Unique identifier (camelCase)
            name: Field Label  # User-friendly label
            type: string   # Field type from table above
            required: true # Optional, default false
            default: "value"  # Optional static default value
            description: "Help"  # Optional help text
            enum: [a, b, c]  # Allowed values for select/multiselect
            validation:    # Optional validation rules
              pattern: "^[a-z]+$"  # Regex for string types
              min: 1       # Minimum for numbers
              max: 100     # Maximum for numbers
```

## Action Types

Action types define how the orchestrator fulfills service requests. Each action type represents a different integration method that platform teams can use to automate or manage their service provisioning workflows.

**Current Implementation**: The implementation supports JIRA ticket and REST API action types. Additional action types (Terraform, GitHub Workflows) are available for future implementation.

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
    summaryTemplate: "{{.current.basic.name}} request"
    descriptionTemplate: |
      Requesting: {{.current.basic.name}}
      Type: {{.metadata.database-aurora-postgresql-standard.name}}
      User: {{.system.user.email}}
      Request ID: {{.system.requestId}}
      
      Configuration details provided in request form.
    issueType: Task
    priority: "{{.current.basic.priority}}"
    labels:
      - platform-automation
      - "{{.metadata.database-aurora-postgresql-standard.category}}"
    customFields:
      customfield_10001: "{{.current.basic.costCenter}}"
      customfield_10002: "{{.current.basic.environment}}"
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
    X-API-Key: "{{.system.platform.apiKey}}"
  body:
    type: json
    contentTemplate: |
      {
        "name": "{{.current.basic.name}}",
        "type": "{{.current.basic.instanceType}}",
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

**Status**: Future Enhancement

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
  commitMessage: "Deploy {{.current.basic.appName}} to {{.current.basic.environment}}"
  mergeStrategy: "squash"
  createPullRequest: false
  files:
    - path: "apps/{{.current.basic.appName}}/config.yaml"
      operation: "update"
      contentTemplate: |
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: {{.current.basic.appName}}-config
        data:
          environment: {{.current.basic.environment}}
          replicas: "{{.current.basic.replicas}}"
```

**Git Operations:**
- File operations support create, update, and delete operations
- Content templates support full variable substitution
- Atomic commits ensure all file changes succeed or fail together
- Branch protection rules are respected and may cause action failure
- Pull request mode enables approval workflows for sensitive changes

### GitHub Workflow

**Status**: Future Enhancement

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
    app_name: "{{.current.basic.appName}}"
    environment: "{{.current.basic.environment}}"
    image_tag: "{{.current.basic.imageTag}}"
    replicas: "{{.current.basic.replicas}}"
```

**Workflow Integration:**
- Workflows must be configured to accept `workflow_dispatch` triggers
- Input parameters are validated against workflow input schema
- Workflow run URLs are captured for status tracking and debugging
- Failed workflows provide detailed error information and logs
- Long-running workflows can optionally be tracked to completion

## Templates and Variables

The orchestrator maintains a map of named values organized by dot-separated paths. Catalog definitions reference these values using `{{.namespace.path.to.value}}` syntax for content generation.

**How it works**: User form data populates `.current` paths, computed values during fulfillment populate `.output` paths sequentially, and static metadata from catalog items populates `.metadata` paths using catalog item IDs. The `.output` namespace accumulates computed values that are available to subsequent fulfillment actions.

**Required Name Field**: All catalog items and bundles must include a required `name` field as the top-level field in their input form for resource identification and naming. This field is always required regardless of other field configurations.

**Form Structure Requirements**: 
- The `name` field must be defined at the top level of the form, outside any group
- Group names must be unique within each catalog item or bundle
- Field names must be unique within each group
- All bundles and catalog items must define input sections with at least the required `name` field

**Variable Syntax**: `{{.namespace.path.to.value}}`

**Input Section Restrictions**: Variables cannot be accessed or used within the input section of catalog documents. The input section only supports static values for defaults, enums, and validation patterns. All variable substitution occurs exclusively during fulfillment processing.

**Variable Scoping Responsibilities**: When bundle components reference the same field names or group names, it is the fulfillment template writer's responsibility to use appropriate scoping and handle any name shadowing. Templates should use fully qualified paths like `{{.current.groupName.fieldName}}` to avoid ambiguity. Future validation enhancements may detect and prevent naming conflicts.

### Namespace Structure

**Four Top-Level Namespaces**:

| Namespace | Purpose | Population Timing | Access Pattern |
|-----------|---------|-------------------|----------------|
| `.current` | Current request's input data | Request processing | `{{.current.groupId.fieldId}}` (current request only) |
| `.output` | Computed values during fulfillment | After each action (sequential) | `{{.output.user-provided-name.computedValue}}` |
| `.metadata` | Static catalog metadata | Catalog loading | `{{.metadata.{catalogItemId}.path}}` |
| `.system` | Platform context & environment | Request processing | `{{.system.timestamp}}` |

**Sequential Fulfillment Processing**: During fulfillment, actions are processed sequentially in the order they appear in the actions array. For each action, the orchestrator processes it in two phases:

1. **Action Execution**: The action is executed using its configured parameters and templates
2. **Output Processing**: After successful execution, any outputs generated by the action are added to the `.output.user-provided-name.*` namespace

The orchestrator builds up the variable namespace progressively:

1. **Initial State**: `.current.*`, `.metadata.*`, and `.system.*` namespaces are available
2. **Action Processing**: Each action is processed in sequence, with each action having access to:
   - `.current.*` values (current request's input data)
   - All `.metadata.*` values from catalog definitions  
   - All `.system.*` platform context values
   - All `.output.*` values accumulated from previous actions in the sequence
3. **Output Accumulation**: After each action completes successfully, its output values are added to the `.output.*` namespace, making them available to all subsequent actions
4. **Template Access**: Each action's template can reference the entire variable namespace built up to that point

**Inter-Scope Communication**: Actions can access the current request's input data via `.current.*` and can reference outputs from previous actions using the user-supplied name in the output namespace. Template writers know the user-supplied name context during template creation since it's provided in the current request.

**Key Design Principle**: Templates are processed at runtime when user-supplied names are available. Output namespacing uses the user-supplied name from the current request's `name` field to create scoped output paths (e.g., `{{.output.webapp.databaseUrl}}` where "webapp" comes from `{{.current.name}}`).

**Note**: `{catalogItemId}` in `.metadata` patterns represents:
- **Individual Items**: The catalog item ID being requested (e.g., `compute-eks-containerapp`)
- **Bundle Components**: The catalog item ID referenced by the component (e.g., `database-aurora-postgresql-standard`)

### Metadata Namespace Organization

The `.metadata` namespace contains static metadata from catalog items. For bundles, each component's metadata becomes available using the catalog item ID as the namespace key.

**Metadata Namespace Population Rules**:
- **Individual CatalogItems**: Catalog item ID → available as `{{.metadata.{catalogItemId}.*}}`
- **Bundle Components**: Referenced catalog item ID → available as `{{.metadata.{catalogItemId}.*}}`
- **Catalog Item Reference**: Both individual items and bundle components always use the full catalog item ID as the metadata key (never component IDs)
- **Static Values**: Metadata contains only constant values loaded from catalog definitions at startup

**Example Bundle Component Mapping**:
```yaml
# Bundle component definition:
components:
  - id: database                    # → {{.metadata.database-aurora-postgresql-standard.*}}
    catalogItem: database-aurora-postgresql-standard
  - id: secrets                     # → {{.metadata.security-parameterstore-standard.*}}
    catalogItem: security-parameterstore-standard
  - id: app                         # → {{.metadata.compute-eks-containerapp.*}}
    catalogItem: compute-eks-containerapp

# Individual CatalogItem usage:
# When requesting compute-eks-containerapp → {{.metadata.compute-eks-containerapp.*}}
```

**Output Namespace Structure**:

The `.output` namespace is organized by the user-supplied `name` field value. Each fulfillment action generates outputs under this user-provided namespace:

```
.output
├── {userSuppliedName}            # From the required 'name' field in input form
│   ├── key1                      # Output values computed during fulfillment
│   ├── key2                      # Each action can add keys under this namespace
│   └── keyN                      # Sequential actions build up this namespace
```

**Examples for Different Scenarios**:

**Individual CatalogItem** (user provides name="myapp"):
```
.output
└── myapp                         # User-supplied name becomes the namespace
    ├── databaseUrl               # Output from database provisioning action
    ├── resourceTags              # Output from tagging action
    └── connectionString          # Output from connection setup action
```

**Bundle Components** (user provides name="webapp"):
```
.output
└── webapp                        # User-supplied bundle name becomes the namespace
    ├── databaseEndpoint          # Output from database component action
    ├── secretsArn                # Output from secrets component action
    └── applicationUrl            # Output from application component action
```

### Path Examples

**Current Request Input Paths**:
```
{{.current.basic.appName}}                     # From basic group (current request)
{{.current.basic.instanceName}}                # From basic group (current request)
{{.current.basic.secretName}}                  # From basic group (current request)
```

**Output Paths** (computed during fulfillment):
```
{{.output.myapp.databaseUrl}}           # Computed connection string (user name: myapp)
{{.output.myapp.resourceTags}}          # Computed resource tags
{{.output.myapp.secretArn}}             # ARN from previous action
{{.output.webapp.applicationUrl}}       # Bundle output (user name: webapp)
```

**Metadata Paths** (static catalog metadata):
```
{{.metadata.database-aurora-postgresql-standard.connectionTemplate}}  # Bundle component
{{.metadata.compute-eks-containerapp.defaultNamespace}}               # Individual item
```

**System Paths** (platform context):
```
{{.system.timestamp}}
{{.system.requestId}} 
{{.system.user.email}}
{{.system.platform.account}}
{{.system.platform.region}}
{{.system.platform.apiKey}}
```

## Variable Reference

This section provides a comprehensive reference for all available variables in each namespace, their types, and descriptions.

### .current Namespace

The `.current` namespace contains all user input from the current request's form submission.

**Structure**: `{{.current.groupId.fieldId}}`

**Available Variables**: Dynamic based on catalog item input form definition
- All field values from user form submission
- Organized by group ID and field ID as defined in the catalog item
- Field values match their declared types (string, number, boolean, arrays for multiselect)

**Examples**:
```
{{.current.name}}                       # string - Required name field
{{.current.basic.instanceName}}         # string - Database instance name
{{.current.basic.instanceClass}}        # string - Selected instance class
{{.current.basic.storageSize}}          # number - Storage size in GB
{{.current.basic.replicas}}             # number - Replica count
{{.current.basic.secrets}}              # array - Multi-select field values
```

### .output Namespace

The `.output` namespace contains computed values from previous actions in the current request.

**Structure**: `{{.output.{userName}.{outputKey}}}`
- `{userName}`: Value from `{{.current.name}}` field
- `{outputKey}`: Key generated by previous action

**Population**: Each action can add key-value pairs to the output namespace scoped by the user-supplied name

**Examples**:
```
{{.output.webapp.databaseUrl}}          # string - Database connection URL
{{.output.webapp.databaseName}}         # string - Created database name
{{.output.webapp.resourceId}}           # string - AWS resource identifier
{{.output.webapp.secretArn}}            # string - AWS Parameter Store ARN
{{.output.webapp.applicationUrl}}       # string - Application endpoint URL
```

### .metadata Namespace

The `.metadata` namespace contains static metadata from catalog item definitions.

**Structure**: `{{.metadata.{catalogItemId}.{metadataField}}}`
- `{catalogItemId}`: Full catalog item ID (e.g., `database-aurora-postgresql-standard`)
- `{metadataField}`: Any field from the catalog item's metadata section

**Available Fields**:
```
{{.metadata.{catalogItemId}.id}}                    # string - Catalog item ID
{{.metadata.{catalogItemId}.name}}                  # string - Display name
{{.metadata.{catalogItemId}.description}}           # string - Description
{{.metadata.{catalogItemId}.version}}               # string - Version number
{{.metadata.{catalogItemId}.category}}              # string - Category name
{{.metadata.{catalogItemId}.owner.team}}            # string - Owning team
{{.metadata.{catalogItemId}.owner.contact}}         # string - Contact email
```

**Custom Metadata Fields** (defined by catalog item author):
```
{{.metadata.database-aurora-postgresql-standard.connectionTemplate}}  # string
{{.metadata.database-aurora-postgresql-standard.defaultPort}}          # string
{{.metadata.compute-eks-containerapp.defaultNamespace}}               # string
{{.metadata.compute-eks-containerapp.clusterEndpoint}}                # string
{{.metadata.security-parameterstore-standard.parameterPath}}          # string
{{.metadata.security-parameterstore-standard.kmsKeyId}}               # string
```

### .system Namespace

The `.system` namespace contains platform-provided context and environment variables.

**Request Context**:
```
{{.system.requestId}}                   # string - Unique request identifier (UUID)
{{.system.timestamp}}                   # string - Request timestamp (ISO 8601)
{{.system.correlationId}}               # string - Correlation ID for tracing
```

**User Context**:
```
{{.system.user.email}}                  # string - User's email address
{{.system.user.name}}                   # string - User's display name
{{.system.user.id}}                     # string - User's unique identifier
{{.system.user.teams}}                  # array - User's team memberships
```

**Platform Context**:
```
{{.system.platform.account}}            # string - AWS account ID
{{.system.platform.region}}             # string - AWS region
{{.system.platform.environment}}        # string - Platform environment (dev/staging/prod)
{{.system.platform.apiKey}}             # string - Platform API key (for external calls)
```

**Generated Values**:
```
{{.system.uuid}}                        # string - Generated UUID
{{.system.shortId}}                     # string - Short random identifier (8 chars)
{{.system.date}}                        # string - Current date (YYYY-MM-DD)
{{.system.time}}                        # string - Current time (HH:MM:SS)
```

### Variable Type Handling

**String Variables**:
- Inserted as-is into templates
- Null/undefined values become empty strings
- Special characters are escaped based on target format (JSON, YAML, etc.)

**Number Variables**:
- Inserted as numeric values (no quotes)
- Null/undefined values become 0 or empty string based on context

**Boolean Variables**:
- Inserted as `true` or `false`
- Null/undefined values become `false`

**Array Variables** (from multiselect fields):
- JSON context: Inserted as JSON array
- String context: Comma-separated values
- YAML context: YAML array format

**Object Variables** (complex metadata):
- JSON context: Inserted as JSON object
- String context: Formatted as key=value pairs
- YAML context: YAML object format

### Scoping Rules

Access to namespace paths is strictly controlled by component type:

- **CatalogItem Fulfillment**: Can reference `.current.*`, `.output.*`, `.system.*`, and `.metadata.*` for the current catalog item and any referenced dependencies
- **CatalogBundle Components**: Components specify catalog item references and dependencies, with variable interpretation occurring during fulfillment execution
- **Action Templates**: Can reference all variable namespaces:
  - `.current.*` - Current request's input form data
  - `.output.user-provided-name.*` - Computed values from previous actions (when names are known)  
  - `.system.*` - Platform context and environment
  - `.metadata.*` - All catalog item metadata (always available using catalog item IDs as keys)

**Important**: Metadata fields contain only static constant values - no variable substitution occurs. All variable substitution occurs exclusively within fulfillment action templates.

**Name Field Usage**: The user-supplied `name` field serves dual purposes:
1. **Resource Identification**: Becomes the basis for AWS resource names, Kubernetes namespaces, etc.
2. **Variable Namespacing**: Creates the `.output.{user-provided-name}.*` namespace where computed fulfillment outputs are stored. The `.current.*` namespace provides access to the current request's input data. This `{user-provided-name}` becomes the dynamic namespace key that scopes all request-specific output data.

## Bundle-to-Component Data Flow

When a bundle is submitted, users fill out the bundle's input form, and the data becomes available to all component fulfillment templates through the `.current` namespace. The `.output` namespace accumulates computed values as each component is processed sequentially.

**Data Flow Process**:
1. **User Input**: User fills out the bundle's defined input form
2. **Data Population**: Form data populates the `.current` namespace with structure `{{.current.groupId.fieldId}}`
3. **Component 1**: Accesses its required input fields and computes outputs, populates `.output.*` namespace
4. **Component 2**: Can reference previous `.output.*` values plus its required `.current.*` fields and `.metadata.*`
5. **Sequential Processing**: Each component builds upon previous computed outputs while accessing its own input fields

**Bundle Form Design**: Bundle authors must design input forms that collect all necessary data for their components. Each bundle defines its own complete input form with all required fields organized into logical groups.

**Example Data Flow**:
```yaml
# Bundle form defines all required fields (using required 'name' field = "webapp"):
# User input becomes available via .current namespace:
# .current.name = "webapp"                          # Required bundle name field
# .current.basic.instanceName = "webapp-db"         # From basic group
# .current.basic.instanceClass = "db.t3.medium"     # From basic group
# .current.basic.secretName = "webapp-secrets"      # From basic group  
# .current.basic.appName = "myapp"                  # From basic group
# .current.basic.containerImage = "nginx:latest"    # From basic group

# Component 1 (Database) uses database-aurora-postgresql-standard catalog item:
# Template can access: {{.metadata.database-aurora-postgresql-standard.connectionTemplate}}
# Template uses: {{.current.basic.instanceName}}, {{.current.basic.instanceClass}}
# Computes and adds to .output:
# .output.webapp.databaseUrl = "postgres://{{.current.basic.instanceName}}.aws.com:5432/db"
# .output.webapp.databaseName = "{{.current.basic.instanceName}}"

# Component 2 (EKS) uses compute-eks-containerapp catalog item:
# Template can access: {{.metadata.compute-eks-containerapp.defaultNamespace}}
# Template uses: {{.output.webapp.databaseUrl}} and {{.current.basic.appName}}
# Computes: .output.webapp.appUrl = "https://{{.current.basic.appName}}.company.com"

# Component 3 (Secrets) uses security-parameterstore-standard catalog item:
# Template can access: {{.metadata.security-parameterstore-standard.parameterPath}}
# Template uses: {{.current.basic.secretName}} and previous outputs
# Can reference: {{.output.webapp.databaseUrl}}, {{.output.webapp.appUrl}}, {{.current.basic.secretName}}

# Key Point: All components share the same .current namespace since it's the same request.
# Inter-component data sharing happens through .output variables scoped by the user-supplied name from .current.name.
```

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

components:
  - id: database
    catalogItem: database-aurora-postgresql-standard
    
  - id: secrets
    catalogItem: security-parameterstore-standard
    dependsOn: [database]
    
  - id: app
    catalogItem: compute-eks-containerapp
    dependsOn: [database, secrets]

input:
  form:
    name: Bundle Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    description: "Unique identifier for this bundle deployment"
    groups:
      - id: basic
        name: Basic Configuration
        fields:
          - id: instanceName
            name: Database Instance Name
            type: string
            required: true
          - id: instanceClass
            name: Instance Class
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: secretName
            name: Secret Name
            type: string
            required: true
          - id: appName
            name: Application Name
            type: string
            required: true
          - id: containerImage
            name: Container Image
            type: string
            required: true
          - id: replicas
            name: Replica Count
            type: number
            default: 2

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

input:
  form:
    name: Resource Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    description: "Unique identifier for this EKS application"
    groups:
      - id: basic
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
            name: Replica Count
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
            summaryTemplate: "Deploy {{.current.basic.appName}} to EKS"
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
                "applicationName": "{{.current.basic.appName}}",
                "containerImage": "{{.current.basic.containerImage}}",
                "replicas": {{.current.basic.replicas}},
                "namespace": "{{.metadata.compute-eks-containerapp.defaultNamespace}}"
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
  connectionTemplate: "host=INSTANCENAME.cluster-xyz.us-west-2.rds.amazonaws.com;port=5432;database=postgres"
  defaultPort: "5432"

input:
  form:
    name: Database Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    description: "Unique identifier for this database instance"
    groups:
      - id: basic
        name: Basic Configuration
        fields:
          - id: instanceName
            name: Database Instance Name
            type: string
            required: true
          - id: instanceClass
            name: Instance Class
            type: select
            enum: [db.t3.micro, db.t3.small, db.t3.medium]
          - id: storageSize
            name: Storage Size (GB)
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
            summaryTemplate: "Aurora PostgreSQL: {{.current.basic.instanceName}}"
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
                "instanceName": "{{.current.basic.instanceName}}",
                "instanceClass": "{{.current.basic.instanceClass}}",
                "allocatedStorage": {{.current.basic.storageSize}},
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
  parameterPath: "/SECRETNAME"
  kmsKeyId: "alias/parameter-store-key"

input:
  form:
    name: Secret Store Name
    type: string
    required: true
    validation:
      pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"
    description: "Unique identifier for this parameter store"
    groups:
      - id: basic
        name: Basic Configuration
        fields:
          - id: secretName
            name: Secret Name
            type: string
            required: true
          - id: secrets
            name: Secret Keys
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
            summaryTemplate: "Create secrets: {{.current.basic.secretName}}"
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
                "parameterPath": "/{{.current.basic.secretName}}",
                "secrets": "{{.current.basic.secrets}}",
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

2. **Validation Scripts** (`/scripts/` directory) - **Core validation in Ruby**
   - `validate-catalog.rb` - Main validation script (Ruby)
   - `validate-single.rb` - Validates individual YAML files (Ruby)
   - `validate-all.sh` - Batch validation wrapper script (Shell)
   - `validate-changed.sh` - Validates only changed files in PR (Shell)

3. **Test Fixtures** (`/tests/` directory)
   - Valid examples that should pass validation
   - Invalid examples with expected error messages
   - Edge cases for comprehensive testing

**Schema Validation Requirements:**

All catalog documents must comply with the following validation rules:

- **Document Structure**: Must include `schemaVersion` and `kind` fields at root level
- **Metadata Requirements**: All items require `id`, `name`, `description`, `version`, `category`, and `owner` fields
- **Input Form Structure**: All catalog items and bundles must contain `input.form` with at least the required `name` field. CatalogItems must also include `input.form.groups` array with at least one group containing fields
- **Required Name Field**: All CatalogItems and CatalogBundles must include a required `name` field as the top-level field in their input form with kebab-case validation pattern: `"^[a-z][a-z0-9-]{2,28}[a-z0-9]$"`
- **Fulfillment Configuration**: Must specify `fulfillment.strategy.mode` and include corresponding action configurations

**What Gets Validated:**

- **Structural Compliance**: YAML structure matches schema requirements
- **Naming Conventions**: All identifiers follow specified patterns (camelCase, kebab-case, etc.)
- **Required Fields**: All mandatory fields are present with valid values
- **Type Constraints**: Field values match their declared types
- **Enum Validation**: Select and multiselect field values match their enum constraints
- **Template Syntax**: Variable references use correct scope and syntax (`{{.namespace.path.field}}`)
- **Cross-References**: Bundle components reference existing CatalogItems
- **Action Configurations**: Each action type has required parameters
- **Variable Reference Validation**: All template variables reference valid scopes (`.current`, `.output`, `.metadata`, `.system`)

### Testing Process

Platform teams follow a structured testing process before submitting catalog changes:

**Local Validation Workflow:**

```bash
# 1. Validate a single service definition
./scripts/validate-single.rb catalog/databases/aurora-postgresql-standard.yaml

# 2. Validate all services in a category
./scripts/validate-catalog.rb catalog/databases/

# 3. Run comprehensive validation before commit
./scripts/validate-all.sh

# 4. Test with sample data (dry run)
./scripts/test-template.rb catalog/databases/aurora-postgresql-standard.yaml sample-data.json
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
  Line 38: Invalid variable reference '{{field.name}}' (should be '{{.current.basic.name}}')
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
      - 'bundles/**'
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
   - Team lead submits PR to add team to CODEOWNERS for their category folder in `/catalog/` of `platform-automation-repository`
   - For bundles: Collaborate with Developer Experience Team who owns `/bundles/` folder
   - Complete catalog training (self-paced documentation review)

### Onboarding Process

1. **Initial Setup** (Day 1)
   - Platform team lead contacts DevX team
   - DevX team provides starter kit with templates
   - Team added to GitHub and CODEOWNERS

2. **First Service Definition** (Days 2-3)
   - Copy template from `/templates/catalog-item-template.yaml`
   - Modify for team's first service (typically simplest offering)
   - Run local validation: `./scripts/validate-single.rb my-service.yaml`
   - Submit PR for review

3. **Review Process**
   - DevX team reviews for schema compliance
   - Architecture team reviews if new patterns introduced
   - Must pass automated validation
   - Merge upon approval

4. **Iteration and Expansion** (Ongoing)
   - Add more services incrementally
   - Evolve from simple to complex offerings
   - Start with JIRA-only fulfillment, evolve to add automation

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

**CatalogBundle IDs:** `bundle-{name}-{variant}`
- name: Descriptive bundle name (webapp, microservice, etc.)
- variant: Differentiator (standard, enterprise, dev)
- Example: `bundle-webapp-production`
- Note: Bundles don't follow category-service-variant pattern since they're cross-domain

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
- `catalog-item.json`: Require metadata (id, name, description, version, category, owner), input.form.groups, fulfillment.strategy.mode, fulfillment.manual.actions
- `catalog-bundle.json`: Require metadata, components array with catalogItem references, input.form with required name field, fulfillment.orchestration
- `common-types.json`: Define enums for categories (compute, databases, security, etc.), field types (string, number, select, etc.), action types (jira-ticket, rest-api); patterns for IDs (kebab-case), variable syntax (`^\{\{\.[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*\}\}$`)

### Ruby Validation Scripts

**Core Requirements:**
- Use JSON Schema validation library for structural validation
- Parse YAML files safely without executing arbitrary code
- Exit codes: 0 (success), 1 (validation error), 2 (system error)
- Output format: `filename:line:column: error message`

**validate-single.rb Purpose:**
Validates a single catalog YAML file against the appropriate JSON schema. Should:
- Load and parse the YAML file safely
- Determine document type from `kind` field (CatalogItem or CatalogBundle)
- Map document type to correct schema file (`catalog-item.json` or `catalog-bundle.json`)
- Validate document structure against schema
- Report validation errors with file location details
- Handle file not found, invalid YAML, and unknown document types

**validate-changed.sh Purpose:**
Validates only files changed in a Git pull request. Should:
- Accept base Git SHA as parameter (defaults to HEAD~1)
- Find changed files in `catalog/` and `bundles/` directories
- Call validate-single.rb for each changed YAML file
- Aggregate results and report total error count
- Exit with error code if any validations fail

**Additional Validations Beyond Schema:**
- **Bundle Component References**: Verify bundle components reference existing CatalogItems in the repository
- **Variable Syntax**: Validate variable references use correct scopes and syntax (`{{.namespace.path.field}}`)
- **JIRA Projects**: Ensure JIRA project keys are uppercase (PLATFORM, DBA, COMPUTE)
- **Field Uniqueness**: Check field IDs are unique within each form group
- **Required Name Field**: Verify all CatalogItems include a required `name` field with kebab-case validation pattern
- **Circular Dependencies**: Detect and prevent circular dependencies in bundle components
- **Component ID Uniqueness**: Ensure component IDs are unique within each bundle
- **Custom Metadata Fields**: Validate custom metadata fields follow naming conventions
- **Template Variable References**: Verify all template variables reference valid scopes

### Test Files
- `valid/`: Include examples with all field types, both action types (jira-ticket, rest-api), cross-component references
- `invalid/missing-required-fields.yaml`: Omit metadata.id, fulfillment.manual.actions
- `invalid/invalid-naming-conventions.yaml`: Use snake_case for fields, PascalCase for IDs
- `invalid/enum-validation-failure.yaml`: Select field with value not in enum list

### Templates
- Include minimal valid structure with TODO comments
- `catalog-item-template.yaml`: Basic metadata, one field, one JIRA action
- `catalog-bundle-template.yaml`: Basic metadata, component references, input form with required name field, orchestration
- `jira-action-template.yaml`: Project, issueType, summaryTemplate with variable examples

### Other Files
- `README.md`: Link to catalog.md, quick start commands, troubleshooting
- `.gitignore`: `*.tmp`, `.DS_Store`, `node_modules/`, `vendor/`, test output files

## Future Enhancements

This section outlines potential catalog capabilities and enhancements. These enhancements represent the evolution path for the catalog system as the platform matures and adoption grows.

- [Advanced Action Types](#advanced-action-types)
- [Enhanced Bundle Capabilities](#enhanced-bundle-capabilities)
- [Advanced Governance Features](#advanced-governance-features)
- [Developer Experience Improvements](#developer-experience-improvements)
- [Platform Intelligence](#platform-intelligence)

The following catalog capabilities are potential future enhancements:

### Advanced Action Types
- **Terraform Configuration**: Infrastructure as Code provisioning with state management
- **Git Commit**: Automated repository updates with pull request workflows  
- **GitHub Workflow**: Automated CI/CD pipeline triggering with workflow dispatch
- **Webhook Action**: Generic outbound webhook invocation for external system notifications
- **ServiceNow Integration**: Direct integration with ServiceNow for enterprise ITSM
- **Slack/Teams Notifications**: Direct messaging integration for status updates
- **Email Notifications**: SMTP-based email actions for approvals and notifications

### Enhanced Bundle Capabilities
- **Parallel Execution**: Execute independent components in parallel when no dependencies exist
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
