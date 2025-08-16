# TICKET-003: Enable Platform Teams to Add Catalog Items

**Reference**: user-stories/002-add-first-catalog-item.md

## Goal
Platform teams can add new service offerings by committing YAML files to the repository.

## Steps
1. Define catalog file naming conventions
2. Implement YAML schema validation
3. Add Git fetch and checkout for specific commits
4. Parse YAML and convert to JSON
5. Insert catalog items with duplicate detection
6. Track file processing in sync status
7. Add validation error reporting

## Acceptance Criteria
- [ ] Valid YAML files create catalog items
- [ ] Invalid YAML files logged but don't break sync
- [ ] Duplicate names handled gracefully
- [ ] Webhook triggers incremental sync
- [ ] File paths preserved in database
- [ ] Update pao-yaml-spec.md with conventions
- [ ] Add example catalog items to repository
- [ ] Unit tests for YAML parsing
- [ ] Integration test for end-to-end flow