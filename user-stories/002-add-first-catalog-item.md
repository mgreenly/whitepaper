# User Story: Platform Team Adds First Catalog Item

## Context
Platform data team lead Josh needs to add the first service offering to the PAO catalog. The PAO service is running with an empty catalog, and the GitHub webhook is configured.

## Step 1: Create YAML File Locally

### User Action
Josh creates a new file in his local clone of the pao-repository.

### File Created
`pao-repository/catalog/databases/mysql-database.yaml`:
```yaml
# Header - Basic metadata
name: "mysql-database"
version: "1.0.0"
description: "MySQL database instance"
owner: "platform-data-team"
tags: ["database", "mysql", "storage"]

# Presentation - User interface definition
presentation:
  fields:
    - name: "database_name"
      type: "string"
      required: true
      max_length: 64
      regexp: "^[a-z][a-z0-9_]*$"
      help_text: "Database name (lowercase, underscores allowed)"
    - name: "instance_size"
      type: "selection"
      oneof: ["db.t3.micro", "db.t3.small", "db.t3.medium"]
      default: "db.t3.small"
      required: true
      help_text: "Database instance size"

# Fulfillment - Manual only for MVP
fulfillment:
  manual:
    system: "jira"
    template:
      project: "PLATFORM"
      issue_type: "Service Request"
      summary: "Create MySQL database {{ database_name }}"
      description: |
        Please create a MySQL database with the following specifications:
        - Database Name: {{ database_name }}
        - Instance Size: {{ instance_size }}
        - Requester: {{ requester.user_id }}
        - Team: {{ requester.team }}
```

## Step 2: Validate Locally

### User Action
Josh runs local validation script (optional but recommended).

### Command
```bash
$ pao-cli validate catalog/databases/mysql-database.yaml
✓ Valid CatalogItem document
✓ All required fields present
✓ Presentation fields properly defined
✓ Fulfillment template valid
```

## Step 3: Commit and Push

### User Actions
```bash
$ git add catalog/databases/mysql-database.yaml
$ git commit -m "Add MySQL database catalog item"
$ git push origin main
```

### Git Output
```
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 1.24 KiB | 1.24 MiB/s, done.
To github.com:org/pao-repository.git
   abc123..def456  main -> main
```

## Step 4: GitHub Triggers Webhook

### System Action
GitHub sends webhook to PAO service.

### Webhook Payload
```json
{
  "ref": "refs/heads/main",
  "before": "abc123...",
  "after": "def456...",
  "commits": [
    {
      "id": "def456",
      "timestamp": "2025-08-16T14:30:00-05:00",
      "message": "Add MySQL database catalog item",
      "author": {
        "name": "Josh Smith",
        "email": "josh.smith@example.com"
      },
      "added": [
        "catalog/databases/mysql-database.yaml"
      ],
      "modified": [],
      "removed": []
    }
  ],
  "repository": {
    "name": "pao-repository",
    "full_name": "org/pao-repository",
    "clone_url": "https://github.com/org/pao-repository.git"
  },
  "pusher": {
    "name": "josh-smith",
    "email": "josh.smith@example.com"
  }
}
```

## Step 5: PAO Service Processes Webhook

### API Interaction
```json
// Request: POST /api/v1/webhooks/github
{
  "headers": {
    "X-GitHub-Event": "push",
    "X-Hub-Signature-256": "sha256=<calculated-signature>",
    "X-GitHub-Delivery": "12345-67890-abcdef",
    "Content-Type": "application/json"
  },
  "body": {
    // Webhook payload from Step 4
  }
}

// Response: 200 OK
{
  "status": "accepted",
  "delivery_id": "12345-67890-abcdef",
  "sync_id": "sync-20250816-001"
}
```

### Internal Processing
1. Validate webhook signature
2. Check if push is to main branch
3. Identify catalog files in commit
4. Trigger sync for added file

### Database Operations
```sql
-- Record webhook event
INSERT INTO webhook_events (
    delivery_id, event_type, payload, 
    signature_valid, processed_at
) VALUES (
    '12345-67890-abcdef',
    'push',
    '{"ref": "refs/heads/main", ...}'::jsonb,
    true,
    NOW()
);

-- Start sync
INSERT INTO catalog_sync_status (
    sync_started_at, status, repository_url, 
    branch, commit_hash, triggered_by
) VALUES (
    NOW(), 'running', 
    'https://github.com/org/pao-repository.git',
    'main', 'def456', 'webhook'
) RETURNING id;
```

## Step 6: Parse and Store Catalog Item

### System Processing
PAO service fetches and parses the new YAML file.

### Git Operations
```bash
# Service performs
git fetch origin
git checkout def456
cat catalog/databases/mysql-database.yaml | parse_yaml
```

### Database Operations
```sql
-- Insert new catalog item
INSERT INTO catalog_items (
    name, version, description, owner, tags, 
    category, presentation, fulfillment,
    source_file_path, source_file_hash, created_at
) VALUES (
    'mysql-database',
    '1.0.0',
    'MySQL database instance',
    'platform-data-team',
    '["database", "mysql", "storage"]'::jsonb,
    'databases',
    '{"fields": [{"name": "database_name", ...}]}'::jsonb,
    '{"manual": {"system": "jira", ...}}'::jsonb,
    'catalog/databases/mysql-database.yaml',
    'sha256:789xyz...',
    NOW()
);

-- Complete sync
UPDATE catalog_sync_status 
SET 
    sync_completed_at = NOW(),
    status = 'completed',
    items_added = 1,
    items_updated = 0,
    items_removed = 0
WHERE id = <sync_id>;
```

## Step 7: Verify via API

### User Action
Josh verifies the catalog item is available.

### API Interaction
```json
// Request: GET /api/v1/catalog/items/mysql-database
{
  "headers": {
    "Authorization": "Bearer <josh-token>"
  }
}

// Response: 200 OK
{
  "name": "mysql-database",
  "version": "1.0.0",
  "description": "MySQL database instance",
  "owner": "platform-data-team",
  "tags": ["database", "mysql", "storage"],
  "presentation": {
    "fields": [
      {
        "name": "database_name",
        "type": "string",
        "required": true,
        "max_length": 64,
        "regexp": "^[a-z][a-z0-9_]*$",
        "help_text": "Database name (lowercase, underscores allowed)"
      },
      {
        "name": "instance_size",
        "type": "selection",
        "oneof": ["db.t3.micro", "db.t3.small", "db.t3.medium"],
        "default": "db.t3.small",
        "required": true,
        "help_text": "Database instance size"
      }
    ]
  }
}
```

## Step 8: Notification (Optional)

### System Action
PAO service sends notification about new catalog item.

### Notification Channels
- Slack: "#platform-updates"
- Email: platform-team@example.com

### Message
```
✅ New catalog item added: mysql-database v1.0.0
Owner: platform-data-team
Description: MySQL database instance
View: https://developer-portal.example.com/catalog/mysql-database
```

## Gaps Identified

### sql-schema.md
1. **Missing Tables:**
   - `webhook_events` - Not defined in current schema
   - `catalog_item_validation_log` - Track validation attempts

2. **Missing Columns:**
   - `catalog_sync_status.files_processed` - List of files handled
   - `catalog_items.validated_at` - When validation occurred

### pao-rest-spec.md
1. **Missing Endpoints:**
   - Webhook endpoint not fully specified
   - Missing webhook signature validation details
   - No endpoint for sync status monitoring

2. **Missing Response Codes:**
   - 401 for invalid webhook signature
   - 422 for invalid YAML content
   - 409 for version conflicts

### pao-yaml-spec.md
1. **Missing Validations:**
   - Name uniqueness requirements
   - Version increment rules
   - Required vs optional fields in fulfillment.manual

### Infrastructure Gaps
1. **CI/CD:**
   - No automated validation on pull requests
   - No dry-run capability for catalog changes
   - No rollback mechanism for bad catalog items

2. **Monitoring:**
   - No metrics for sync duration
   - No alerts for sync failures
   - No dashboard for catalog health