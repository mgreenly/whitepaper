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
- Resource-based URLs
- HTTP methods for operations (GET, POST, PUT, DELETE)
- JSON request/response format
- Standard HTTP status codes
- Pagination for list operations

### 2.2 Authentication & Authorization

The API uses AWS IAM authentication with AWS Signature Version 4 signing process. All requests must be properly signed using AWS credentials.

### 2.3 API Standards

- **Base URL**: `/api/v1`
- **Content Type**: `application/json`
- **Versioning**: Semantic versioning in URL path
- **Error Format**: RFC 7807 Problem Details for HTTP APIs
- **Pagination**: Cursor-based with `limit` and `cursor` parameters

## 3. Catalog Endpoints

### 3.1 List Catalog Items

```http
GET /api/v1/catalog/items
```

**Parameters:**
- `tags` (optional): Filter by tags (comma-separated)
- `owner` (optional): Filter by owner team
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
      "href": "/api/v1/catalog/items/eks-container-app"
    }
  ],
  "pagination": {
    "next_cursor": "eyJuYW1lIjoiZWtzLWNvbnRhaW5lci1hcHAifQ==",
    "has_more": true
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
        "help_text": "Application name"
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
  "description": "Complete web application stack",
  "bundle": {
    "required_items": [
      {
        "catalog_item": "eks-container-app",
        "version": ">=1.2.0"
      }
    ],
    "optional_items": [
      {
        "catalog_item": "redis-cache",
        "version": ">=1.1.0",
        "default_enabled": false
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

**Request Body:**
```json
{
  "catalog_item": "eks-container-app",
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
  "created_at": "2025-08-16T10:30:00Z",
  "updated_at": "2025-08-16T10:35:00Z",
  "fulfillment": {
    "actions": [
      {
        "type": "TerraformFile",
        "status": "completed",
        "completed_at": "2025-08-16T10:33:00Z"
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
  "catalog_last_updated": "2025-08-16T09:00:00Z"
}
```

## 6. Data Models

### 6.1 Catalog Models

All catalog models follow the structure defined in the PAO YAML specification, converted to JSON format for API responses.

### 6.2 Request Models

**Request Status Values:**
- `submitted`: Request received and queued
- `validating`: Validating request parameters
- `in_progress`: Fulfillment actions executing
- `completed`: All actions completed successfully
- `failed`: One or more actions failed
- `cancelled`: Request cancelled by user or admin

### 6.3 Error Models

```json
{
  "type": "https://pao.example.com/errors/validation-error",
  "title": "Request validation failed",
  "status": 400,
  "detail": "Field 'app_name' is required but was not provided",
  "instance": "/api/v1/requests"
}
```

---

*End of Draft Specification*