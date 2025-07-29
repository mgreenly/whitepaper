# Analysis of Gaps in PSA Specification (v2)

### 1. Executive Summary

The Platform Solutions Automation (PSA) specification has evolved into a robust blueprint, having successfully addressed the major organizational, governance, and security gaps identified in the initial analysis. The document now clearly defines the "social contract," security posture, and communication channels necessary for such a system to succeed.

With the foundational elements in place, the analysis now shifts from the "why" to the "how." The most critical remaining gaps are in the detailed operational and logical workings of the system. The specification must now answer more granular questions about versioning, error handling, fulfillment logic, and the user feedback loop to be considered implementation-ready.

---

### 2. Critical Implementation Gaps

#### 2.1. The Versioning and Lifecycle Gap

The specification includes a `version` field for solutions and bundles, but it does not define the lifecycle or the dependency management that this implies.

*   **The Problem:** Versioning is a critical and complex part of managing a catalog of interdependent software. The current spec leaves key questions unanswered:
    *   **Breaking Changes:** What happens when a platform team releases a new, breaking version of a solution (e.g., `v2.0.0`)? How are existing bundles that depend on `v1.x` handled? Does the API prevent the deletion of an old version that is still in use?
    *   **Dependency Resolution:** Can a bundle specify a version range (e.g., `~1.2`) for a solution, or must it be pinned exactly?
    *   **Lifecycle Management:** What is the process for deprecating and eventually decommissioning an old version of a solution? How is this communicated to users who may still be using it?

*   **Suggestion for Improvement:**
    *   **Adopt Semantic Versioning (SemVer):** Formally state that all solutions and bundles MUST adhere to SemVer (`MAJOR.MINOR.PATCH`).
    *   **Define a Versioning Policy:** Document a clear policy in the "Governance" section. For example:
        *   `PATCH` releases (bug fixes) should be transparent and safe to auto-update.
        *   `MINOR` releases (new, non-breaking features) should be opt-in.
        *   `MAJOR` releases (breaking changes) require a new solution ID (e.g., `ec2-instance-v2`) or a formal migration plan communicated via the Platform Council.
    *   **Enhance the API:** Add an endpoint (`GET /api/v1/catalog/{id}/versions`) to list all available versions of a solution. The primary `GET /api/v1/catalog/{id}` endpoint should return the *latest stable* version by default.

#### 2.2. The Fulfillment Logic Gap

The specification allows for multiple fulfillment types in the `fulfillments` array but does not define the logic for how one is chosen.

*   **The Problem:** The orchestration API needs a deterministic way to decide which fulfillment method to execute.
    *   Is it a simple order of preference (e.g., always try `terraform` first, then `jira`)?
    *   Can a user explicitly request a specific fulfillment type (e.g., "I need a JIRA ticket for this, even though it could be automated")?
    *   How does the system handle fulfillment failure? If the `terraform` fulfillment fails, does it automatically fall back to creating a `jira` ticket?

*   **Suggestion for Improvement:**
    *   **Define Fulfillment Strategy:** Add a `fulfillmentStrategy` field to the `metadata` section of a solution. The default could be `failover`.
        *   `failover`: The orchestrator attempts fulfillments in the order they are listed in the array. If one fails, it proceeds to the next.
        *   `manual`: The orchestrator ignores automated fulfillments and proceeds directly to the first manual one (e.g., `jira`).
    *   **Allow User Selection:** The API request (`POST /api/v1/requests`) could accept an optional `fulfillmentHint` field to allow the user to override the default strategy.
    *   **Document the Flow:** Add a flowchart or sequence diagram to the "Processing Pipeline" section that clearly illustrates this logic.

#### 2.3. The User Feedback and Error Handling Gap

The specification defines a successful GitOps workflow but is silent on what happens when things go wrong and how that is communicated back to the end-user.

*   **The Problem:** The developer experience breaks down if the user's request is accepted (HTTP 202) but then fails silently in a downstream system.
    *   If the Terraform PR fails its automated checks, how does the requesting user get notified?
    *   How are validation errors from the fulfillment engine (e.g., Terraform plan fails) surfaced to the user who submitted the request?
    *   The `GET /api/v1/requests/{id}` endpoint needs a more detailed response schema that can capture the status of each stage of the fulfillment process.

*   **Suggestion for Improvement:**
    *   **Define a `status` model for requests.** The request status should be more granular than just "pending" or "complete." It should include states like `validating`, `fulfillment_pending`, `fulfillment_failed`, `pr_created`, `pr_merged`, `pr_closed`, `succeeded`.
    *   **Integrate with a Notification Service:** The orchestration API should be responsible for sending notifications (e.g., via Slack, Teams, or email) to the requesting user when the status of their request changes, especially on failure.
    *   **Surface Error Details:** The `GET /api/v1/requests/{id}` response should include a structured `error` object with details from the fulfillment engine when a request fails.

#### 2.4. The "Day 2" Operations Gap

The specification is heavily focused on "Day 1" provisioning. It does not address how a developer interacts with a solution *after* it has been provisioned.

*   **The Problem:** Provisioning is only the first step. Users will need to update, reconfigure, or decommission their resources.
    *   How does a user change the instance size of their EC2 instance? Do they submit a new request for the same application, and the system generates a modifying PR?
    *   How are resources decommissioned? Is there a `DELETE /api/v1/requests/{id}` endpoint that would trigger a PR to destroy the resources?
    *   How does the PSA system track the state of provisioned resources? Does it need its own database, or is the Git repo the single source of truth for desired state?

*   **Suggestion for Improvement:**
    *   **Clarify the State Management Model:** Explicitly state that the Git repository for the target environment is the source of truth for the *desired state*. The PSA API does not maintain its own state database of resources.
    *   **Define Update and Delete Workflows:**
        *   **Update:** Document that modifying a resource is done by submitting a new request for the *exact same resource identifier* (e.g., same application name and environment). The orchestrator should then generate a PR that modifies the existing Terraform files.
        *   **Delete:** Propose a `DELETE /api/v1/requests/{id}` endpoint or a new `POST /api/v1/decommission` endpoint. This action would trigger a PR that removes the relevant Terraform configuration.
    *   **Add Endpoints for Discovery:** Users will need to see what they've already provisioned. Add endpoints like `GET /api/v1/requests?requestor=me` to support this.