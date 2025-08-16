# User Story: Initial Catalog Repository Setup and Sync

## Context
Platform engineer Mike needs to set up the PAO service for the first time. The service has an empty database and needs to sync with the Git repository containing catalog definitions.

## Step 1: Configure PAO Service with Repository

### User Action
Mike configures the PAO service with the Git repository URL and credentials via environment variables.

### Configuration
```json
{
  "PAO_REPO_URL": "https://github.com/org/pao-repository.git",
  "PAO_REPO_BRANCH": "main",
  "PAO_REPO_TOKEN": "<github-token>",
  "PAO_SYNC_INTERVAL": "300",
  "PAO_WEBHOOK_SECRET": "webhook-secret-123"
}
```

### Database Operation
Service starts with empty database, creates schema:
```sql
-- All tables created via migrations
CREATE TABLE catalog_items ...
CREATE TABLE catalog_bundles ...
CREATE TABLE catalog_sync_status ...
```

## Step 2: Initial Repository Clone

### System Action
PAO service clones the repository on startup.

### Internal Process
```go
// Service initialization
repo := git.Clone(config.RepoURL, config.Branch)
files := repo.ListFiles("catalog/**/*.yaml")
```

### Database Operation
```sql
INSERT INTO catalog_sync_status (
    sync_started_at, status, repository_url, branch
) VALUES (
    NOW(), 'running', 'https://github.com/org/pao-repository.git', 'main'
) RETURNING id;
```

## Step 3: Parse and Store First Catalog Item

### Repository Content
Mike has added `pao-repository/catalog/databases/postgres-database.yaml`:
```yaml
# Header - Basic metadata
name: "postgres-database"
version: "1.0.0"
description: "PostgreSQL database instance"
owner: "platform-data-team"
tags: ["database", "postgres", "storage"]

# Presentation - User interface definition
presentation:
  fields:
    - name: "database_name"
      type: "string"
      required: true
      max_length: 63
      regexp: "^[a-z][a-z0-9_]*$"
      help_text: "Database name (lowercase, underscores allowed)"

# Fulfillment - Manual only initially
fulfillment:
  manual:
    system: "jira"
    template:
      project: "PLATFORM"
      issue_type: "Service Request"
      summary: "Create PostgreSQL database {{ database_name }}"
```

### System Processing
PAO service reads and validates the YAML file.

### Database Operations
```sql
INSERT INTO catalog_items (
    name, version, description, owner, tags, category,
    presentation, fulfillment,
    source_file_path, source_file_hash
) VALUES (
    'postgres-database',
    '1.0.0',
    'PostgreSQL database instance',
    'platform-data-team',
    '["database", "postgres", "storage"]'::jsonb,
    'databases',
    '{"fields": [...]}'::jsonb,
    '{"manual": {...}}'::jsonb,
    'catalog/databases/postgres-database.yaml',
    'sha256:abc123...'
) ON CONFLICT (name) DO UPDATE SET
    version = EXCLUDED.version,
    presentation = EXCLUDED.presentation,
    fulfillment = EXCLUDED.fulfillment,
    updated_at = NOW();
```

## Step 4: Complete Initial Sync

### Database Operation
```sql
UPDATE catalog_sync_status 
SET 
    sync_completed_at = NOW(),
    status = 'completed',
    items_added = 1,
    commit_hash = 'abc123def'
WHERE id = <sync_id>;
```

### API Verification
```json
// Request: GET /api/v1/catalog/items
{
  "headers": {
    "Authorization": "Bearer <admin-token>"
  }
}

// Response: 200 OK
{
  "items": [
    {
      "name": "postgres-database",
      "version": "1.0.0",
      "description": "PostgreSQL database instance",
      "owner": "platform-data-team",
      "tags": ["database", "postgres", "storage"],
      "href": "/api/v1/catalog/items/postgres-database"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

## Step 5: Configure GitHub Webhook

### User Action
Mike configures a webhook in GitHub repository settings:
- Payload URL: `https://pao-service.example.com/api/v1/webhooks/github`
- Content type: `application/json`
- Secret: `webhook-secret-123`
- Events: Push events on main branch

### GitHub Webhook Payload (on push)
```json
{
  "ref": "refs/heads/main",
  "commits": [
    {
      "id": "def456ghi",
      "message": "Add EKS container app catalog item",
      "added": [
        "catalog/compute/eks-container-app.yaml"
      ],
      "modified": [],
      "removed": []
    }
  ],
  "repository": {
    "clone_url": "https://github.com/org/pao-repository.git"
  }
}
```

## Step 6: Process Webhook for New Item

### API Interaction
```json
// Request: POST /api/v1/webhooks/github
{
  "headers": {
    "X-GitHub-Event": "push",
    "X-Hub-Signature-256": "sha256=<signature>",
    "Content-Type": "application/json"
  },
  "body": {
    // GitHub webhook payload from Step 5
  }
}

// Response: 200 OK
{
  "status": "accepted",
  "sync_triggered": true
}
```

### System Processing
1. Validate webhook signature
2. Detect changes in catalog/ directory
3. Trigger incremental sync
4. Parse new/modified YAML files
5. Update database

### Database Operations
```sql
-- Start new sync
INSERT INTO catalog_sync_status (
    sync_started_at, status, repository_url, branch, commit_hash
) VALUES (
    NOW(), 'running', 'https://github.com/org/pao-repository.git', 
    'main', 'def456ghi'
);

-- Add new catalog item
INSERT INTO catalog_items (
    name, version, description, owner, tags, category,
    presentation, fulfillment,
    source_file_path, source_file_hash
) VALUES (
    'eks-container-app',
    '1.0.0',
    'Managed Kubernetes application deployment',
    'platform-compute-team',
    '["containers", "kubernetes", "compute"]'::jsonb,
    'compute',
    '{"fields": [...]}'::jsonb,
    '{"manual": {...}}'::jsonb,
    'catalog/compute/eks-container-app.yaml',
    'sha256:def456...'
);

-- Complete sync
UPDATE catalog_sync_status 
SET 
    sync_completed_at = NOW(),
    status = 'completed',
    items_added = 1
WHERE id = <current_sync_id>;
```

## Gaps Identified

### sql-schema.md
1. **Missing Tables:**
   - `webhook_events` - Track received webhooks and processing status
   - `catalog_validation_errors` - Store validation failures during sync
   - `catalog_item_versions` - History of item versions

2. **Missing Columns:**
   - `catalog_items.is_active` - Soft delete support
   - `catalog_sync_status.triggered_by` - webhook vs scheduled
   - `catalog_sync_status.webhook_payload` - Store triggering webhook

### pao-rest-spec.md
1. **Missing Endpoints:**
   - `POST /api/v1/webhooks/github` - GitHub webhook receiver
   - `POST /api/v1/admin/catalog/sync` - Manual sync trigger
   - `GET /api/v1/admin/catalog/sync/status` - Current sync status
   - `GET /api/v1/admin/catalog/validation-errors` - List validation failures

2. **Missing Features:**
   - Webhook signature validation details
   - Incremental vs full sync logic
   - Conflict resolution for concurrent syncs

### pao-yaml-spec.md
1. **Missing Specifications:**
   - File naming conventions
   - Directory structure requirements
   - Validation error reporting format
   - Version conflict resolution rules

### General Gaps
1. **Operations:**
   - How to handle malformed YAML files
   - Rollback strategy for bad catalog updates
   - Monitoring/alerting for sync failures
   - Rate limiting for webhook processing