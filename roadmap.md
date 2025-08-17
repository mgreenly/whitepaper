# IDP Orchestrator Development Roadmap

## Phase 1: Repository & Catalog Foundation
- **Orchestrator Catalog Repository Setup**: Create GitHub repository to serve as central document store for CatalogItem definitions
- **CatalogItem Schema Design**: Define two-section document format - presentation fields for user input requirements and action section for fulfillment logic
- **Initial Action Types**: Implement support for three core action targets - JIRA ticket creation, REST API calls, and Terraform file generation
- **Schema Validation**: Create validation rules and examples for CatalogItem documents to ensure consistency across platform teams

## Phase 2: Data-Driven Service Foundation
- **Catalog Repository Population**: Work with platform teams to create initial CatalogItem documents for existing services using the two-section format
- **Schema Testing**: Validate CatalogItem schema with real-world examples from compute, database, and messaging platform teams

## Phase 3: REST API Foundation
- **API Framework Setup**: Establish REST API service framework that will be consumed by the Developer Experience Team's portal
- **Webhook Integration**: Implement webhook endpoint to receive catalog change notifications from GitHub repository
- **Database Setup**: Configure SQL database to track current state of provisioned resources using Terraform-like state management

## Phase 4: Core Orchestration Engine
- **State Management System**: Build Terraform-inspired state verification and reconciliation engine for resource lifecycle management
- **Catalog Processing**: Implement logic to consume and validate CatalogItem documents from repository into unified service catalog
- **Action Engine**: Build execution engine for the three initial action types - JIRA tickets, REST API calls, and Terraform file generation

## Phase 5: Platform Team Integration
- **Multi-Platform Support**: Create integration points for various platform teams to define and fulfill their service offerings
- **Progressive Automation**: Enable platform teams to evolve from manual JIRA-based fulfillment to full automation at their own pace
- **State Verification**: Implement pre-change verification to ensure resource state consistency before applying modifications