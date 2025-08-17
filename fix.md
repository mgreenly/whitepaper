# Fix: Automatic JIRA Escalation for Bundle Orchestration Failures

## Problem
When CatalogBundle orchestration fails, the current documentation states that "failures require manual intervention" but provides no mechanism for operators to understand what partial state exists or what cleanup actions are needed.

## Solution
Implement automatic JIRA ticket creation for failed bundle orchestration that provides structured failure context to the Orchestration team.

## Implementation Instructions

### 1. Update service.md

**Location**: `/workspace/service.md` - "Multi-Action Fulfillment Engine" section (around line 130)

**Change**: Replace the existing text:
```
- No automatic error recovery; failures stop execution and require manual intervention
```

**With**:
```
- No automatic error recovery; failures stop execution and automatically escalate via JIRA
- Bundle failures create structured JIRA tickets for Orchestration team with partial state inventory
- Request status marked as "escalated" with JIRA ticket reference for tracking
```

### 2. Add Failure Escalation Section

**Location**: `/workspace/service.md` - Add new section after "Variable System" (around line 185)

**Add**:
```markdown
### Failure Escalation System

**Bundle Orchestration Failures**:
When CatalogBundle execution fails, the orchestrator automatically creates a JIRA ticket for the Orchestration team containing:

- **Partial State Inventory**: Which components succeeded/failed and what resources were created
- **Error Context**: Full error messages, logs, and failure timestamps  
- **Cleanup Guidance**: Component-specific cleanup procedures based on action types
- **Request Metadata**: Original request data and user context for troubleshooting

**JIRA Ticket Configuration**:
```yaml
type: jira-ticket
config:
  ticket:
    project: ORCHESTRATION
    issueType: "Incident"
    priority: "High"
    summaryTemplate: "Bundle Orchestration Failure - {{bundle.metadata.name}} ({{request.id}})"
    descriptionTemplate: |
      **Bundle Information**
      Bundle: {{bundle.metadata.name}} ({{bundle.metadata.version}})
      Request ID: {{request.id}}
      User: {{request.user.email}}
      Failure Time: {{failure.timestamp}}
      
      **Component Status**
      {{#each components}}
      - {{id}}: {{status}}{{#if resources}} (Resources: {{join resources ", "}}){{/if}}
      {{/each}}
      
      **Error Details**
      {{failure.error}}
      
      **Cleanup Required**
      {{#each components}}
      {{#if succeeded}}
      - {{id}}: {{cleanup.instructions}}
      {{/if}}
      {{/each}}
      
      **Original Request Data**
      ```json
      {{json request.data}}
      ```
```

**Request Status Updates**:
- Failed requests marked with status: `"escalated"`
- JIRA ticket ID stored in request metadata
- Operators can query escalated requests via API: `GET /api/v1/requests?status=escalated`
```

### 3. Update Database Schema Section

**Location**: `/workspace/service.md` - "Requests Table" definition (around line 240)

**Change**: Add to the existing CREATE TABLE statement:
```sql
    escalation_ticket_id VARCHAR(50),
    escalation_timestamp TIMESTAMP
```

So the complete table becomes:
```sql
CREATE TABLE requests (
    id UUID PRIMARY KEY,
    catalog_item_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    request_data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    escalation_ticket_id VARCHAR(50),
    escalation_timestamp TIMESTAMP
);
```

### 4. Add API Endpoint

**Location**: `/workspace/service.md` - "Essential APIs" section (around line 30)

**Add** to Request Lifecycle endpoints:
```http
GET    /api/v1/requests/escalated                  # List escalated requests
GET    /api/v1/requests/{request_id}/escalation    # Escalation details
```

## Benefits

1. **Structured Escalation**: Transforms vague "manual intervention" into actionable JIRA workflow
2. **Operational Visibility**: Centralized tracking of all orchestration failures
3. **Cleanup Guidance**: Provides specific instructions for each component type
4. **Audit Trail**: Complete failure context preserved for root cause analysis
5. **Leverages Existing Infrastructure**: Uses existing JIRA action framework

## Implementation Priority

This should be implemented in **Q4 2025** as part of the "Bundle Orchestration Engine" deliverable, ensuring that multi-service orchestration has proper failure handling from day one.