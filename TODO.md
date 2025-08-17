# TODO: Critical Path - Schema Validation Implementation

## For: Catalog Agent (2-person team)

**Priority**: CRITICAL PATH - BLOCKS ALL OTHER DEVELOPMENT

**Epic**: Q3 2025 Foundation Epic
**Success Metric**: Schema specification complete with 100% validation coverage

## Background

According to the roadmap, schema design is the critical path for the entire Platform Automation Orchestrator (PAO) project. The implementation strategy explicitly states: "Catalog schema design is the critical path - all service development depends on stable schema specification. Schema team leads with complete specification before service implementation begins."

The Service Team and DevCtl Team are waiting for stable schema definitions before they can begin their core API and portal development work.

## Task: Implement CatalogItem Schema Validation System

Create a comprehensive JSON Schema validation system for CatalogItem definitions as specified in `catalog.md`.

### Deliverables

1. **JSON Schema Files** (`/schema/` directory):
   - `catalog-item-v1.json` - Complete JSON Schema for CatalogItem
   - `catalog-bundle-v1.json` - Complete JSON Schema for CatalogBundle  
   - `field-types.json` - Schema definitions for all field types
   - `action-types.json` - Schema definitions for all action types

2. **Validation Script** (`/scripts/validate.js` or `/scripts/validate.go`):
   - CLI tool that validates YAML files against schemas
   - Supports both individual files and directory scanning
   - Provides detailed error messages with line numbers
   - Returns appropriate exit codes for CI/CD integration

3. **Sample Catalog Items** (`/catalog/` directories):
   - 5+ validated sample items demonstrating all action types:
     - `databases/postgresql-standard.yaml` 
     - `compute/eks-containerapp.yaml`
     - `security/parameterstore-standard.yaml`
     - `messaging/sqs-queue.yaml`
     - `storage/s3-bucket.yaml`
   - Each sample must pass validation
   - Cover all field types and action types

4. **CI/CD Integration** (`.github/workflows/validate.yml`):
   - GitHub Actions workflow that validates all catalog items on PR
   - Blocks merges if validation fails
   - Provides clear feedback to contributors

### Schema Requirements

Based on `catalog.md`, the schema must validate:

**Metadata Section**:
- `id` follows kebab-case pattern: `{category}-{service}-{variant}`
- `name` is 1-100 characters
- `description` is 50-500 characters
- `version` follows semantic versioning
- `category` matches predefined list
- `owner` has required `team` and `contact` fields

**Presentation Section**:
- Form groups have unique IDs
- Field IDs are unique within the item
- Field types match supported types (string, number, boolean, select, etc.)
- Validation rules are type-appropriate
- Required fields are properly marked

**Fulfillment Section**:
- Strategy mode is either "manual" or "automatic"
- Manual actions have valid JIRA configuration
- Automatic actions have valid action type configurations
- Templates use proper variable syntax: `{{scope.field}}`
- Output mappings are properly defined

**Action Type Validation**:
- `jira-ticket`: Required project, issueType, summaryTemplate
- `rest-api`: Valid URL, HTTP method, proper authentication
- `terraform`: Valid contentTemplate, filename patterns
- `github-workflow`: Valid repository and workflow references
- `webhook`: Valid endpoint URL and method

**Variable System**:
- Template syntax: `{{scope.field}}` where scope is fields, metadata, request, system, env, secrets, output
- Function calls: `{{function(args)}}` for uuid(), timestamp(), upper(), concat(), replace(), json(), base64()
- Proper escaping for special characters

### Validation Rules

1. **Naming Conventions**:
   - Type names (kind): PascalCase
   - Field names: camelCase  
   - File names: kebab-case
   - IDs and references: kebab-case
   - Terraform identifiers: snake_case (transformed via replace function)

2. **Cross-Reference Validation**:
   - CatalogBundle components reference valid CatalogItem IDs
   - Dependency references (`dependsOn`) point to valid component IDs
   - Output references match declared outputs
   - Variable references use valid scopes and syntax

3. **Security Validation**:
   - No hardcoded secrets or sensitive data
   - Proper variable usage for sensitive fields
   - Valid authentication configurations

### Success Criteria

- [ ] JSON Schema validates all examples in `catalog.md`
- [ ] Validation script provides clear, actionable error messages  
- [ ] CI/CD workflow blocks invalid catalog items
- [ ] 5+ sample catalog items pass validation
- [ ] Platform teams can validate their service definitions independently
- [ ] Schema is stable enough for Service Team to begin API development

### Dependencies

- Review `catalog.md` for complete schema specification
- Coordinate with Service Team on JSON Schema requirements for API consumption
- Ensure DevCtl Team can use schema for form generation

### Timeline

**Week 1**: JSON Schema creation and basic validation script
**Week 2**: Sample catalog items and comprehensive testing  
**Week 3**: CI/CD integration and platform team onboarding
**Week 4**: Schema finalization and handoff to Service Team

This task directly enables the Q3 2025 Foundation Epic success criteria and unblocks the entire development effort.