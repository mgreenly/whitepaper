# User Story: Initial PAO Service Setup with Webhook-Driven Sync

## Context
Platform engineer Mike sets up the PAO service for the first time. The service starts with an empty database and will receive catalog updates via GitHub webhooks.

## Step 1: Start PAO Service with Empty Database

### User Action
Mike starts the PAO service with configuration.

### Configuration
```json
{
  "PAO_REPO_URL": "https://github.com/org/pao-repository.git",
  "PAO_REPO_BRANCH": "main",
  "PAO_REPO_TOKEN": "<github-token>",
  "PAO_WEBHOOK_SECRET": "webhook-secret-123",
  "PAO_DB_URL": "postgresql://pao:password@localhost/pao"
}
```

### Database Operation
```sql
-- Service creates schema on first run
CREATE TABLE catalog_items ...
CREATE TABLE catalog_sync_status (
    id SERIAL PRIMARY KEY,
    last_processed_sha VARCHAR(40),
    processed_at TIMESTAMPTZ,
    files_changed INT,
    status VARCHAR(50)
);
```

### Service State
- Database is empty
- No catalog items exist
- Service is ready to receive webhooks
- Last processed SHA is NULL

## Step 2: Configure GitHub Webhook

### User Action
Mike configures webhook in GitHub repository settings:
- **Payload URL**: `https://pao-service.example.com/api/v1/webhooks/github`
- **Content type**: `application/json`
- **Secret**: `webhook-secret-123`
- **Events**: Just the push event
- **Active**: ✓

### GitHub Test
GitHub sends a ping event to verify connectivity.

```json
// Ping Request: POST /api/v1/webhooks/github
{
  "headers": {
    "X-GitHub-Event": "ping",
    "X-Hub-Signature-256": "sha256=<signature>"
  },
  "body": {
    "zen": "Design for failure.",
    "hook_id": 123456,
    "hook": {
      "type": "Repository",
      "id": 123456,
      "events": ["push"],
      "active": true
    }
  }
}

// Response: 200 OK
{
  "status": "pong",
  "message": "Webhook configured successfully"
}
```

## Step 3: First Push to Repository Triggers Initial Load

### User Action
Someone pushes to main branch (could be any commit).

### GitHub Webhook
```json
{
  "ref": "refs/heads/main",
  "after": "abc123def456",
  "repository": {
    "clone_url": "https://github.com/org/pao-repository.git",
    "default_branch": "main"
  },
  "head_commit": {
    "id": "abc123def456",
    "message": "Update README"
  }
}
```

## Step 4: PAO Service Processes First Webhook

### API Interaction
```json
// Request: POST /api/v1/webhooks/github
{
  "headers": {
    "X-GitHub-Event": "push",
    "X-Hub-Signature-256": "sha256=<signature>"
  },
  "body": {
    // Webhook from Step 3
  }
}
```

### Internal Processing
```go
// Service logic
lastSHA := getLastProcessedSHA() // Returns NULL for first run
currentSHA := webhook.After       // "abc123def456"

if lastSHA == "" {
    // First sync - process all catalog files at current SHA
    files = git.ListFiles("catalog/**/*.yaml", currentSHA)
} else {
    // Incremental - get only changed files
    files = git.Diff(lastSHA, currentSHA, "catalog/**/*.yaml")
}
```

### Git Operations
Since this is the first webhook (lastSHA is NULL), service lists ALL catalog files:
```bash
# Service runs internally
git clone https://github.com/org/pao-repository.git /tmp/repo
cd /tmp/repo
git checkout abc123def456
find catalog -name "*.yaml" -type f
```

### Found Files
```
catalog/databases/postgres-database.yaml
catalog/databases/mysql-database.yaml
catalog/compute/eks-container-app.yaml
```

### Database Operations
```sql
-- Process each found file
BEGIN;

-- Insert all catalog items found
INSERT INTO catalog_items (name, version, ...) VALUES
    ('postgres-database', '1.0.0', ...),
    ('mysql-database', '1.0.0', ...),
    ('eks-container-app', '1.0.0', ...);

-- Record the sync
INSERT INTO catalog_sync_status (
    last_processed_sha, processed_at, files_changed, status
) VALUES (
    'abc123def456', NOW(), 3, 'completed'
);

COMMIT;
```

### Response
```json
{
  "status": "accepted",
  "sha_processed": "abc123def456",
  "files_processed": 3,
  "items_created": 3
}
```

## Step 5: Subsequent Push with Changes

### User Action
Josh adds a new catalog item and pushes.

### GitHub Webhook
```json
{
  "ref": "refs/heads/main",
  "before": "abc123def456",
  "after": "def789ghi012",
  "commits": [
    {
      "added": ["catalog/storage/s3-bucket.yaml"],
      "modified": ["catalog/databases/postgres-database.yaml"],
      "removed": []
    }
  ]
}
```

## Step 6: Incremental Update

### Internal Processing
```go
lastSHA := getLastProcessedSHA() // Returns "abc123def456"
currentSHA := webhook.After       // "def789ghi012"

// Get only files changed between SHAs
changedFiles := git.Diff(lastSHA, currentSHA, "catalog/**/*.yaml")
// Returns: 
// - catalog/storage/s3-bucket.yaml (added)
// - catalog/databases/postgres-database.yaml (modified)
```

### Git Operations
```bash
cd /tmp/repo
git fetch
git diff --name-status abc123def456..def789ghi012 -- 'catalog/*.yaml'
# A  catalog/storage/s3-bucket.yaml
# M  catalog/databases/postgres-database.yaml
```

### Database Operations
```sql
BEGIN;

-- Insert new item
INSERT INTO catalog_items (name, version, ...) 
VALUES ('s3-bucket', '1.0.0', ...);

-- Update modified item
UPDATE catalog_items 
SET version = '1.1.0', presentation = '...', updated_at = NOW()
WHERE name = 'postgres-database';

-- Update last processed SHA
UPDATE catalog_sync_status 
SET last_processed_sha = 'def789ghi012',
    processed_at = NOW(),
    files_changed = 2,
    status = 'completed';

COMMIT;
```

## Step 7: Handle Deletion

### User Action
Someone removes an outdated catalog item.

### GitHub Webhook
```json
{
  "ref": "refs/heads/main",
  "before": "def789ghi012",
  "after": "ghi345jkl678",
  "commits": [
    {
      "removed": ["catalog/databases/mysql-database.yaml"]
    }
  ]
}
```

### Internal Processing
```go
// Detect removed files
removed := webhook.Commits[0].Removed
for _, file := range removed {
    itemName := extractItemName(file) // "mysql-database"
    markAsInactive(itemName)
}
```

### Database Operations
```sql
-- Soft delete the removed item
UPDATE catalog_items 
SET is_active = false, updated_at = NOW()
WHERE name = 'mysql-database';

-- Record the sync
UPDATE catalog_sync_status 
SET last_processed_sha = 'ghi345jkl678',
    processed_at = NOW(),
    files_changed = 1;
```

## Gaps Identified

### sql-schema.md
1. **Missing Columns:**
   - `catalog_sync_status.last_processed_sha` - Track git position
   - `catalog_items.is_active` - Soft delete support
   - `catalog_items.last_seen_sha` - Track when item last updated

### pao-rest-spec.md
1. **Missing Details:**
   - How to handle webhook when last_processed_sha is NULL
   - Rate limiting for webhook endpoint
   - Handling force pushes and rebases

### Implementation Gaps
1. **Git Operations:**
   - Need local git cache management
   - Handle authentication for private repos
   - Clean up temporary git clones

2. **Error Handling:**
   - What if git fetch fails?
   - How to handle merge commits?
   - Recovery from partial sync failures