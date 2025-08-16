# Spec: Platform Automation Orchestrator (PAO) REST API

**DRAFT SPECIFICATION**

---

**Important Notice:** This is a draft specification generated with the assistance of AI agents. No organization-specific proprietary information was used in its creation. This document is intended solely as inspiration for the development of the actual Platform Automation Orchestrator API specification and should not be considered a final or authoritative technical reference.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overview](#2-overview)
   - [2.1 API Architecture](#21-api-architecture)
   - [2.2 Authentication & Authorization](#22-authentication--authorization)
   - [2.3 API Standards](#23-api-standards)
3. [Catalog Endpoints](#3-catalog-endpoints)
   - [3.1 List Catalog Items](#31-list-catalog-items)
   - [3.2 Get Catalog Item](#32-get-catalog-item)
   - [3.3 List Catalog Bundles](#33-list-catalog-bundles)
   - [3.4 Get Catalog Bundle](#34-get-catalog-bundle)
4. [Request Management](#4-request-management)
   - [4.1 Submit Service Request](#41-submit-service-request)
   - [4.2 Get Request Status](#42-get-request-status)
   - [4.3 List User Requests](#43-list-user-requests)
5. [Administration](#5-administration)
   - [5.1 Refresh Catalog](#51-refresh-catalog)
   - [5.2 Health Check](#52-health-check)
   - [5.3 Validate Catalog Item](#53-validate-catalog-item)
   - [5.4 Get Catalog Statistics](#54-get-catalog-statistics)
6. [Data Models](#6-data-models)
   - [6.1 Catalog Models](#61-catalog-models)
   - [6.2 Request Models](#62-request-models)
   - [6.3 Error Models](#63-error-models)

---

## 1. Introduction

This document specifies the REST API for the Platform Automation Orchestrator Service (pao-srv). The API enables Developer Control Planes and other clients to discover available service offerings from the catalog and submit requests for service provisioning.

The pao-srv acts as the runtime component that processes the YAML catalog definitions and exposes them through a standardized REST interface. It handles catalog discovery, request validation, fulfillment orchestration, and status tracking.

## 2. Overview

### 2.1 API Architecture

The PAO REST API follows REST principles with:
- Resource-based URLs following hierarchical catalog structure
- HTTP methods for operations (GET, POST, PUT, DELETE)
- JSON request/response format (converted from YAML catalog definitions)
- Standard HTTP status codes
- Pagination for list operations
- Semantic versioning for all resources

### 2.2 Authentication & Authorization

The API uses AWS IAM authentication with AWS Signature Version 4 signing process. All requests must be properly signed using AWS credentials.

### 2.3 API Standards

- **Base URL**: `/api/v1`
- **Content Type**: `application/json`
- **Versioning**: 
  - API versioning in URL path (`/api/v1`, `/api/v2`)
  - Resource versioning using semantic versioning (major.minor.patch)
  - Support for pre-release and metadata fields (e.g., "2.1.0-beta.1+build.20250816")
- **Error Format**: RFC 7807 Problem Details for HTTP APIs
- **Pagination**: Cursor-based with `limit` and `cursor` parameters
- **Repository Structure Mapping**:
  - Catalog items organized by category (compute, databases, messaging, networking, storage)
  - Direct mapping from repository path to API resource path

## 3. Catalog Endpoints

### 3.1 List Catalog Items

```http
GET /api/v1/catalog/items
```

**Parameters:**
- `tags` (optional): Filter by tags (comma-separated)
- `owner` (optional): Filter by owner team
- `category` (optional): Filter by category (compute, databases, messaging, networking, storage)
- `search` (optional): Search in name and description
- `limit` (optional): Number of items to return (default: 50, max: 100)
- `cursor` (optional): Pagination cursor

**Response:**
```json
{
  "items": [
    {
      "name": "eks-container-app",
      "version": "1.2.0",
      "description": "Managed Kubernetes application deployment",
      "owner": "platform-compute-team",
      "tags": ["containers", "kubernetes", "compute"],
      "category": "compute",
      "href": "/api/v1/catalog/items/eks-container-app"
    }
  ],
  "pagination": {
    "next_cursor": "eyJuYW1lIjoiZWtzLWNvbnRhaW5lci1hcHAifQ==",
    "has_more": true,
    "total_count": 25
  }
}
```

### 3.2 Get Catalog Item

```http
GET /api/v1/catalog/items/{item_name}
```

**Response:**
```json
{
  "name": "eks-container-app",
  "version": "1.2.0",
  "description": "Managed Kubernetes application deployment",
  "owner": "platform-compute-team",
  "tags": ["containers", "kubernetes", "compute"],
  "presentation": {
    "fields": [
      {
        "name": "app_name",
        "type": "string",
        "required": true,
        "max_length": 50,
        "min_length": 3,
        "regexp": "^[a-z][a-z0-9-]*$",
        "help_text": "Application name (lowercase alphanumeric with hyphens)"
      },
      {
        "name": "environment",
        "type": "selection",
        "oneof": ["dev", "staging", "prod"],
        "required": true,
        "help_text": "Target deployment environment"
      },
      {
        "name": "replicas",
        "type": "integer",
        "min_value": 1,
        "max_value": 10,
        "default": 2,
        "help_text": "Number of replicas to deploy"
      }
    ]
  },
  "fulfillment": {
    "actions": [
      {
        "type": "TerraformFile",
        "template": {
          "module_source": "./modules/eks-app",
          "variables": {
            "app_name": "{{ app_name }}",
            "environment": "{{ environment }}",
            "replica_count": "{{ replicas }}"
          }
        }
      }
    ]
  }
}
```

### 3.3 List Catalog Bundles

```http
GET /api/v1/catalog/bundles
```

**Response:**
```json
{
  "bundles": [
    {
      "name": "full-stack-web-app",
      "version": "2.1.0",
      "description": "Complete web application stack",
      "owner": "platform-solutions-team",
      "tags": ["web-app", "full-stack"],
      "href": "/api/v1/catalog/bundles/full-stack-web-app"
    }
  ]
}
```

### 3.4 Get Catalog Bundle

```http
GET /api/v1/catalog/bundles/{bundle_name}
```

**Response:**
```json
{
  "name": "full-stack-web-app",
  "version": "2.1.0",
  "description": "Complete web application stack with database and monitoring",
  "owner": "platform-solutions-team",
  "tags": ["web-app", "full-stack", "solution"],
  "bundle": {
    "required_items": [
      {
        "catalog_item": "eks-container-app",
        "version": ">=1.2.0",
        "parameters": {
          "app_type": "web-frontend"
        }
      },
      {
        "catalog_item": "postgres-database",
        "version": ">=2.0.0"
      }
    ],
    "optional_items": [
      {
        "catalog_item": "redis-cache",
        "version": ">=1.1.0",
        "default_enabled": false
      },
      {
        "catalog_item": "application-monitoring",
        "version": ">=1.0.0",
        "default_enabled": true
      }
    ]
  },
  "presentation": {
    "bundle_fields": [
      {
        "name": "solution_name",
        "type": "string",
        "required": true,
        "help_text": "Name for this solution deployment"
      },
      {
        "name": "enable_ha",
        "type": "boolean",
        "default": false,
        "help_text": "Enable high availability mode"
      }
    ]
  }
}
```

## 4. Request Management

### 4.1 Submit Service Request

```http
POST /api/v1/requests
```

**Request Body for CatalogItem:**
```json
{
  "catalog_item": "eks-container-app",
  "version": "1.2.0",
  "parameters": {
    "app_name": "my-web-app",
    "environment": "staging",
    "replicas": 3
  },
  "requester": {
    "user_id": "dev-user-123",
    "team": "product-team"
  }
}
```

**Request Body for CatalogBundle:**
```json
{
  "catalog_bundle": "full-stack-web-app",
  "version": "2.1.0",
  "bundle_parameters": {
    "solution_name": "customer-portal",
    "enable_ha": true
  },
  "item_selections": {
    "optional_items": [
      {
        "catalog_item": "redis-cache",
        "enabled": true,
        "parameters": {
          "cache_size": "2gb"
        }
      }
    ]
  },
  "requester": {
    "user_id": "dev-user-123",
    "team": "product-team"
  }
}
```

**Response:**
```json
{
  "request_id": "req-abc123def456",
  "status": "submitted",
  "catalog_item": "eks-container-app",
  "created_at": "2025-08-16T10:30:00Z",
  "href": "/api/v1/requests/req-abc123def456"
}
```

### 4.2 Get Request Status

```http
GET /api/v1/requests/{request_id}
```

**Response:**
```json
{
  "request_id": "req-abc123def456",
  "status": "in_progress",
  "catalog_item": "eks-container-app",
  "version": "1.2.0",
  "parameters": {
    "app_name": "my-web-app",
    "environment": "staging",
    "replicas": 3
  },
  "created_at": "2025-08-16T10:30:00Z",
  "updated_at": "2025-08-16T10:35:00Z",
  "requester": {
    "user_id": "dev-user-123",
    "team": "product-team"
  },
  "fulfillment": {
    "actions": [
      {
        "type": "TerraformFile",
        "status": "completed",
        "completed_at": "2025-08-16T10:33:00Z",
        "output": {
          "terraform_run_id": "run-xyz789",
          "resources_created": 5
        }
      }
    ]
  }
}
```

### 4.3 List User Requests

```http
GET /api/v1/requests
```

**Parameters:**
- `user_id` (optional): Filter by user
- `status` (optional): Filter by status
- `limit` (optional): Number of requests to return

**Response:**
```json
{
  "requests": [
    {
      "request_id": "req-abc123def456",
      "status": "completed",
      "catalog_item": "eks-container-app",
      "created_at": "2025-08-16T10:30:00Z"
    }
  ]
}
```

## 5. Administration

### 5.1 Refresh Catalog

```http
POST /api/v1/admin/catalog/refresh
```

Forces pao-srv to rescan the catalog repository for changes.

### 5.2 Health Check

```http
GET /api/v1/health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "catalog_last_updated": "2025-08-16T09:00:00Z",
  "repository": {
    "url": "https://github.com/org/pao-repository",
    "branch": "main",
    "last_sync": "2025-08-16T09:00:00Z"
  }
}
```

### 5.3 Validate Catalog Item

```http
POST /api/v1/admin/catalog/validate
```

Validates a catalog item or bundle definition without adding it to the catalog.

**Request Body:**
```json
{
  "type": "catalog_item",
  "definition": {
    "name": "test-service",
    "version": "1.0.0",
    "description": "Test service definition",
    "owner": "platform-team",
    "tags": ["test"],
    "presentation": {
      "fields": []
    },
    "fulfillment": {
      "actions": []
    }
  }
}
```

**Response:**
```json
{
  "valid": true,
  "warnings": [],
  "errors": []
}
```

### 5.4 Get Catalog Statistics

```http
GET /api/v1/admin/catalog/stats
```

**Response:**
```json
{
  "total_items": 25,
  "total_bundles": 5,
  "items_by_owner": {
    "platform-compute-team": 8,
    "platform-data-team": 6,
    "platform-networking-team": 11
  },
  "items_by_category": {
    "compute": 8,
    "databases": 6,
    "networking": 7,
    "storage": 4
  },
  "last_updated": "2025-08-16T09:00:00Z"
}
```

## 6. Data Models

### 6.1 Catalog Models

All catalog models follow the structure defined in the PAO YAML specification, converted to JSON format for API responses.

#### Field Type Definitions

The API returns field definitions matching the YAML specification's comprehensive type system:

**Basic Types:**
- `string`: Text input with validation constraints
- `integer`: Whole numbers with range limits  
- `number`: Decimal values with precision control
- `boolean`: True/false selection

**Temporal Types:**
- `date`: Date selection (ISO 8601 format)
- `datetime`: Date and time with timezone
- `time`: Time-only input (HH:MM or HH:MM:SS)

**Selection Types:**
- `selection`: Single choice from predefined options
- `multiselect`: Multiple choices from options

**Specialized Types:**
- `percentage`: Values 0-100 with validation
- `textarea`: Multi-line text input

**Field Validation Properties:**
```json
{
  "name": "field_name",
  "type": "string",
  "required": true,
  "default": "default_value",
  "help_text": "Contextual help for users",
  "max_length": 100,
  "min_length": 1,
  "regexp": "^[a-z][a-z0-9-]*$",
  "readonly": false,
  "hidden": false,
  "conditional": {
    "field": "other_field",
    "value": "specific_value"
  }
}
```

### 6.2 Request Models

**Request Status Values:**
- `submitted`: Request received and queued
- `validating`: Validating request parameters
- `in_progress`: Fulfillment actions executing
- `completed`: All actions completed successfully
- `failed`: One or more actions failed
- `cancelled`: Request cancelled by user or admin

**Fulfillment Action Types:**
- `JiraTicket`: Creates JIRA ticket for manual fulfillment
- `TerraformFile`: Executes Terraform automation
- `GitHubWorkflow`: Triggers GitHub Actions workflow
- `HttpPost`/`HttpPut`: Makes HTTP API calls

### 6.3 Error Models

```json
{
  "type": "https://pao.example.com/errors/validation-error",
  "title": "Request validation failed",
  "status": 400,
  "detail": "Field 'app_name' is required but was not provided",
  "instance": "/api/v1/requests",
  "validation_errors": [
    {
      "field": "app_name",
      "error": "required",
      "message": "This field is required"
    },
    {
      "field": "replicas",
      "error": "max_value",
      "message": "Value must be less than or equal to 10"
    }
  ]
}
```

---

*End of Draft Specification*