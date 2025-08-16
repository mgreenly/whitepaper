# Spec: Platform Automation Orchestrator (PAO)

**DRAFT SPECIFICATION**

---

**Important Notice:** This is a draft specification generated with the assistance of AI agents. No organization-specific proprietary information was used in its creation. This document is intended solely as inspiration for the development of the actual Platform Automation Orchestrator specification and should not be considered a final or authoritative technical reference.

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

### 3.1 Sample Document

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

# Fulfillment - Automation templates
fulfillment:
  actions:
    - type: "TerraformFile"
      template:
        module_source: "./modules/eks-app"
        variables:
          app_name: "{{ app_name }}"
          environment: "{{ environment }}"
          replica_count: "{{ replicas }}"
```

### 3.2 Document Structure

A CatalogItem consists of three mandatory top-level objects:

- **Header**: Contains metadata and document-level properties
- **Presentation**: Defines the user interface elements and data collection requirements
- **Fulfillment**: Specifies the automation templates and actions for service provisioning

### 3.3 Header Section

The Header section provides essential metadata about the catalog item, including:

- **name**: The display name of the service offering
- **version**: Semantic versioning information for the catalog item definition
- **description**: A brief description of the service
- **owner**: The Platform Team responsible for this offering
- **tags**: Searchable metadata tags for categorization
- **dependencies**: References to other catalog items or prerequisites

### 3.4 Presentation Section

The Presentation section defines the form structure for collecting service request parameters and supports field groups, display ordering, validation rules, and help text for end users.

### 3.5 Fulfillment Section

The Fulfillment section contains templates and action definitions that execute upon service request submission. It supports multiple action types including JiraTicket, HttpPost/HttpPut, TerraformFile, and GitHubWorkflow. Each action type includes templating capabilities for value substitution using data collected through the Presentation layer.

## 4. Presentation Field Types

The Presentation layer supports comprehensive field types for collecting service request parameters:

### 4.1 Sample Field Definitions

```yaml
# String fields - Text input with validation
- name: "application_name"
  type: "string"
  required: true
  max_length: 50
  min_length: 3
  regexp: "^[a-z][a-z0-9-]*$"
  help_text: "Lowercase alphanumeric with hyphens"

# Integer fields - Numeric input with constraints  
- name: "instance_count"
  type: "int"
  min_value: 1
  max_value: 100
  default: 3
  help_text: "Number of instances to deploy"

# Selection fields - Predefined choices
- name: "environment"
  type: "selection"
  oneof: ["development", "staging", "production"]
  required: true
  help_text: "Target deployment environment"

# Boolean fields - True/false selections
- name: "enable_monitoring"
  type: "boolean"
  default: true
  help_text: "Enable application monitoring"

# Date fields - Date/time inputs
- name: "maintenance_window"
  type: "date"
  format: "iso8601"
  help_text: "Preferred maintenance window start time"
```

### 4.2 Field Type Specifications

- **String**: Text input with validation constraints (max_length, min_length, regexp)
- **Int**: Integer values with range constraints (min_value, max_value)
- **Float**: Decimal values with precision and range constraints
- **Selection**: Enumerated choices from predefined options (oneof: [option1, option2, ...])
- **Boolean**: True/false selections
- **Date**: Date/time inputs with format specifications

### 4.3 Field Properties

- **required**: Boolean indicating if field must be completed
- **default**: Default value when field is optional
- **help_text**: Contextual assistance displayed to users
- **validation**: Custom validation rules and error messages

## 5. Processing Model

### 5.1 Document Discovery

The PAO Service periodically scans the catalog directory structure to discover and validate CatalogItem documents.

### 5.2 Catalog Generation

Valid CatalogItems are processed to generate a unified service catalog exposed through the Developer Control Plane.

### 5.3 Request Fulfillment

Upon service request submission:
1. Collected values are validated against Presentation constraints
2. Fulfillment templates are rendered with substituted values
3. Specified actions are executed in defined order
4. Status tracking and notifications are managed throughout the process

## 6. Extensibility

The PAO specification is designed for progressive enhancement:

- New field types can be added to the Presentation schema
- Additional action types can be introduced to the Fulfillment schema
- Custom validation rules and business logic can be incorporated
- Platform Teams can evolve from manual to automated fulfillment incrementally

## 7. Future Considerations

This draft specification provides the foundation for the PAO catalog system. Future revisions may include:

- Advanced workflow orchestration capabilities
- Approval chain definitions
- Cost estimation and chargeback integration
- Service dependency management
- Rollback and versioning strategies
- Multi-environment promotion paths

---

*End of Draft Specification*