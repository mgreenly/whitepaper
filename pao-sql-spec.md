# PAO Service SQL Database Schema

## Overview

The PAO Service uses a PostgreSQL database to store catalog metadata, service requests, and execution state. The schema is designed to support efficient catalog discovery, request tracking, and step-level execution monitoring.

## Core Tables

### catalog_items
Stores the parsed catalog items from the YAML repository.

```sql
CREATE TABLE catalog_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    tags JSONB DEFAULT '[]'::jsonb,
    category VARCHAR(100), -- compute, databases, messaging, networking, storage
    presentation JSONB NOT NULL, -- Full presentation schema as JSON
    fulfillment JSONB NOT NULL, -- Full fulfillment definition as JSON
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source_file_path VARCHAR(500), -- Path in git repository
    source_file_hash VARCHAR(64), -- SHA256 of source YAML file
    
    INDEX idx_catalog_items_name (name),
    INDEX idx_catalog_items_owner (owner),
    INDEX idx_catalog_items_category (category),
    INDEX idx_catalog_items_tags USING gin(tags)
);
```

### catalog_bundles
Stores catalog bundles that group multiple catalog items.

```sql
CREATE TABLE catalog_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    tags JSONB DEFAULT '[]'::jsonb,
    bundle_definition JSONB NOT NULL, -- required_items, optional_items
    presentation JSONB NOT NULL, -- bundle_fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source_file_path VARCHAR(500),
    source_file_hash VARCHAR(64),
    
    INDEX idx_catalog_bundles_name (name),
    INDEX idx_catalog_bundles_owner (owner)
);
```

### service_requests
Tracks all service provisioning requests.

```sql
CREATE TABLE service_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id VARCHAR(100) NOT NULL UNIQUE, -- External facing ID
    catalog_item_id UUID REFERENCES catalog_items(id),
    catalog_bundle_id UUID REFERENCES catalog_bundles(id),
    catalog_version VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL, -- submitted, validating, in_progress, completed, failed, cancelled, resuming, aborted
    parameters JSONB NOT NULL, -- User-provided parameters
    requester_user_id VARCHAR(255) NOT NULL,
    requester_team VARCHAR(255),
    requester_email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    INDEX idx_service_requests_request_id (request_id),
    INDEX idx_service_requests_status (status),
    INDEX idx_service_requests_requester (requester_user_id),
    INDEX idx_service_requests_created_at (created_at DESC),
    
    CONSTRAINT check_catalog_reference CHECK (
        (catalog_item_id IS NOT NULL AND catalog_bundle_id IS NULL) OR
        (catalog_item_id IS NULL AND catalog_bundle_id IS NOT NULL)
    )
);
```

### request_steps
Tracks individual execution steps for each request.

```sql
CREATE TABLE request_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
    step_id VARCHAR(100) NOT NULL, -- External step identifier
    step_name VARCHAR(255) NOT NULL,
    step_type VARCHAR(50) NOT NULL, -- TerraformFile, GitHubWorkflow, HttpPost, JiraTicket
    step_config JSONB NOT NULL, -- Step configuration from fulfillment
    status VARCHAR(50) NOT NULL, -- pending, running, verifying, completed, failed, skipped, retrying
    position INT NOT NULL, -- Order in execution sequence
    depends_on TEXT[], -- Array of step_ids this depends on
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    outputs JSONB, -- Step outputs for reference by other steps
    
    INDEX idx_request_steps_request_id (request_id),
    INDEX idx_request_steps_status (status),
    
    UNIQUE(request_id, step_id)
);
```

### step_attempts
Records each execution attempt for a step.

```sql
CREATE TABLE step_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id UUID NOT NULL REFERENCES request_steps(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL,
    status VARCHAR(50) NOT NULL, -- running, completed, failed
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_type VARCHAR(100),
    error_message TEXT,
    error_details JSONB,
    logs_url TEXT,
    external_job_id VARCHAR(255), -- External system job ID
    external_job_url TEXT, -- Link to external system
    verification_result JSONB, -- Verification details
    
    INDEX idx_step_attempts_step_id (step_id),
    UNIQUE(step_id, attempt_number)
);
```

### manual_tickets
Tracks manual tickets created for failed automation or manual fulfillment.

```sql
CREATE TABLE manual_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES service_requests(id),
    step_id UUID REFERENCES request_steps(id), -- NULL for manual-only fulfillment
    ticket_system VARCHAR(50) NOT NULL, -- jira, servicenow
    ticket_id VARCHAR(100) NOT NULL,
    ticket_url TEXT,
    ticket_type VARCHAR(50), -- fulfillment, cleanup, completion
    status VARCHAR(50) NOT NULL, -- open, in_progress, resolved, closed
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    
    INDEX idx_manual_tickets_request_id (request_id),
    INDEX idx_manual_tickets_ticket_id (ticket_id)
);
```

### catalog_sync_status
Tracks synchronization status with the Git repository.

```sql
CREATE TABLE catalog_sync_status (
    id SERIAL PRIMARY KEY,
    sync_started_at TIMESTAMPTZ NOT NULL,
    sync_completed_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL, -- running, completed, failed
    repository_url TEXT NOT NULL,
    branch VARCHAR(100) NOT NULL,
    commit_hash VARCHAR(40),
    items_added INT DEFAULT 0,
    items_updated INT DEFAULT 0,
    items_removed INT DEFAULT 0,
    bundles_added INT DEFAULT 0,
    bundles_updated INT DEFAULT 0,
    bundles_removed INT DEFAULT 0,
    error_message TEXT,
    
    INDEX idx_catalog_sync_status_completed (sync_completed_at DESC)
);
```

## Supporting Functions

### get_catalog_item_with_bundle_context
Retrieves catalog item details including any bundles that contain it.

```sql
CREATE OR REPLACE FUNCTION get_catalog_item_with_bundle_context(p_item_name VARCHAR)
RETURNS TABLE (
    item_id UUID,
    item_name VARCHAR,
    item_version VARCHAR,
    item_presentation JSONB,
    bundle_id UUID,
    bundle_name VARCHAR,
    bundle_version VARCHAR,
    bundle_presentation JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id as item_id,
        ci.name as item_name,
        ci.version as item_version,
        ci.presentation as item_presentation,
        cb.id as bundle_id,
        cb.name as bundle_name,
        cb.version as bundle_version,
        cb.presentation as bundle_presentation
    FROM catalog_items ci
    LEFT JOIN catalog_bundles cb ON 
        cb.bundle_definition @> jsonb_build_array(
            jsonb_build_object('catalog_item', ci.name)
        )
    WHERE ci.name = p_item_name;
END;
$$ LANGUAGE plpgsql;
```

### update_request_status
Updates request status and manages state transitions.

```sql
CREATE OR REPLACE FUNCTION update_request_status(
    p_request_id UUID,
    p_new_status VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    SELECT status INTO v_current_status
    FROM service_requests
    WHERE id = p_request_id
    FOR UPDATE;
    
    -- Validate state transition
    IF NOT is_valid_status_transition(v_current_status, p_new_status) THEN
        RAISE EXCEPTION 'Invalid status transition from % to %', 
            v_current_status, p_new_status;
    END IF;
    
    UPDATE service_requests
    SET 
        status = p_new_status,
        updated_at = NOW(),
        completed_at = CASE 
            WHEN p_new_status IN ('completed', 'failed', 'aborted', 'cancelled') 
            THEN NOW() 
            ELSE completed_at 
        END
    WHERE id = p_request_id;
END;
$$ LANGUAGE plpgsql;
```

## Indexes for Common Queries

```sql
-- For pagination queries
CREATE INDEX idx_catalog_items_name_id ON catalog_items(name, id);
CREATE INDEX idx_catalog_items_created_id ON catalog_items(created_at DESC, id);

-- For request history queries
CREATE INDEX idx_service_requests_user_created ON service_requests(requester_user_id, created_at DESC);
CREATE INDEX idx_service_requests_team_created ON service_requests(requester_team, created_at DESC);

-- For step execution monitoring
CREATE INDEX idx_request_steps_request_status ON request_steps(request_id, status);
CREATE INDEX idx_step_attempts_external_job ON step_attempts(external_job_id) WHERE external_job_id IS NOT NULL;
```

## Notes

- All timestamps use TIMESTAMPTZ to store timezone information
- JSONB is used for flexible schema storage of presentation and fulfillment definitions
- UUIDs are used for internal IDs, with human-readable external IDs where appropriate
- Indexes are created for common query patterns and pagination