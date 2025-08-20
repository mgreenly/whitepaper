# Platform Automation Orchestrator - Catalog Summary

## Core Purpose
The catalog repository (`platform-automation-repository`) defines platform service offerings through schema-driven YAML documents that enable automated self-service provisioning.

## Document Types

### CatalogBundle (Composite Services)
```yaml
schemaVersion: catalog/v1
kind: CatalogBundle
metadata: {id, name, description, version, owner}
components: [{id, catalogItem, dependsOn}]  # Sequential processing
input.form: {name (required), groups: [{fields}]}
fulfillment.orchestration: {mode: sequential}
```

### CatalogItem (Individual Services)  
```yaml
schemaVersion: catalog/v1
kind: CatalogItem
metadata: {id, name, description, version, category, owner}
input.form: {name (required), groups: [{fields}]}
fulfillment:
  strategy.mode: manual|automatic
  manual.actions: [{type: jira-ticket, config}]
  automatic.actions: [{type: rest-api|git-commit|github-workflow, config}]
```

## Critical Requirements
- **Required Name Field**: All forms must include `name: string, required: true, pattern: "^[a-z][a-z0-9-]{2,28}[a-z0-9]$"`
- **Form Structure**: All fields (except top-level name) must be in `input.form.groups` array
- **Naming**: IDs use kebab-case, field names use camelCase, kinds use PascalCase

## Variable System
**Template Syntax**: `{{.namespace.path.to.value}}`

**Four Namespaces**:
- `.current.*` - User form input (e.g., `{{.current.basic.instanceName}}`)
- `.output.*` - Computed values from previous actions (e.g., `{{.output.databaseUrl}}`)
- `.metadata.*` - Static catalog metadata (e.g., `{{.metadata.database-aurora-postgresql-standard.defaultPort}}`)
- `.system.*` - Platform context (e.g., `{{.system.user.email}}`, `{{.system.requestId}}`)

**Scoping Rules**:
- Variables only work in fulfillment templates, not input sections
- Sequential action processing: each action accesses all previous `.output.*` values
- Bundle components share `.current.*` namespace but use catalog item IDs for `.metadata.*`

## Action Types

### JIRA Ticket
```yaml
type: jira-ticket
config:
  ticket: {project, issueType, summaryTemplate, descriptionTemplate}
```

### REST API
```yaml
type: rest-api  
config:
  endpoint: {url, method}
  body: {type: json, contentTemplate}
```

## Field Types
`string, number, boolean, select, multiselect, date, file, textarea, password, email`

## Repository Structure
```
catalog/{category}/*.yaml     # CatalogItems by domain
bundles/*.yaml               # CatalogBundles
schema/*.json               # JSON Schema definitions
scripts/*.rb               # Ruby validation scripts
```

## Validation Requirements
- JSON Schema compliance
- Naming convention enforcement  
- Variable syntax validation (`{{.namespace.path}}`)
- Cross-reference validation (bundle → catalog item)
- Required field validation
- CODEOWNERS enforcement per category

## Key Patterns
- **Progressive Enhancement**: Manual JIRA → Automated fulfillment
- **Team Ownership**: Platform teams own their catalog categories
- **Schema Evolution**: Version-controlled schema with backward compatibility
- **Error Handling**: All failures require manual intervention (retry/abort/escalate)