# PAO Service SQL Database Schema

## Overview

The PAO Service uses a PostgreSQL database to store catalog metadata, service requests, execution state, and runtime service instance management. The schema is designed to support efficient catalog discovery, request tracking, step-level execution monitoring, and complete lifecycle management of deployed services including their dependencies and upgrade paths.

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
    request_type VARCHAR(50) NOT NULL, -- create, update, upgrade, decommission
    catalog_item_id UUID REFERENCES catalog_items(id),
    catalog_bundle_id UUID REFERENCES catalog_bundles(id),
    update_item_id UUID REFERENCES update_items(id),
    upgrade_item_id UUID REFERENCES upgrade_items(id),
    target_instance_id UUID REFERENCES service_instances(id), -- For update/upgrade/decommission
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
    INDEX idx_service_requests_target_instance (target_instance_id),
    INDEX idx_service_requests_type (request_type),
    
    CONSTRAINT check_request_type_reference CHECK (
        CASE request_type
            WHEN 'create' THEN 
                (catalog_item_id IS NOT NULL OR catalog_bundle_id IS NOT NULL) AND
                update_item_id IS NULL AND upgrade_item_id IS NULL AND target_instance_id IS NULL
            WHEN 'update' THEN
                update_item_id IS NOT NULL AND target_instance_id IS NOT NULL AND
                catalog_item_id IS NULL AND catalog_bundle_id IS NULL AND upgrade_item_id IS NULL
            WHEN 'upgrade' THEN
                upgrade_item_id IS NOT NULL AND target_instance_id IS NOT NULL AND
                catalog_item_id IS NULL AND catalog_bundle_id IS NULL AND update_item_id IS NULL
            WHEN 'decommission' THEN
                target_instance_id IS NOT NULL AND
                catalog_item_id IS NULL AND catalog_bundle_id IS NULL AND 
                update_item_id IS NULL AND upgrade_item_id IS NULL
            ELSE FALSE
        END
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

## Runtime State Management Tables

### service_instances
Tracks deployed service instances and their current state.

```sql
CREATE TABLE service_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id VARCHAR(100) NOT NULL UNIQUE, -- External facing instance ID (e.g., "si-abc123def456")
    catalog_item_id UUID REFERENCES catalog_items(id),
    catalog_bundle_id UUID REFERENCES catalog_bundles(id),
    catalog_version VARCHAR(50) NOT NULL, -- Version at deployment time
    instance_name VARCHAR(255) NOT NULL, -- User-provided name for the instance
    instance_state VARCHAR(50) NOT NULL, -- active, provisioning, updating, failed, degraded, decommissioning, decommissioned
    owner_user_id VARCHAR(255) NOT NULL,
    owner_team VARCHAR(255) NOT NULL,
    owner_email VARCHAR(255),
    
    -- Deployment details
    deployment_parameters JSONB NOT NULL, -- Original deployment parameters
    deployed_resources JSONB, -- Resource identifiers (ARNs, IDs, etc.)
    service_outputs JSONB, -- Endpoints, connection strings, credentials reference
    service_metadata JSONB, -- Additional metadata (tags, labels, annotations)
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    provisioned_at TIMESTAMPTZ, -- When first became active
    decommissioned_at TIMESTAMPTZ, -- When decommissioned
    
    -- Request tracking
    creation_request_id UUID REFERENCES service_requests(id), -- Original creation request
    last_update_request_id UUID REFERENCES service_requests(id), -- Most recent update request
    
    INDEX idx_service_instances_instance_id (instance_id),
    INDEX idx_service_instances_state (instance_state),
    INDEX idx_service_instances_owner (owner_team, owner_user_id),
    INDEX idx_service_instances_created_at (created_at DESC),
    INDEX idx_service_instances_catalog_item (catalog_item_id),
    INDEX idx_service_instances_catalog_bundle (catalog_bundle_id),
    
    CONSTRAINT check_catalog_reference CHECK (
        (catalog_item_id IS NOT NULL AND catalog_bundle_id IS NULL) OR
        (catalog_item_id IS NULL AND catalog_bundle_id IS NOT NULL)
    )
);
```

### bundle_instance_members
Tracks individual service instances that are part of a bundle deployment.

```sql
CREATE TABLE bundle_instance_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    member_instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    catalog_item_name VARCHAR(255) NOT NULL, -- Name of the catalog item this member represents
    is_required BOOLEAN NOT NULL DEFAULT TRUE, -- Whether this was a required or optional component
    member_role VARCHAR(100), -- Role within the bundle (e.g., "database", "cache", "frontend")
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    INDEX idx_bundle_members_bundle (bundle_instance_id),
    INDEX idx_bundle_members_member (member_instance_id),
    UNIQUE(bundle_instance_id, member_instance_id)
);
```

### service_instance_dependencies
Tracks dependencies between service instances.

```sql
CREATE TABLE service_instance_dependencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dependent_instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    provider_instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    dependency_type VARCHAR(50) NOT NULL, -- data, network, authentication, configuration
    dependency_name VARCHAR(255), -- Semantic name for the dependency
    dependency_config JSONB, -- Configuration passed from provider to dependent
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    INDEX idx_dependencies_dependent (dependent_instance_id),
    INDEX idx_dependencies_provider (provider_instance_id),
    UNIQUE(dependent_instance_id, provider_instance_id, dependency_type)
);
```

### instance_version_history
Tracks version upgrade history for service instances.

```sql
CREATE TABLE instance_version_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    from_version VARCHAR(50),
    to_version VARCHAR(50) NOT NULL,
    upgrade_type VARCHAR(50) NOT NULL, -- major, minor, patch, configuration
    upgrade_request_id UUID REFERENCES service_requests(id),
    upgrade_item_name VARCHAR(255), -- Name of UpgradeItem used
    upgraded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    upgrade_duration_seconds INT,
    upgrade_status VARCHAR(50) NOT NULL, -- success, failed, rolled_back
    rollback_available BOOLEAN DEFAULT FALSE,
    upgrade_notes TEXT,
    
    INDEX idx_version_history_instance (instance_id, upgraded_at DESC),
    INDEX idx_version_history_request (upgrade_request_id)
);
```

### eligible_operations
Tracks which update/upgrade operations are eligible for specific service instances.

```sql
CREATE TABLE eligible_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID NOT NULL REFERENCES service_instances(id) ON DELETE CASCADE,
    operation_type VARCHAR(50) NOT NULL, -- upgrade, update
    operation_name VARCHAR(255) NOT NULL, -- Name of the UpgradeItem or UpdateItem
    operation_version VARCHAR(50) NOT NULL,
    eligibility_status VARCHAR(50) NOT NULL, -- eligible, ineligible, completed, superseded
    eligibility_reason TEXT, -- Why eligible or ineligible
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ, -- When this eligibility expires
    
    INDEX idx_eligible_ops_instance (instance_id, eligibility_status),
    INDEX idx_eligible_ops_operation (operation_name),
    UNIQUE(instance_id, operation_name, operation_version)
);
```

### update_items
Stores UpdateItem definitions from the catalog.

```sql
CREATE TABLE update_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    tags JSONB DEFAULT '[]'::jsonb,
    targets JSONB NOT NULL, -- Target catalog items and constraints
    destructive BOOLEAN NOT NULL DEFAULT FALSE,
    downtime_required BOOLEAN NOT NULL DEFAULT FALSE,
    estimated_duration VARCHAR(50),
    presentation JSONB NOT NULL,
    fulfillment JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source_file_path VARCHAR(500),
    source_file_hash VARCHAR(64),
    
    INDEX idx_update_items_name (name),
    INDEX idx_update_items_destructive (destructive)
);
```

### upgrade_items
Stores UpgradeItem definitions from the catalog.

```sql
CREATE TABLE upgrade_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    tags JSONB DEFAULT '[]'::jsonb,
    targets JSONB NOT NULL, -- Target catalog items and version constraints
    destructive BOOLEAN NOT NULL DEFAULT TRUE,
    downtime_required BOOLEAN NOT NULL DEFAULT TRUE,
    estimated_duration VARCHAR(50),
    presentation JSONB NOT NULL,
    fulfillment JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source_file_path VARCHAR(500),
    source_file_hash VARCHAR(64),
    
    INDEX idx_upgrade_items_name (name),
    INDEX idx_upgrade_items_downtime (downtime_required)
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
    v_request_type VARCHAR;
    v_target_instance_id UUID;
BEGIN
    SELECT status, request_type, target_instance_id 
    INTO v_current_status, v_request_type, v_target_instance_id
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
    
    -- Update service instance state based on request completion
    IF p_new_status = 'completed' THEN
        IF v_request_type = 'create' THEN
            -- Instance creation handled separately after outputs are available
            NULL;
        ELSIF v_request_type = 'update' THEN
            UPDATE service_instances
            SET instance_state = 'active',
                last_update_request_id = p_request_id,
                updated_at = NOW()
            WHERE id = v_target_instance_id;
        ELSIF v_request_type = 'upgrade' THEN
            UPDATE service_instances
            SET instance_state = 'active',
                last_update_request_id = p_request_id,
                updated_at = NOW()
            WHERE id = v_target_instance_id;
        ELSIF v_request_type = 'decommission' THEN
            UPDATE service_instances
            SET instance_state = 'decommissioned',
                decommissioned_at = NOW(),
                updated_at = NOW()
            WHERE id = v_target_instance_id;
        END IF;
    ELSIF p_new_status = 'failed' AND v_request_type = 'create' THEN
        UPDATE service_instances
        SET instance_state = 'failed',
            updated_at = NOW()
        WHERE creation_request_id = p_request_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### create_service_instance
Creates a new service instance from a completed request.

```sql
CREATE OR REPLACE FUNCTION create_service_instance(
    p_request_id UUID,
    p_instance_name VARCHAR,
    p_outputs JSONB,
    p_resources JSONB
) RETURNS UUID AS $$
DECLARE
    v_instance_id UUID;
    v_external_id VARCHAR;
    v_catalog_item_id UUID;
    v_catalog_bundle_id UUID;
    v_catalog_version VARCHAR;
    v_parameters JSONB;
    v_user_id VARCHAR;
    v_team VARCHAR;
    v_email VARCHAR;
BEGIN
    -- Get request details
    SELECT catalog_item_id, catalog_bundle_id, catalog_version, 
           parameters, requester_user_id, requester_team, requester_email
    INTO v_catalog_item_id, v_catalog_bundle_id, v_catalog_version,
         v_parameters, v_user_id, v_team, v_email
    FROM service_requests
    WHERE id = p_request_id AND status = 'completed';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request % not found or not completed', p_request_id;
    END IF;
    
    -- Generate external instance ID
    v_external_id := 'si-' || substr(md5(random()::text), 1, 12);
    
    -- Create service instance
    INSERT INTO service_instances (
        instance_id, catalog_item_id, catalog_bundle_id, catalog_version,
        instance_name, instance_state, owner_user_id, owner_team, owner_email,
        deployment_parameters, deployed_resources, service_outputs,
        creation_request_id, provisioned_at
    ) VALUES (
        v_external_id, v_catalog_item_id, v_catalog_bundle_id, v_catalog_version,
        p_instance_name, 'active', v_user_id, v_team, v_email,
        v_parameters, p_resources, p_outputs,
        p_request_id, NOW()
    ) RETURNING id INTO v_instance_id;
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;
```

### get_eligible_operations
Returns eligible update/upgrade operations for a service instance.

```sql
CREATE OR REPLACE FUNCTION get_eligible_operations(p_instance_id UUID)
RETURNS TABLE (
    operation_type VARCHAR,
    operation_name VARCHAR,
    operation_version VARCHAR,
    description TEXT,
    destructive BOOLEAN,
    downtime_required BOOLEAN,
    estimated_duration VARCHAR
) AS $$
DECLARE
    v_catalog_item_id UUID;
    v_catalog_version VARCHAR;
    v_instance_state VARCHAR;
BEGIN
    -- Get instance details
    SELECT si.catalog_item_id, si.catalog_version, si.instance_state
    INTO v_catalog_item_id, v_catalog_version, v_instance_state
    FROM service_instances si
    WHERE si.id = p_instance_id;
    
    IF v_instance_state NOT IN ('active', 'degraded') THEN
        RETURN; -- No operations eligible for non-active instances
    END IF;
    
    -- Find eligible update operations
    RETURN QUERY
    SELECT 
        'update'::VARCHAR as operation_type,
        ui.name,
        ui.version,
        ui.description,
        ui.destructive,
        ui.downtime_required,
        ui.estimated_duration
    FROM update_items ui
    WHERE EXISTS (
        SELECT 1
        FROM jsonb_array_elements(ui.targets->'catalog_items') as target
        WHERE (target->>'name')::VARCHAR = (
            SELECT name FROM catalog_items WHERE id = v_catalog_item_id
        )
    )
    AND NOT EXISTS (
        SELECT 1 FROM eligible_operations eo
        WHERE eo.instance_id = p_instance_id
        AND eo.operation_name = ui.name
        AND eo.eligibility_status = 'completed'
    )
    
    UNION ALL
    
    -- Find eligible upgrade operations
    SELECT 
        'upgrade'::VARCHAR as operation_type,
        ugi.name,
        ugi.version,
        ugi.description,
        ugi.destructive,
        ugi.downtime_required,
        ugi.estimated_duration
    FROM upgrade_items ugi
    WHERE EXISTS (
        SELECT 1
        FROM jsonb_array_elements(ugi.targets->'catalog_items') as target
        WHERE (target->>'name')::VARCHAR = (
            SELECT name FROM catalog_items WHERE id = v_catalog_item_id
        )
        -- Add version range check here if needed
    )
    AND NOT EXISTS (
        SELECT 1 FROM eligible_operations eo
        WHERE eo.instance_id = p_instance_id
        AND eo.operation_name = ugi.name
        AND eo.eligibility_status = 'completed'
    );
END;
$$ LANGUAGE plpgsql;
```

### get_instance_dependencies
Returns all dependencies for a service instance.

```sql
CREATE OR REPLACE FUNCTION get_instance_dependencies(
    p_instance_id UUID,
    p_direction VARCHAR DEFAULT 'both' -- 'providers', 'dependents', 'both'
)
RETURNS TABLE (
    relationship VARCHAR,
    instance_id UUID,
    instance_name VARCHAR,
    instance_state VARCHAR,
    dependency_type VARCHAR,
    dependency_name VARCHAR,
    is_required BOOLEAN
) AS $$
BEGIN
    IF p_direction IN ('providers', 'both') THEN
        -- Get providers (instances this instance depends on)
        RETURN QUERY
        SELECT 
            'provider'::VARCHAR as relationship,
            si.id,
            si.instance_name,
            si.instance_state,
            sid.dependency_type,
            sid.dependency_name,
            sid.is_required
        FROM service_instance_dependencies sid
        JOIN service_instances si ON si.id = sid.provider_instance_id
        WHERE sid.dependent_instance_id = p_instance_id;
    END IF;
    
    IF p_direction IN ('dependents', 'both') THEN
        -- Get dependents (instances that depend on this instance)
        RETURN QUERY
        SELECT 
            'dependent'::VARCHAR as relationship,
            si.id,
            si.instance_name,
            si.instance_state,
            sid.dependency_type,
            sid.dependency_name,
            sid.is_required
        FROM service_instance_dependencies sid
        JOIN service_instances si ON si.id = sid.dependent_instance_id
        WHERE sid.provider_instance_id = p_instance_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### can_decommission_instance
Checks if an instance can be safely decommissioned.

```sql
CREATE OR REPLACE FUNCTION can_decommission_instance(p_instance_id UUID)
RETURNS TABLE (
    can_decommission BOOLEAN,
    reason TEXT,
    blocking_instances JSONB
) AS $$
DECLARE
    v_has_required_dependents BOOLEAN;
    v_blocking_instances JSONB DEFAULT '[]'::jsonb;
BEGIN
    -- Check for required dependents
    SELECT COUNT(*) > 0
    INTO v_has_required_dependents
    FROM service_instance_dependencies sid
    JOIN service_instances si ON si.id = sid.dependent_instance_id
    WHERE sid.provider_instance_id = p_instance_id
    AND sid.is_required = TRUE
    AND si.instance_state NOT IN ('decommissioning', 'decommissioned');
    
    IF v_has_required_dependents THEN
        -- Get list of blocking instances
        SELECT jsonb_agg(jsonb_build_object(
            'instance_id', si.instance_id,
            'instance_name', si.instance_name,
            'instance_state', si.instance_state,
            'dependency_type', sid.dependency_type
        ))
        INTO v_blocking_instances
        FROM service_instance_dependencies sid
        JOIN service_instances si ON si.id = sid.dependent_instance_id
        WHERE sid.provider_instance_id = p_instance_id
        AND sid.is_required = TRUE
        AND si.instance_state NOT IN ('decommissioning', 'decommissioned');
        
        RETURN QUERY SELECT 
            FALSE,
            'Instance has required dependents that must be decommissioned first'::TEXT,
            v_blocking_instances;
    ELSE
        RETURN QUERY SELECT 
            TRUE,
            NULL::TEXT,
            '[]'::jsonb;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### record_upgrade_history
Records an upgrade operation in the version history.

```sql
CREATE OR REPLACE FUNCTION record_upgrade_history(
    p_instance_id UUID,
    p_request_id UUID,
    p_from_version VARCHAR,
    p_to_version VARCHAR,
    p_upgrade_item_name VARCHAR,
    p_status VARCHAR DEFAULT 'success'
) RETURNS VOID AS $$
DECLARE
    v_upgrade_type VARCHAR;
    v_start_time TIMESTAMPTZ;
    v_duration INT;
BEGIN
    -- Determine upgrade type based on version change
    IF split_part(p_from_version, '.', 1) != split_part(p_to_version, '.', 1) THEN
        v_upgrade_type := 'major';
    ELSIF split_part(p_from_version, '.', 2) != split_part(p_to_version, '.', 2) THEN
        v_upgrade_type := 'minor';
    ELSIF split_part(p_from_version, '.', 3) != split_part(p_to_version, '.', 3) THEN
        v_upgrade_type := 'patch';
    ELSE
        v_upgrade_type := 'configuration';
    END IF;
    
    -- Calculate duration if request exists
    IF p_request_id IS NOT NULL THEN
        SELECT created_at INTO v_start_time
        FROM service_requests
        WHERE id = p_request_id;
        
        v_duration := EXTRACT(EPOCH FROM (NOW() - v_start_time))::INT;
    END IF;
    
    -- Insert history record
    INSERT INTO instance_version_history (
        instance_id, from_version, to_version, upgrade_type,
        upgrade_request_id, upgrade_item_name, upgrade_duration_seconds,
        upgrade_status
    ) VALUES (
        p_instance_id, p_from_version, p_to_version, v_upgrade_type,
        p_request_id, p_upgrade_item_name, v_duration,
        p_status
    );
    
    -- Update instance catalog version if successful
    IF p_status = 'success' THEN
        UPDATE service_instances
        SET catalog_version = p_to_version,
            updated_at = NOW()
        WHERE id = p_instance_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

## Additional Indexes for Runtime State Queries

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

-- For service instance queries
CREATE INDEX idx_service_instances_name ON service_instances(instance_name);
CREATE INDEX idx_service_instances_state_updated ON service_instances(instance_state, updated_at DESC);
CREATE INDEX idx_service_instances_owner_state ON service_instances(owner_team, instance_state);
CREATE INDEX idx_service_instances_provisioned ON service_instances(provisioned_at DESC) WHERE provisioned_at IS NOT NULL;

-- For dependency traversal
CREATE INDEX idx_dependencies_provider_required ON service_instance_dependencies(provider_instance_id, is_required);
CREATE INDEX idx_dependencies_dependent_required ON service_instance_dependencies(dependent_instance_id, is_required);

-- For version history queries
CREATE INDEX idx_version_history_instance_status ON instance_version_history(instance_id, upgrade_status);
CREATE INDEX idx_version_history_upgrade_item ON instance_version_history(upgrade_item_name) WHERE upgrade_item_name IS NOT NULL;

-- For eligibility tracking
CREATE INDEX idx_eligible_ops_status_expires ON eligible_operations(eligibility_status, expires_at);
CREATE INDEX idx_eligible_ops_evaluated ON eligible_operations(evaluated_at DESC);

-- For bundle member queries
CREATE INDEX idx_bundle_members_role ON bundle_instance_members(member_role) WHERE member_role IS NOT NULL;

-- For update/upgrade item queries  
CREATE INDEX idx_update_items_tags USING gin(tags);
CREATE INDEX idx_upgrade_items_tags USING gin(tags);
CREATE INDEX idx_update_items_targets USING gin(targets);
CREATE INDEX idx_upgrade_items_targets USING gin(targets);
```

## Notes

- All timestamps use TIMESTAMPTZ to store timezone information
- JSONB is used for flexible schema storage of presentation and fulfillment definitions
- UUIDs are used for internal IDs, with human-readable external IDs where appropriate
- Indexes are created for common query patterns and pagination
- Service instances maintain full lifecycle state from provisioning to decommissioning
- Dependencies are tracked bidirectionally to enable safe decommissioning
- Version history provides audit trail for all upgrades and updates
- Eligibility tracking enables proactive day-2 operations recommendations