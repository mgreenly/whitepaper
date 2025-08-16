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
5. [Presentation Field Types](#5-presentation-field-types)
   - [5.1 Sample Field Definitions](#51-sample-field-definitions)
   - [5.2 Field Type Specifications](#52-field-type-specifications)
   - [5.3 Field Properties](#53-field-properties)
6. [Processing Model](#6-processing-model)
   - [6.1 Document Discovery](#61-document-discovery)
   - [6.2 Catalog Generation](#62-catalog-generation)
   - [6.3 Request Fulfillment](#63-request-fulfillment)
7. [Extensibility](#7-extensibility)
8. [Future Considerations](#8-future-considerations)

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

The Fulfillment section contains templates and action definitions that execute upon service request submission. It supports multiple action types including JiraTicket, HttpPost/HttpPut, TerraformFile, and GitHubWorkflow. Each action type includes templating capabilities for value substitution using data collected through the Presentation layer.

## 5. Presentation Field Types

The Presentation layer supports comprehensive field types for collecting service request parameters. The basic field types provide complete coverage for most use cases, with extensibility for specialized domain-specific types when needed.

### 5.1 Sample Field Definitions

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

### 5.2 Basic Field Type Specifications

#### 5.2.1 Basic Data Types

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

#### 5.2.2 Temporal Types

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

#### 5.2.3 Selection Types

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

#### 5.2.4 Specialized Basic Types

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

### 5.3 Universal Field Properties

All field types support these common properties:

- **required**: Boolean indicating if field must be completed
- **default**: Default value when field is optional
- **help_text**: Contextual assistance displayed to users
- **readonly**: Field is display-only and cannot be modified
- **hidden**: Field is not visible but can have default values
- **conditional**: Field visibility based on other field values

### 5.4 Extensibility for Specialized Types

The PAO specification supports extensibility for domain-specific field types beyond the basic set. Organizations can define specialized types such as:

- Network-specific types (CIDR blocks, IP addresses)
- Cloud provider-specific types (regions, instance types, resource names)
- Security-specific types (certificates, secrets, access keys)
- Business-specific types (cost centers, approval workflows)

These specialized types follow the same validation and property patterns as basic types, ensuring consistency across the catalog system while enabling domain-specific functionality.

## 6. Processing Model

### 6.1 Document Discovery

The PAO Service periodically scans the catalog directory structure to discover and validate CatalogItem documents.

### 6.2 Catalog Generation

Valid CatalogItems are processed to generate a unified service catalog exposed through the Developer Control Plane.

### 6.3 Request Fulfillment

Upon service request submission:
1. Collected values are validated against Presentation constraints
2. Fulfillment templates are rendered with substituted values
3. Specified actions are executed in defined order
4. Status tracking and notifications are managed throughout the process

## 7. Extensibility

The PAO specification is designed for progressive enhancement:

- New field types can be added to the Presentation schema
- Additional action types can be introduced to the Fulfillment schema
- Custom validation rules and business logic can be incorporated
- Platform Teams can evolve from manual to automated fulfillment incrementally

## 8. Future Considerations

This draft specification provides the foundation for the PAO catalog system. Future revisions may include:

- Advanced workflow orchestration capabilities
- Approval chain definitions
- Cost estimation and chargeback integration
- Service dependency management
- Rollback and versioning strategies
- Multi-environment promotion paths

---

*End of Draft Specification*