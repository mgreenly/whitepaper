# Platform Automation Orchestrator - Customer Requirements

## User Group 1: End User Developer Customers

**Context**: Developers at a large retailer who need platform services to build and deploy applications that support revenue-generating business operations.

**Current Pain Points** (derived from whitepaper.md, roadmap.md and catalog.md):
- Multi-week delays for basic platform resources due to fragmented JIRA processes across Platform Teams
- Must navigate complex multi-team dependency chains across compute, storage, messaging, and networking teams
- High cognitive load learning internal bureaucracy instead of focusing on building software that supports the business
- Manual handoffs create bottlenecks and delays in innovation cycles
- Development capacity constrained by speed of platform resource delivery, directly impacting competitive edge
- Fragmented developer experience forces engineers to become experts in navigating internal processes rather than building software

**User Stories**:

**US-001**: As a developer, I want to provision a complete application stack (database + compute + secrets) in minutes instead of weeks, so I can focus on writing code that directly supports our strategic business goals rather than navigating internal processes.

**US-002**: As a developer, I want a modern self-service portal with a unified catalog of platform services, so I can discover and request resources without dependency on multiple Platform Teams and their individual processes.

**US-003**: As a developer, I want to fill out a simple form with my requirements (instance size, storage needs, replicas) and get back a working environment, so I don't need to learn the specifics of each platform team's process or submit multiple JIRA tickets.

**US-004**: As a developer, I want to track the status of my provisioning requests in real-time through a single interface, so I know when my resources will be available and can plan my development work accordingly.

**US-005**: As a developer, I want to reuse successful configurations as templates for similar projects, so I can quickly provision consistent environments and accelerate delivery cycles for new applications.

**US-006**: As a developer, I want clear error messages and troubleshooting guidance when requests fail, so I can resolve issues quickly without losing development velocity or escalate appropriately to the right Platform Team.

**US-007**: As a developer, I want the platform to remove friction from my workflow, so our organization's capacity for innovation increases and we maintain our competitive edge in the market.

## User Group 2: Developer Portal Developers

**Context**: The team building the developer portal interface that serves as the "single pane of glass" through which developers interact with the Internal Developer Platform (IDP).

**Current Pain Points** (derived from whitepaper.md reference architecture and catalog.md schema requirements):
- Need to create dynamic forms from catalog item definitions that represent the convergence point for Platform Team collaboration
- Must handle complex variable scoping and data flow between components in the catalog document store
- Required to validate user input and provide helpful error messages for the self-service experience
- Need to integrate with multiple backend systems (JIRA, REST APIs, etc.) while presenting a unified interface
- Must present Platform Team offerings in a discoverable way that abstracts the underlying complexity
- Need to support the Reference Architecture's Developer Control Plane as the primary user interface

**User Stories**:

**US-008**: As a portal developer, I want catalog items to define their input requirements in a standardized schema, so I can automatically generate appropriate form fields (text inputs, dropdowns, checkboxes, etc.) for the unified self-service experience.

**US-009**: As a portal developer, I want the catalog document store to specify field validation rules (patterns, required fields, enum values), so I can provide real-time validation feedback that prevents user errors before submission.

**US-010**: As a portal developer, I want a clear separation between form presentation (input.form.groups) and fulfillment logic, so I can focus on UI/UX for the Developer Control Plane without needing to understand backend provisioning details.

**US-011**: As a portal developer, I want catalog bundles to define their complete input requirements, so I can present a single comprehensive form that collects all necessary data for multi-component deployments and eliminates multiple handoffs.

**US-012**: As a portal developer, I want standardized naming conventions (camelCase fields, kebab-case IDs) enforced by schema validation, so I can build consistent UI components that work reliably across all Platform Team offerings.

**US-013**: As a portal developer, I want to retrieve catalog metadata (categories, descriptions, versions) through a REST API, so I can organize and present services in a logical browsing interface that helps users discover Platform Team capabilities.

**US-014**: As a portal developer, I want the platform to provide discovery and presentation capabilities that make the fragmented landscape of Platform Team offerings appear as a cohesive, unified platform to end users.

## User Group 3: Platform Teams

**Context**: Teams that own specific platform domains (databases, compute, networking, security) and need to make their offerings available through the central document store that serves as the convergence point for collaboration.

**Current Pain Points** (derived from whitepaper.md and roadmap.md governance requirements):
- Need to define their services in the central document store without becoming catalog experts
- Want to maintain full ownership and control over their fulfillment processes while participating in the unified platform
- Need clear ownership boundaries and review processes that respect their domain expertise
- Want to evolve from manual JIRA fulfillment to full automation at their own pace without blocking other teams' progress
- Must balance focus on creating platform offerings with the effort required to add them to the catalog
- Need to participate in the platform orchestration without disrupting their existing operational processes

**User Stories**:

**US-015**: As a platform team member, I want to define my service using simple YAML templates with comprehensive examples, so I can contribute to the central document store without learning complex schemas from scratch.

**US-016**: As a platform team member, I want to start with JIRA-ticket fulfillment and gradually add automation, so I can participate in the platform immediately while building automation capabilities over time without blocking progress.

**US-017**: As a platform team member, I want CODEOWNERS to ensure only my team can modify our service definitions, so we maintain full ownership and control over our offerings while collaborating through the shared convergence point.

**US-018**: As a platform team member, I want validation scripts that check my service definitions locally, so I can catch errors before submitting pull requests and avoid breaking the catalog system.

**US-019**: As a platform team member, I want to define custom metadata fields (defaultPort, engineType) specific to my services, so I can provide relevant technical information that other components and teams can reference.

**US-020**: As a platform team member, I want clear variable scoping rules that let me reference user input and system context in my JIRA templates, so I can create meaningful tickets with all necessary information for my team's fulfillment process.

**US-021**: As a platform team member, I want the orchestrator to handle all error handling and retry logic, so I can focus on defining what should happen rather than how failures are managed across the platform.

**US-022**: As a platform team member, I want to make my team's offerings available through the platform without adding unnecessary burden, so I can focus on creating high-quality platform services rather than learning catalog management.

## User Group 4: Architects and Leaders

**Context**: Technical leaders and architects who need to prioritize platform capabilities, ensure architectural consistency, and transform the Internal Developer Platform from a source of delay into a strategic accelerator for business goals.

**Current Pain Points** (derived from whitepaper.md strategic context and roadmap.md priorities):
- Organization's capacity for innovation is directly constrained by the speed at which development teams can deliver new applications
- Need to coordinate work across multiple Platform Teams to create a cohesive platform experience
- Must ensure architectural consistency while maintaining team autonomy and respecting existing organizational structure
- Need visibility into platform adoption, usage patterns, and business impact to measure success
- Must balance innovation speed with operational stability during critical business periods (holiday sales, restricted change windows)
- Must work within operational calendar constraints that limit large-scale technology initiatives during revenue-critical periods
- Need to demonstrate value delivery quickly while building toward a fully automated future state

**User Stories**:

**US-023**: As an architect, I want a formal Reference Architecture that defines the logical design of our Internal Developer Platform independent of organizational structure, so we have a shared understanding and blueprint for building the Platform Automation Orchestrator.

**US-024**: As an architect, I want a clear roadmap with prioritized layers (Foundation → Schema → Samples → Testing → Governance), so I can sequence Platform Team work to avoid dependencies and deliver incremental value that aligns with our business rhythms.

**US-025**: As an architect, I want the Platform Automation Orchestrator to serve as the central coordination point where Platform Teams make their offerings available, so we create a unified platform experience without disrupting existing organizational structure.

**US-026**: As an architect, I want schema versioning and validation rules that enforce architectural standards, so Platform Teams can innovate within defined boundaries without breaking system consistency or the overall platform vision.

**US-027**: As an architect, I want governance controls (CODEOWNERS, required reviews) that preserve Platform Team autonomy while ensuring architectural oversight for schema changes and new patterns that affect the overall platform.

**US-028**: As a technical leader, I want metrics on catalog adoption, provisioning times, and failure rates, so I can measure the business impact of removing friction from our developer experience and demonstrate ROI.

**US-029**: As a technical leader, I want to see which Platform Teams are ready to contribute and which need additional support, so I can allocate resources effectively and remove blockers that prevent teams from participating in the unified platform.

**US-030**: As a technical leader, I want the implementation to respect our operational calendar constraints (holiday sales periods, restricted change windows), so we can deliver value incrementally without disrupting critical revenue-supporting activities.

**US-031**: As an architect, I want Platform Teams to progress from manual JIRA workflows to full automation at their own pace, so we can realize immediate value while building toward a fully automated future state that supports our strategic business goals.

**US-032**: As a technical leader, I want clear success metrics for each implementation layer, so I can track progress toward transforming our Internal Developer Platform from a source of delay into a strategic accelerator for innovation and competitive advantage.