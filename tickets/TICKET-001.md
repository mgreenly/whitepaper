# TICKET-001: Enable Bundle Request Submission

**Reference**: user-stories/001-eks-app-with-postgres.md

## Goal
Enable developers to request catalog bundles containing multiple services through the PAO API.

## Steps
1. Add `bundle_request_items` table to track selected bundle components
2. Update `service_requests` table to support bundle parameters
3. Implement `POST /api/v1/requests` endpoint for bundle submissions
4. Add request validation for bundle-specific requirements
5. Create step generation logic for bundle components
6. Implement dependency resolution between bundle items
7. Add output aggregation for completed bundle requests
8. Set up automatic manual ticket creation on step failure

## Acceptance Criteria
- [ ] Bundle requests create appropriate steps for each component
- [ ] Dependencies between components are enforced
- [ ] Failed steps trigger manual ticket creation
- [ ] Request status includes all component steps
- [ ] Bundle outputs aggregate component outputs
- [ ] Update sql-schema.md with new tables
- [ ] Update pao-rest-spec.md with bundle request format
- [ ] Add integration tests for bundle submission
- [ ] Add unit tests for dependency resolution