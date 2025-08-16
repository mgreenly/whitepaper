# TICKET-001: Bootstrap Empty PAO Service

**Reference**: user-stories/001-initial-catalog-setup-revised.md

## Goal
Enable PAO service to start with empty database and process catalog via webhooks.

## Steps
1. Create database migration scripts for all tables
2. Add last_processed_sha tracking column
3. Implement webhook endpoint with signature validation
4. Add logic to list all files when last_sha is NULL
5. Implement diff logic for incremental updates
6. Parse and validate YAML files
7. Insert/update catalog items based on changes

## Acceptance Criteria
- [ ] Service creates schema on first run
- [ ] First webhook processes all catalog files
- [ ] Subsequent webhooks process only changes
- [ ] Tracks last processed SHA
- [ ] Handles added/modified/removed files
- [ ] Update sql-schema.md with SHA tracking
- [ ] Document webhook-driven architecture
- [ ] Unit tests for diff logic
- [ ] Integration test for webhook processing