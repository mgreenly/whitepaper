# Platform Automation Orchestrator Service

## Overview

The Platform Automation Orchestrator (PAO) is a REST API service that serves as the central coordination point for the Internal Developer Platform (IDP). It enables self-service provisioning through a unified catalog of platform services.

## Architecture

The service operates within the Integration and Delivery Plane of the reference architecture, providing:

- **Catalog Management**: Consumes YAML service definitions from platform teams
- **Service Discovery**: Generates unified service catalog from distributed definitions  
- **Request Orchestration**: Routes and fulfills service requests automatically
- **Progressive Enhancement**: Supports evolution from manual to automated fulfillment

## Core Functionality

### Catalog Processing
- Reads service definitions from the catalog repository
- Validates against JSON schema
- Generates dynamic UI forms from presentation layer definitions
- Maintains service metadata and SLA information

### Request Fulfillment
- Processes service requests with variable substitution
- Executes fulfillment actions (JIRA tickets, REST calls, Terraform, GitHub workflows)
- Provides status tracking and error handling
- Supports retry logic and rollback procedures

### API Endpoints
- `GET /catalog` - Retrieve available services
- `POST /requests` - Submit service request
- `GET /requests/{id}` - Check request status
- `GET /health` - Service health check

## Technology Stack

- **Runtime**: REST service (implementation language TBD)
- **Data Store**: Document-driven (catalog repository)
- **Integration**: JIRA, GitHub, Terraform, custom webhooks
- **Validation**: JSON Schema for catalog items

## Deployment Model

- Stateless service design for horizontal scaling
- Configuration via environment variables
- Kubernetes-ready with health checks
- Integration with existing CI/CD pipelines