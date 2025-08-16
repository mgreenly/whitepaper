# User Story: Deploy EKS Container App with PostgreSQL Backend

## Context
A developer named Sarah needs to deploy a new web application that requires:
- An EKS container application for the frontend/API
- A PostgreSQL database for data persistence
- Both components properly configured and connected

Sarah accesses the Developer Portal (Stratus) which consumes the PAO Service catalog.

## Step 1: Browse Available Services

### User Action
Sarah navigates to the "Service Catalog" page in the Developer Portal.

### API Interaction
```json
// Request: GET /api/v1/catalog/bundles?tags=web-app
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
{
  "bundles": [
    {
      "name": "full-stack-web-app",
      "version": "2.1.0",
      "description": "Complete web application stack with database and monitoring",
      "owner": "platform-solutions-team",
      "tags": ["web-app", "full-stack", "solution"],
      "href": "/api/v1/catalog/bundles/full-stack-web-app"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### YAML Source
From `pao-repository/catalog/bundles/full-stack-web-app.yaml`:
```yaml
name: "Full Stack Web Application"
version: "2.1.0"
description: "Complete web application stack with database and monitoring"
owner: "platform-solutions-team"
tags: ["web-app", "full-stack", "solution"]
```

### Database Operation
```sql
SELECT 
    id, name, version, description, owner, tags
FROM catalog_bundles
WHERE tags @> '["web-app"]'::jsonb
ORDER BY name, id
LIMIT 51;
```

## Step 2: Select Bundle and View Details

### User Action
Sarah clicks on "Full Stack Web Application" to see details.

### API Interaction
```json
// Request: GET /api/v1/catalog/bundles/full-stack-web-app
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
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

### Database Operation
```sql
SELECT 
    id, name, version, description, owner, tags,
    bundle_definition, presentation
FROM catalog_bundles
WHERE name = 'full-stack-web-app';
```

## Step 3: Fetch Individual Item Presentations

### User Action
The Portal automatically fetches presentation details for each item in the bundle.

### API Interactions

#### EKS Container App
```json
// Request: GET /api/v1/catalog/items/eks-container-app
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
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
  }
}
```

#### PostgreSQL Database
```json
// Request: GET /api/v1/catalog/items/postgres-database
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
{
  "name": "postgres-database",
  "version": "2.1.0",
  "description": "PostgreSQL database instance",
  "owner": "platform-data-team",
  "tags": ["database", "postgres", "storage"],
  "presentation": {
    "fields": [
      {
        "name": "database_name",
        "type": "string",
        "required": true,
        "max_length": 63,
        "regexp": "^[a-z][a-z0-9_]*$",
        "help_text": "Database name (lowercase, underscores allowed)"
      },
      {
        "name": "instance_class",
        "type": "selection",
        "oneof": ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large"],
        "default": "db.t3.small",
        "help_text": "Database instance size"
      },
      {
        "name": "allocated_storage",
        "type": "integer",
        "min_value": 20,
        "max_value": 1000,
        "default": 100,
        "help_text": "Storage size in GB"
      },
      {
        "name": "backup_retention",
        "type": "integer",
        "min_value": 1,
        "max_value": 35,
        "default": 7,
        "help_text": "Backup retention period in days"
      }
    ]
  }
}
```

### Database Operations
```sql
-- Query for EKS app
SELECT id, name, version, description, owner, tags, presentation
FROM catalog_items
WHERE name = 'eks-container-app';

-- Query for Postgres
SELECT id, name, version, description, owner, tags, presentation
FROM catalog_items
WHERE name = 'postgres-database';
```

## Step 4: Fill Out Forms

### User Actions
Sarah fills out the forms in the Developer Portal:

**Bundle Configuration:**
- Solution Name: `customer-portal`
- Enable HA: `true` (checked)

**EKS Container Application:**
- App Name: `customer-portal-api`
- Environment: `staging`
- Replicas: `3`

**PostgreSQL Database:**
- Database Name: `customer_portal_db`
- Instance Class: `db.t3.medium`
- Allocated Storage: `250`
- Backup Retention: `14`

**Optional Items:**
- Redis Cache: `true` (Sarah enables this)
  - Cache Size: `cache.t3.micro`
- Application Monitoring: `true` (already enabled by default)

## Step 5: Submit Request

### User Action
Sarah clicks "Submit Request" button.

### API Interaction
```json
// Request: POST /api/v1/requests
{
  "headers": {
    "Authorization": "Bearer <sarah-token>",
    "Content-Type": "application/json"
  },
  "body": {
    "catalog_bundle": "full-stack-web-app",
    "version": "2.1.0",
    "bundle_parameters": {
      "solution_name": "customer-portal",
      "enable_ha": true
    },
    "item_parameters": {
      "eks-container-app": {
        "app_name": "customer-portal-api",
        "environment": "staging",
        "replicas": 3,
        "app_type": "web-frontend"  // From bundle defaults
      },
      "postgres-database": {
        "database_name": "customer_portal_db",
        "instance_class": "db.t3.medium",
        "allocated_storage": 250,
        "backup_retention": 14
      },
      "redis-cache": {
        "enabled": true,
        "cache_size": "cache.t3.micro"
      },
      "application-monitoring": {
        "enabled": true
      }
    },
    "requester": {
      "user_id": "sarah-123",
      "team": "customer-experience",
      "email": "sarah@example.com"
    }
  }
}

// Response: 201 Created
{
  "request_id": "req-20250816-abc123",
  "status": "submitted",
  "catalog_bundle": "full-stack-web-app",
  "created_at": "2025-08-16T10:30:00-05:00",
  "href": "/api/v1/requests/req-20250816-abc123"
}
```

### Database Operations
```sql
BEGIN;

-- Insert main request
INSERT INTO service_requests (
    request_id, catalog_bundle_id, catalog_version, 
    status, parameters, requester_user_id, requester_team, requester_email
) VALUES (
    'req-20250816-abc123',
    (SELECT id FROM catalog_bundles WHERE name = 'full-stack-web-app'),
    '2.1.0',
    'submitted',
    '{"bundle_parameters": {...}, "item_parameters": {...}}'::jsonb,
    'sarah-123',
    'customer-experience',
    'sarah@example.com'
) RETURNING id;

-- Insert steps for each component
INSERT INTO request_steps (request_id, step_id, step_name, step_type, step_config, status, position)
VALUES 
    (<request_uuid>, 'step-001', 'provision_eks_app', 'TerraformFile', '...'::jsonb, 'pending', 1),
    (<request_uuid>, 'step-002', 'provision_postgres', 'TerraformFile', '...'::jsonb, 'pending', 2),
    (<request_uuid>, 'step-003', 'provision_redis', 'TerraformFile', '...'::jsonb, 'pending', 3),
    (<request_uuid>, 'step-004', 'setup_monitoring', 'GitHubWorkflow', '...'::jsonb, 'pending', 4),
    (<request_uuid>, 'step-005', 'configure_connections', 'HttpPost', '...'::jsonb, 'pending', 5);

COMMIT;
```

## Step 6: Monitor Request Progress

### User Action
Sarah refreshes the request status page.

### API Interaction
```json
// Request: GET /api/v1/requests/req-20250816-abc123
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
{
  "request_id": "req-20250816-abc123",
  "status": "in_progress",
  "catalog_bundle": "full-stack-web-app",
  "version": "2.1.0",
  "created_at": "2025-08-16T10:30:00-05:00",
  "updated_at": "2025-08-16T10:35:00-05:00",
  "requester": {
    "user_id": "sarah-123",
    "team": "customer-experience"
  },
  "fulfillment": {
    "execution_mode": "automation",
    "steps": [
      {
        "step_id": "step-001",
        "name": "provision_eks_app",
        "type": "TerraformFile",
        "status": "completed",
        "started_at": "2025-08-16T10:30:30-05:00",
        "completed_at": "2025-08-16T10:33:00-05:00",
        "outputs": {
          "cluster_endpoint": "https://eks-staging.example.com",
          "service_url": "https://customer-portal-api.staging.example.com"
        }
      },
      {
        "step_id": "step-002",
        "name": "provision_postgres",
        "type": "TerraformFile",
        "status": "running",
        "started_at": "2025-08-16T10:33:00-05:00",
        "job_tracking": {
          "external_id": "tf-run-postgres-456",
          "tracking_url": "https://terraform.example.com/runs/tf-run-postgres-456"
        }
      },
      {
        "step_id": "step-003",
        "name": "provision_redis",
        "status": "pending"
      },
      {
        "step_id": "step-004",
        "name": "setup_monitoring",
        "status": "pending"
      },
      {
        "step_id": "step-005",
        "name": "configure_connections",
        "status": "pending",
        "depends_on": ["step-001", "step-002", "step-003"]
      }
    ]
  }
}
```

### Database Operation
```sql
SELECT 
    sr.*, 
    json_agg(
        json_build_object(
            'step_id', rs.step_id,
            'name', rs.step_name,
            'type', rs.step_type,
            'status', rs.status,
            'started_at', rs.started_at,
            'completed_at', rs.completed_at,
            'outputs', rs.outputs
        ) ORDER BY rs.position
    ) as steps
FROM service_requests sr
LEFT JOIN request_steps rs ON rs.request_id = sr.id
WHERE sr.request_id = 'req-20250816-abc123'
GROUP BY sr.id;
```

## Step 7: Handle Step Failure

### Scenario
The PostgreSQL provisioning fails due to subnet conflicts.

### API Interaction (Status Check)
```json
// Request: GET /api/v1/requests/req-20250816-abc123/steps/step-002
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
{
  "request_id": "req-20250816-abc123",
  "step_id": "step-002",
  "name": "provision_postgres",
  "type": "TerraformFile",
  "status": "failed",
  "attempts": [
    {
      "attempt_number": 1,
      "started_at": "2025-08-16T10:33:00-05:00",
      "completed_at": "2025-08-16T10:36:00-05:00",
      "status": "failed",
      "error": {
        "type": "terraform_error",
        "message": "Error creating RDS instance: subnet group conflicts with existing resources",
        "details": {
          "resource": "aws_db_subnet_group.postgres",
          "error_code": "InvalidDBSubnetGroup"
        }
      }
    }
  ],
  "can_retry": true,
  "manual_fallback_available": true
}
```

### Automatic Fallback to Manual
```sql
-- Insert manual ticket for failed step
INSERT INTO manual_tickets (
    request_id, step_id, ticket_system, ticket_id, 
    ticket_url, ticket_type, status
) VALUES (
    (SELECT id FROM service_requests WHERE request_id = 'req-20250816-abc123'),
    (SELECT id FROM request_steps WHERE step_id = 'step-002'),
    'jira',
    'PLATFORM-5678',
    'https://jira.example.com/browse/PLATFORM-5678',
    'fulfillment',
    'open'
) RETURNING id;
```

## Step 8: Complete Request

After platform team resolves the PostgreSQL issue manually and marks the step as complete, the automation continues and completes successfully.

### Final Status
```json
// Request: GET /api/v1/requests/req-20250816-abc123
{
  "headers": {
    "Authorization": "Bearer <sarah-token>"
  }
}

// Response: 200 OK
{
  "request_id": "req-20250816-abc123",
  "status": "completed",
  "catalog_bundle": "full-stack-web-app",
  "created_at": "2025-08-16T10:30:00-05:00",
  "completed_at": "2025-08-16T11:15:00-05:00",
  "outputs": {
    "eks_app": {
      "service_url": "https://customer-portal-api.staging.example.com",
      "cluster_endpoint": "https://eks-staging.example.com"
    },
    "postgres": {
      "connection_string": "postgresql://customer_portal_db.staging.rds.amazonaws.com:5432/customer_portal_db",
      "admin_secret_arn": "arn:aws:secretsmanager:us-east-1:123456789:secret:customer-portal-db-admin"
    },
    "redis": {
      "endpoint": "customer-portal-redis.staging.cache.amazonaws.com:6379"
    },
    "monitoring": {
      "dashboard_url": "https://grafana.example.com/dashboards/customer-portal"
    }
  }
}
```

## Gaps Identified

### sql-schema.md
1. **Missing Tables:**
   - `bundle_request_items` - To track which items from a bundle were actually requested
   - `request_outputs` - To store the final outputs from completed requests
   - `user_sessions` - To track user authentication/authorization
   - `audit_log` - To track all API operations for compliance

2. **Missing Columns:**
   - `service_requests.bundle_parameters` - Separate storage for bundle vs item parameters
   - `service_requests.outputs` - Final outputs from the request
   - `request_steps.verification_config` - Expected verification criteria

### pao-rest-spec.md
1. **Missing Endpoints:**
   - `POST /api/v1/requests/validate` - Pre-validate a request before submission
   - `GET /api/v1/requests/{request_id}/outputs` - Get just the outputs
   - `POST /api/v1/requests/{request_id}/cancel` - Cancel a pending request
   - `GET /api/v1/catalog/search` - Full-text search across catalog

2. **Missing Response Fields:**
   - Bundle requests need different structure than item requests
   - Need to return validation errors in a structured format
   - Missing cost estimation information

3. **Missing Features:**
   - WebSocket endpoint for real-time status updates
   - Batch request submission for multiple items
   - Request templates/drafts that can be saved

### pao-yaml-spec.md
1. **Missing Definitions:**
   - How to reference outputs from one item in another within a bundle
   - How to specify item dependencies within a bundle
   - Cost estimation metadata for catalog items
   - Resource quotas and limits

2. **Missing Field Types:**
   - `secret` - For sensitive inputs that shouldn't be logged
   - `file` - For file uploads
   - `json` - For complex configuration objects

3. **Missing Fulfillment Features:**
   - Pre-flight checks before execution
   - Rollback procedures for failed provisioning
   - Health checks after provisioning
   - Connection string template generation

### General Gaps
1. **Authentication/Authorization:**
   - How are users authenticated?
   - How are team-based permissions enforced?
   - API rate limiting

2. **Versioning:**
   - How to handle catalog item version updates
   - Migration path for existing provisioned resources
   - Backward compatibility guarantees

3. **Operations:**
   - Metrics and monitoring for the PAO service itself
   - Backup and disaster recovery procedures
   - Multi-region considerations