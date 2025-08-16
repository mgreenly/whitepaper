# TICKET-002: Implement SHA-Based Incremental Sync

**Reference**: user-stories/001-initial-catalog-setup-revised.md

## Goal
Track and process only changed files between git commits using SHA comparison.

## Steps
1. Implement git diff between SHAs
2. Parse webhook for before/after SHAs
3. Handle NULL last_processed_sha (process all files)
4. Process added files as new items
5. Process modified files as updates
6. Process removed files as soft deletes
7. Update last_processed_sha after success

## Acceptance Criteria
- [ ] Correctly identifies changed files between SHAs
- [ ] Handles first sync (NULL SHA) properly
- [ ] Processes all change types (add/modify/remove)
- [ ] Atomic updates with SHA tracking
- [ ] Handles force pushes gracefully
- [ ] Document SHA tracking logic
- [ ] Unit tests for diff logic
- [ ] Integration test for various git scenarios