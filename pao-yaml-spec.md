# Spec: Platform Automation Orchestrator (PAO)

**DRAFT SPECIFICATION**

---

**Important Notice:** This is a draft specification generated with the assistance of AI agents. No organization-specific proprietary information was used in its creation. This document is intended solely as inspiration for the development of the actual Platform Automation Orchestrator specification and should not be considered a final or authoritative technical reference.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overview](#2-overview)
   - [2.1 Document Architecture](#21-document-architecture)
   - [2.2 Repository Structure](#22-repository-structure)
   - [2.3 Document Format Standards](#23-document-format-standards)
3. [CatalogBundle](#3-catalogbundle)
   - [3.1 Sample Document](#31-sample-document)
   - [3.2 Document Structure](#32-document-structure)
   - [3.3 Bundle Composition](#33-bundle-composition)
4. [CatalogItem](#4-catalogitem)
   - [4.1 Sample Document](#41-sample-document)
   - [4.2 Document Structure](#42-document-structure)
   - [4.3 Header Section](#43-header-section)
   - [4.4 Presentation Section](#44-presentation-section)
   - [4.5 Fulfillment Section](#45-fulfillment-section)
     - [4.5.1 Fulfillment Structure](#451-fulfillment-structure)
     - [4.5.2 Manual Fulfillment](#452-manual-fulfillment)
     - [4.5.3 Automation Sequence](#453-automation-sequence)
     - [4.5.4 Automation Step Types](#454-automation-step-types)
     - [4.5.5 Step Execution Model](#455-step-execution-model)
5. [UpgradeOperation](#5-upgradeoperation)
   - [5.1 Sample Document](#51-sample-document)
   - [5.2 Document Structure](#52-document-structure)
   - [5.3 Operation Targets](#53-operation-targets)
   - [5.4 Upgrade Execution](#54-upgrade-execution)
6. [UpdateOperation](#6-updateoperation)
   - [6.1 Sample Document](#61-sample-document)
   - [6.2 Document Structure](#62-document-structure)
   - [6.3 Update Execution](#63-update-execution)
7. [Presentation Field Types](#7-presentation-field-types)
   - [7.1 Sample Field Definitions](#71-sample-field-definitions)
   - [7.2 Field Type Specifications](#72-field-type-specifications)
   - [7.3 Field Properties](#73-field-properties)
8. [Processing Model](#8-processing-model)
   - [8.1 Document Discovery](#81-document-discovery)
   - [8.2 Catalog Generation](#82-catalog-generation)
   - [8.3 Request Fulfillment](#83-request-fulfillment)
9. [Extensibility](#9-extensibility)
10. [Future Considerations](#10-future-considerations)

---

## 1. Introduction

This document specifies the structure and schema for the Platform Automation Orchestrator (PAO) catalog definition system. The PAO, as described in the Reference Architecture, serves as the central coordination point through which Platform Teams define and expose their service offerings to development teams. This specification defines the document formats, schemas, and structures that comprise the PAO catalog, enabling automated service provisioning and a unified self-service developer experience.

The PAO system uses a document-driven approach where each platform service offering is defined through structured YAML documents. These documents serve dual purposes: they define the customer-facing interface for requesting services and specify the technical implementation for service fulfillment. This decoupling allows Platform Teams to maintain ownership of their services while participating in a unified, orchestrated delivery model.

## 2. Overview

### 2.1 Document Architecture

The PAO catalog consists of multiple document types that can exist as standalone files or be embedded within other documents. All catalog documents are stored in the PAO Repository, a GitHub repository that serves as the single source of truth for platform service definitions.

### 2.2 Repository Structure

The PAO Repository follows a hierarchical structure designed to organize offerings by their architectural domains:

```
pao-repository/
├── catalog/
│   ├── compute/
│   │   ├── eks-container-app/
│   │   └── ec2-vm-app/
│   ├── databases/
│   │   ├── mysql/
│   │   └── postgres/
│   ├── messaging/
│   ├── networking/
│   └── storage/
```

Each category folder contains one or more offering folders, grouping architecturally related services. This structure enables logical organization while maintaining flexibility for Platform Teams to define their services according to their domain expertise.

### 2.3 Document Format Standards

- **Storage Format**: All documents in the PAO Repository are stored in YAML format to optimize human readability and ease of maintenance
- **Runtime Format**: The PAO Service converts YAML to JSON upon reading, with all API communications utilizing JSON format
- **Schema Validation**: All documents must conform to defined JSON Schema specifications for their respective document types
- **Versioning**: All document versions use semantic versioning (semver) specification, supporting major.minor.patch with optional pre-release and metadata fields (e.g., "2.1.0-beta.1+build.20250816")

## 3. CatalogBundle

The CatalogBundle represents a collection of related CatalogItems that can be provisioned together as a cohesive solution. It defines dependencies between services and specifies which items are required versus optional components.

### 3.1 Sample Document

```yaml
# Header - Bundle metadata
name: "Full Stack Web Application"
version: "2.1.0"
description: "Complete web application stack with database and monitoring"
owner: "platform-solutions-team"
tags: ["web-app", "full-stack", "solution"]

# Bundle composition - Required and optional items
bundle:
  required_items:
    - catalog_item: "eks-container-app"
      version: ">=1.2.0"
      parameters:
        app_type: "web-frontend"
    - catalog_item: "postgres-database"
      version: ">=2.0.0"
      
  optional_items:
    - catalog_item: "redis-cache"
      version: ">=1.1.0"
      default_enabled: false
    - catalog_item: "application-monitoring"
      version: ">=1.0.0"
      default_enabled: true

# Presentation - Bundle-level configuration
presentation:
  bundle_fields:
    - name: "solution_name"
      type: "string"
      required: true
      help_text: "Name for this solution deployment"
    - name: "enable_ha"
      type: "boolean"
      default: false
      help_text: "Enable high availability mode"
```

### 3.2 Document Structure

A CatalogBundle consists of three mandatory top-level objects:

- **Header**: Contains metadata and bundle-level properties
- **Bundle**: Defines required and optional CatalogItems with version constraints
- **Presentation**: Collects bundle-level parameters that may affect multiple items

### 3.3 Bundle Composition

- **required_items**: CatalogItems that must be provisioned for the bundle
- **optional_items**: CatalogItems that can be optionally included
- **version**: Version constraints for each included CatalogItem
- **parameters**: Default or fixed parameters passed to individual items
- **default_enabled**: Whether optional items are enabled by default

## 4. CatalogItem

The CatalogItem represents the fundamental unit of a service offering in the PAO catalog. It encapsulates all information necessary to present, collect, and fulfill a service request.

### 4.1 Sample Document

```yaml
# Header - Basic metadata
name: "EKS Container Application"
version: "1.2.0"
description: "Managed Kubernetes application deployment"
owner: "platform-compute-team"
tags: ["containers", "kubernetes", "compute"]

# Presentation - User interface definition
presentation:
  fields:
    - name: "app_name"
      type: "string"
      required: true
      max_length: 50
    - name: "environment"
      type: "selection"
      oneof: ["dev", "staging", "prod"]
      required: true
    - name: "replicas"
      type: "int"
      min_value: 1
      max_value: 10
      default: 2

# Fulfillment - Manual and automation definitions
fulfillment:
  manual:
    system: "jira"
    template:
      project: "PLATFORM"
      issue_type: "Service Request"
      summary: "Deploy {{ app_name }} to {{ environment }}"
      description: |
        Service Request: EKS Container Application
        Application: {{ app_name }}
        Environment: {{ environment }}
        Replicas: {{ replicas }}
        
        Please provision the requested Kubernetes application.
      
  automation:
    steps:
      - name: "provision_infrastructure"
        type: "TerraformFile"
        template:
          module_source: "./modules/eks-app"
          variables:
            app_name: "{{ app_name }}"
            environment: "{{ environment }}"
            replica_count: "{{ replicas }}"
        verification:
          type: "terraform_state"
          resource_count: 5
```

### 4.2 Document Structure

A CatalogItem consists of three mandatory top-level objects:

- **Header**: Contains metadata and document-level properties
- **Presentation**: Defines the user interface elements and data collection requirements
- **Fulfillment**: Specifies the automation templates and actions for service provisioning

### 4.3 Header Section

The Header section provides essential metadata about the catalog item, including:

- **name**: The display name of the service offering
- **version**: Semantic versioning (semver) information for the catalog item definition, supporting full specification including pre-release and metadata fields (e.g., "1.2.0-alpha.1+build.123")
- **description**: A brief description of the service
- **owner**: The Platform Team responsible for this offering
- **tags**: Searchable metadata tags for categorization
- **dependencies**: References to other catalog items or prerequisites

### 4.4 Presentation Section

The Presentation section defines the form structure for collecting service request parameters and supports field groups, display ordering, validation rules, and help text for end users.

### 4.5 Fulfillment Section

The Fulfillment section defines how service requests are processed, containing both manual fallback procedures and automated execution sequences. All CatalogItems must provide manual fulfillment instructions as a safety net, with optional automation for improved efficiency and consistency.

#### 4.5.1 Fulfillment Structure

The Fulfillment section contains two mandatory top-level objects:

- **Manual**: Fallback instructions for manual processing (required for all items)
- **Automation**: Sequence of automated steps for service provisioning (optional)

#### 4.5.2 Manual Fulfillment

All catalog items must define manual fulfillment procedures to ensure service delivery continuity when automation fails or is unavailable.

**Manual System Types:**
- **jira**: Creates tickets in JIRA for manual processing
- **servicenow**: Creates tickets in ServiceNow (future extension)
- **email**: Sends structured email requests to service teams
- **webhook**: Posts to custom ticketing systems

**JIRA Manual Configuration:**
```yaml
manual:
  system: "jira"
  template:
    project: "PLATFORM"
    issue_type: "Service Request"
    summary: "{{ service_name }} - {{ requester.user_id }}"
    description: |
      Service: {{ catalog_item.name }}
      Version: {{ catalog_item.version }}
      Requester: {{ requester.user_id }} ({{ requester.team }})
      
      Parameters:
      {% for param in parameters %}
      - {{ param.name }}: {{ param.value }}
      {% endfor %}
    priority: "Medium"
    assignee: "{{ catalog_item.owner }}"
    labels: ["pao-request", "{{ catalog_item.tags | join(',') }}"]
```

#### 4.5.3 Automation Sequence

Automation defines a sequence of steps that execute in order, with built-in verification, retry logic, and fallback to manual processing.

**Automation Properties:**
- **steps**: Ordered sequence of automation actions
- **retry_policy**: Global retry configuration for failed steps
- **timeout**: Maximum execution time for the entire sequence
- **fallback_on_failure**: Automatically create manual tickets for failed steps

**Sample Automation Configuration:**
```yaml
automation:
  retry_policy:
    max_attempts: 3
    backoff_strategy: "exponential"
    initial_delay: "30s"
    max_delay: "300s"
  timeout: "30m"
  fallback_on_failure: true
  
  steps:
    - name: "validate_prerequisites"
      type: "HttpPost"
      template:
        url: "https://validation-api.example.com/validate"
        headers:
          Authorization: "Bearer {{ secrets.api_token }}"
        body:
          service: "{{ app_name }}"
          environment: "{{ environment }}"
      verification:
        type: "http_status"
        expected_status: 200
      retry_policy:
        max_attempts: 2
        
    - name: "provision_infrastructure"
      type: "TerraformFile"
      depends_on: ["validate_prerequisites"]
      template:
        module_source: "./modules/eks-app"
        variables:
          app_name: "{{ app_name }}"
          environment: "{{ environment }}"
          replica_count: "{{ replicas }}"
      verification:
        type: "terraform_state"
        resource_count: 5
        required_outputs: ["cluster_endpoint", "service_url"]
        
    - name: "configure_monitoring"
      type: "GitHubWorkflow"
      depends_on: ["provision_infrastructure"]
      template:
        repository: "platform-team/monitoring-setup"
        workflow_id: "setup-monitoring.yml"
        inputs:
          service_name: "{{ app_name }}"
          environment: "{{ environment }}"
          cluster_endpoint: "{{ steps.provision_infrastructure.outputs.cluster_endpoint }}"
      verification:
        type: "workflow_status"
        expected_status: "success"
```

#### 4.5.4 Automation Step Types

**TerraformFile**
- **Purpose**: Generate and apply Terraform configurations
- **Template Fields**:
  - `module_source`: Path to Terraform module
  - `variables`: Input variables for the module
  - `backend_config`: Backend configuration overrides
- **Verification Options**:
  - `terraform_state`: Verify resource count and outputs
  - `resource_health`: Check resource health status

**GitHubWorkflow**
- **Purpose**: Trigger GitHub Actions workflows
- **Template Fields**:
  - `repository`: Target repository (org/repo format)
  - `workflow_id`: Workflow file name or ID
  - `inputs`: Workflow input parameters
  - `ref`: Branch or tag reference (default: main)
- **Verification Options**:
  - `workflow_status`: Check workflow completion status
  - `artifact_exists`: Verify specific artifacts were created

**HttpPost/HttpPut**
- **Purpose**: Execute HTTP requests to external APIs
- **Template Fields**:
  - `url`: Target endpoint URL
  - `headers`: HTTP headers
  - `body`: Request payload
  - `authentication`: Auth configuration
- **Verification Options**:
  - `http_status`: Expected HTTP status code
  - `response_body`: JSON path validation of response
  - `headers_present`: Required response headers

**JiraTicket**
- **Purpose**: Create JIRA tickets for semi-automated workflows
- **Template Fields**:
  - `project`: JIRA project key
  - `issue_type`: Type of issue to create
  - `summary`: Ticket summary
  - `description`: Detailed description
  - `assignee`: Ticket assignee
- **Verification Options**:
  - `ticket_status`: Monitor ticket status changes
  - `resolution_time`: Maximum time for ticket resolution

#### 4.5.5 Step Execution Model

**Sequential Execution:**
- Steps execute in defined order by default
- Each step must complete successfully before the next begins
- Failed steps halt execution unless retry policy permits continuation

**Dependency Management:**
- `depends_on`: Explicit step dependencies
- Steps can reference outputs from previous steps using `{{ steps.step_name.outputs.key }}`
- Circular dependencies are detected and rejected during validation

**Verification and Retry Logic:**
- Each step includes verification criteria to determine success/failure
- Failed verification triggers retry according to step-specific or global retry policy
- After max retry attempts, step is marked as failed
- Failed steps can trigger automatic fallback to manual processing

**Step Status Tracking:**
- `pending`: Step queued for execution
- `running`: Step currently executing
- `verifying`: Step completed, verification in progress
- `completed`: Step and verification successful
- `failed`: Step failed after all retry attempts
- `skipped`: Step skipped due to failed dependencies

**Manual Fallback Integration:**
- When `fallback_on_failure: true`, failed automation steps automatically generate manual tickets
- Manual tickets include context from failed automation attempts
- Manual tickets reference specific step that failed and error details
- Service teams can complete work manually and mark automation steps as resolved

## 5. UpgradeOperation

The UpgradeOperation document type defines major lifecycle changes to existing services that may require resource recreation or breaking changes. Upgrade operations are designed for scenarios like database version migrations, framework upgrades, or infrastructure platform transitions.

### 5.1 Sample Document

```yaml
# Header - Operation metadata
name: "postgres-major-upgrade"
version: "1.0.0"
description: "Upgrade PostgreSQL from version 14 to version 15"
owner: "platform-data-team"
tags: ["database", "postgres", "upgrade", "major-version"]

# Target specification - What this operation can upgrade
targets:
  catalog_items:
    - name: "postgres-database"
      version_range: ">=2.0.0, <3.0.0"
      required_parameters: ["database_name", "current_version"]
  destructive: true
  downtime_required: true
  estimated_duration: "45m"

# Presentation - Parameters for upgrade operation
presentation:
  fields:
    - name: "target_version"
      type: "selection"
      oneof: ["15.1", "15.2", "15.3"]
      required: true
      help_text: "Target PostgreSQL version"
    
    - name: "backup_retention"
      type: "integer"
      min_value: 7
      max_value: 90
      default: 30
      help_text: "Days to retain pre-upgrade backup"
    
    - name: "maintenance_window"
      type: "datetime"
      required: true
      help_text: "Scheduled maintenance window for upgrade"
    
    - name: "rollback_plan"
      type: "boolean"
      default: true
      help_text: "Create rollback plan before upgrade"

# Fulfillment - Manual and automation for upgrade
fulfillment:
  manual:
    system: "jira"
    template:
      project: "PLATFORM"
      issue_type: "Major Upgrade"
      summary: "PostgreSQL Major Upgrade: {{ database_name }} to v{{ target_version }}"
      description: |
        PostgreSQL Major Version Upgrade
        
        Database: {{ database_name }}
        Current Version: {{ current_version }}
        Target Version: {{ target_version }}
        Maintenance Window: {{ maintenance_window }}
        
        CRITICAL: This is a destructive operation requiring downtime.
        
        Pre-upgrade checklist:
        - [ ] Verify backup completion
        - [ ] Confirm maintenance window
        - [ ] Review rollback procedure
      priority: "High"
      
  automation:
    pre_execution_checks:
      - verify_target_compatibility
      - check_backup_status
      - validate_maintenance_window
    
    steps:
      - name: "create_backup"
        type: "TerraformFile"
        template:
          module_source: "./modules/postgres-backup"
          variables:
            database_name: "{{ database_name }}"
            backup_retention: "{{ backup_retention }}"
        verification:
          type: "backup_completion"
          timeout: "20m"
          
      - name: "upgrade_database"
        type: "TerraformFile"
        depends_on: ["create_backup"]
        template:
          module_source: "./modules/postgres-upgrade"
          variables:
            database_name: "{{ database_name }}"
            target_version: "{{ target_version }}"
            maintenance_window: "{{ maintenance_window }}"
        verification:
          type: "version_check"
          expected_version: "{{ target_version }}"
          
      - name: "validate_upgrade"
        type: "HttpPost"
        depends_on: ["upgrade_database"]
        template:
          url: "https://db-validation.example.com/validate"
          body:
            database: "{{ database_name }}"
            expected_version: "{{ target_version }}"
        verification:
          type: "http_status"
          expected_status: 200
```

### 5.2 Document Structure

An UpgradeOperation consists of four mandatory top-level objects:

- **Header**: Contains metadata and operation-level properties
- **Targets**: Specifies which CatalogItems this operation can upgrade
- **Presentation**: Defines parameters needed for the upgrade operation
- **Fulfillment**: Contains manual and automated procedures for executing the upgrade

### 5.3 Operation Targets

The Targets section clearly defines the scope and constraints of the upgrade operation:

**Target Properties:**
- **catalog_items**: Array of CatalogItems this operation can upgrade
- **destructive**: Boolean indicating if operation may destroy/recreate resources
- **downtime_required**: Boolean indicating if operation requires service downtime
- **estimated_duration**: Expected time for operation completion
- **prerequisites**: Required conditions before operation can execute

**CatalogItem Target Specification:**
```yaml
targets:
  catalog_items:
    - name: "postgres-database"
      version_range: ">=2.0.0, <3.0.0"  # Semver range specification
      required_parameters: ["database_name", "current_version"]
      optional_parameters: ["backup_strategy"]
    - name: "mysql-database"
      version_range: ">=1.5.0"
      required_parameters: ["database_name"]
```

### 5.4 Upgrade Execution

**Pre-execution Validation:**
- Verify target CatalogItem is compatible with upgrade operation
- Check that current service instance matches version requirements
- Validate all required parameters are provided
- Confirm maintenance window and downtime requirements

**Execution Characteristics:**
- Upgrade operations are inherently more complex than initial provisioning
- May require service downtime and resource recreation
- Include comprehensive backup and rollback procedures
- Support both automated execution and manual fallback procedures
- Track upgrade progress and provide detailed status reporting

## 6. UpdateOperation

The UpdateOperation document type defines minor modifications to existing services that can be performed without resource destruction or service recreation. Update operations handle configuration changes, scaling, and non-breaking modifications.

### 6.1 Sample Document

```yaml
# Header - Operation metadata
name: "postgres-scale-update"
version: "1.1.0"
description: "Update PostgreSQL instance size and storage"
owner: "platform-data-team"
tags: ["database", "postgres", "scaling", "update"]

# Target specification - What this operation can update
targets:
  catalog_items:
    - name: "postgres-database"
      version_range: ">=2.0.0"
      required_parameters: ["database_name"]
  destructive: false
  downtime_required: false
  estimated_duration: "15m"

# Presentation - Parameters for update operation  
presentation:
  fields:
    - name: "instance_class"
      type: "selection"
      oneof: ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large"]
      help_text: "Database instance class"
    
    - name: "allocated_storage"
      type: "integer"
      min_value: 20
      max_value: 1000
      help_text: "Storage size in GB"
    
    - name: "backup_retention"
      type: "integer"
      min_value: 1
      max_value: 35
      help_text: "Backup retention period in days"
    
    - name: "description"
      type: "textarea"
      max_length: 500
      help_text: "Updated service description"

# Fulfillment - Manual and automation for updates
fulfillment:
  manual:
    system: "jira"
    template:
      project: "PLATFORM"
      issue_type: "Service Update"
      summary: "Update {{ database_name }} configuration"
      description: |
        PostgreSQL Configuration Update
        
        Database: {{ database_name }}
        
        Requested Changes:
        {% if instance_class %}
        - Instance Class: {{ instance_class }}
        {% endif %}
        {% if allocated_storage %}
        - Storage: {{ allocated_storage }}GB
        {% endif %}
        {% if backup_retention %}
        - Backup Retention: {{ backup_retention }} days
        {% endif %}
      
  automation:
    steps:
      - name: "update_configuration"
        type: "TerraformFile"
        template:
          module_source: "./modules/postgres-update"
          variables:
            database_name: "{{ database_name }}"
            instance_class: "{{ instance_class }}"
            allocated_storage: "{{ allocated_storage }}"
            backup_retention: "{{ backup_retention }}"
        verification:
          type: "configuration_check"
          expected_changes: ["instance_class", "allocated_storage"]
          
      - name: "update_metadata"
        type: "HttpPut"
        depends_on: ["update_configuration"]
        template:
          url: "https://catalog-api.example.com/services/{{ database_name }}"
          body:
            description: "{{ description }}"
            last_updated: "{{ current_timestamp }}"
        verification:
          type: "http_status"
          expected_status: 200
```

### 6.2 Document Structure

An UpdateOperation consists of four mandatory top-level objects:

- **Header**: Contains metadata and operation-level properties  
- **Targets**: Specifies which CatalogItems this operation can update
- **Presentation**: Defines parameters for the update operation
- **Fulfillment**: Contains manual and automated procedures for executing updates

### 6.3 Update Execution

**Non-destructive Operations:**
- Update operations must not destroy or recreate existing resources
- Changes should be applied in-place without service interruption
- Support for configuration drift detection and correction
- Rollback capabilities for failed updates

**Supported Update Types:**
- **Scaling**: Instance size, storage capacity, replica count
- **Configuration**: Settings, parameters, feature flags  
- **Metadata**: Descriptions, tags, ownership information
- **Security**: Access policies, network rules, encryption settings
- **Monitoring**: Alerting thresholds, logging configuration

## 7. Presentation Field Types

The Presentation layer supports comprehensive field types for collecting service request parameters. The basic field types provide complete coverage for most use cases, with extensibility for specialized domain-specific types when needed.

### 7.1 Sample Field Definitions

```yaml
# Basic data types - Core field types
presentation:
  fields:
    # String fields - Text input with validation
    - name: "application_name"
      type: "string"
      required: true
      max_length: 50
      min_length: 3
      regexp: "^[a-z][a-z0-9-]*$"
      help_text: "Lowercase alphanumeric with hyphens"

    # Integer fields - Whole number input
    - name: "instance_count"
      type: "integer"
      min_value: 1
      max_value: 100
      default: 3
      help_text: "Number of instances to deploy"

    # Number fields - Decimal values
    - name: "cpu_allocation"
      type: "number"
      min_value: 0.5
      max_value: 16.0
      step: 0.5
      default: 2.0
      help_text: "CPU cores (supports half-core increments)"

    # Boolean fields - True/false selections
    - name: "enable_monitoring"
      type: "boolean"
      default: true
      help_text: "Enable application monitoring"

    # Date fields - Date selection
    - name: "deployment_date"
      type: "date"
      format: "iso8601"
      min_date: "2025-01-01"
      help_text: "Target deployment date"

    # DateTime fields - Date and time selection
    - name: "maintenance_window"
      type: "datetime"
      format: "iso8601"
      timezone: "UTC"
      help_text: "Maintenance window start time"

    # Time fields - Time-only input
    - name: "backup_time"
      type: "time"
      format: "HH:MM"
      default: "02:00"
      help_text: "Daily backup time"

    # Selection fields - Single choice from options
    - name: "environment"
      type: "selection"
      oneof: ["development", "staging", "production"]
      required: true
      help_text: "Target deployment environment"

    # Multiselect fields - Multiple choices
    - name: "features"
      type: "multiselect"
      options: ["logging", "metrics", "tracing", "alerting"]
      min_selections: 1
      max_selections: 3
      help_text: "Select observability features"

    # Percentage fields - Percentage values
    - name: "cpu_threshold"
      type: "percentage"
      min_value: 0
      max_value: 100
      default: 80
      help_text: "CPU utilization alert threshold"

    # Textarea fields - Multi-line text
    - name: "description"
      type: "textarea"
      max_length: 500
      rows: 4
      help_text: "Detailed service description"
```

### 7.2 Basic Field Type Specifications

#### 7.2.1 Basic Data Types

**String**
- **Purpose**: Single-line text input with validation
- **Validation Options**:
  - `max_length`: Maximum character count
  - `min_length`: Minimum character count  
  - `regexp`: Regular expression pattern
  - `format`: Predefined format (email, url, hostname)
- **Example**: Application names, identifiers, descriptions

**Integer**
- **Purpose**: Whole number input with range constraints
- **Validation Options**:
  - `min_value`: Minimum allowed value
  - `max_value`: Maximum allowed value
  - `step`: Increment step size
- **Example**: Instance counts, port numbers, replica counts

**Number**
- **Purpose**: Decimal number input with precision control
- **Validation Options**:
  - `min_value`: Minimum allowed value
  - `max_value`: Maximum allowed value
  - `step`: Increment step size
  - `precision`: Decimal places
- **Example**: CPU allocation, memory ratios, scaling factors

**Boolean**
- **Purpose**: True/false selection
- **Validation Options**:
  - `default`: Default true/false value
- **Example**: Feature toggles, enable/disable options

#### 7.2.2 Temporal Types

**Date**
- **Purpose**: Date selection without time component
- **Validation Options**:
  - `format`: Date format specification (iso8601, yyyy-mm-dd)
  - `min_date`: Earliest allowed date
  - `max_date`: Latest allowed date
- **Example**: Deployment dates, expiration dates

**DateTime**
- **Purpose**: Date and time selection with timezone support
- **Validation Options**:
  - `format`: DateTime format specification
  - `timezone`: Timezone handling (UTC, local, specific)
  - `min_datetime`: Earliest allowed datetime
  - `max_datetime`: Latest allowed datetime
- **Example**: Maintenance windows, scheduled events

**Time**
- **Purpose**: Time-only input without date component
- **Validation Options**:
  - `format`: Time format (HH:MM, HH:MM:SS)
  - `min_time`: Earliest allowed time
  - `max_time`: Latest allowed time
- **Example**: Daily backup times, recurring schedules

#### 7.2.3 Selection Types

**Selection**
- **Purpose**: Single choice from predefined options
- **Validation Options**:
  - `oneof`: Array of valid options
  - `allow_custom`: Allow user-entered values
- **Example**: Environment selection, instance types

**Multiselect**
- **Purpose**: Multiple choices from predefined options
- **Validation Options**:
  - `options`: Array of available choices
  - `min_selections`: Minimum required selections
  - `max_selections`: Maximum allowed selections
- **Example**: Feature flags, service dependencies

#### 7.2.4 Specialized Basic Types

**Percentage**
- **Purpose**: Percentage values with automatic validation
- **Validation Options**:
  - `min_value`: Minimum percentage (0-100)
  - `max_value`: Maximum percentage (0-100)
  - `step`: Increment step size
- **Example**: Resource thresholds, scaling percentages

**Textarea**
- **Purpose**: Multi-line text input for longer content
- **Validation Options**:
  - `max_length`: Maximum character count
  - `min_length`: Minimum character count
  - `rows`: Display height in rows
  - `cols`: Display width in columns
- **Example**: Descriptions, configuration snippets, notes

### 7.3 Universal Field Properties

All field types support these common properties:

- **required**: Boolean indicating if field must be completed
- **default**: Default value when field is optional
- **help_text**: Contextual assistance displayed to users
- **readonly**: Field is display-only and cannot be modified
- **hidden**: Field is not visible but can have default values
- **conditional**: Field visibility based on other field values

### 7.4 Extensibility for Specialized Types

The PAO specification supports extensibility for domain-specific field types beyond the basic set. Organizations can define specialized types such as:

- Network-specific types (CIDR blocks, IP addresses)
- Cloud provider-specific types (regions, instance types, resource names)
- Security-specific types (certificates, secrets, access keys)
- Business-specific types (cost centers, approval workflows)

These specialized types follow the same validation and property patterns as basic types, ensuring consistency across the catalog system while enabling domain-specific functionality.

## 8. Processing Model

### 8.1 Document Discovery

The PAO Service periodically scans the catalog directory structure to discover and validate CatalogItem documents.

### 8.2 Catalog Generation

Valid CatalogItems are processed to generate a unified service catalog exposed through the Developer Control Plane.

### 8.3 Request Fulfillment

Upon service request submission:
1. Collected values are validated against Presentation constraints
2. Fulfillment templates are rendered with substituted values
3. Specified actions are executed in defined order
4. Status tracking and notifications are managed throughout the process

## 9. Extensibility

The PAO specification is designed for progressive enhancement:

- New field types can be added to the Presentation schema
- Additional action types can be introduced to the Fulfillment schema
- Custom validation rules and business logic can be incorporated
- Platform Teams can evolve from manual to automated fulfillment incrementally

## 10. Future Considerations

This draft specification provides the foundation for the PAO catalog system. Future revisions may include:

- Advanced workflow orchestration capabilities
- Approval chain definitions
- Cost estimation and chargeback integration
- Service dependency management
- Rollback and versioning strategies
- Multi-environment promotion paths

---

*End of Draft Specification*