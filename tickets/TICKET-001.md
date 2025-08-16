# TICKET-001: Bootstrap Empty PAO Service

**Reference**: user-stories/001-initial-catalog-sync.md

## Goal
Enable PAO service to start with empty database and sync catalog from Git repository.

## Steps
1. Create database migration scripts for all tables
2. Implement Git repository cloning on service startup
3. Add YAML file discovery in catalog/ directory
4. Implement YAML parser and validator
5. Create catalog item insertion logic with conflict handling
6. Add sync status tracking
7. Implement health check endpoint

## Acceptance Criteria
- [ ] Service creates schema on first run
- [ ] Clones and parses repository on startup
- [ ] Validates YAML against schema
- [ ] Stores valid items in database
- [ ] Skips invalid items with error logging
- [ ] Update sql-schema.md with migrations
- [ ] Add startup sequence to README
- [ ] Unit tests for YAML validation
- [ ] Integration test for full sync