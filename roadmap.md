# IDP Orchestrator Development Roadmap

## Phase 1: Repository & Catalog Foundation
- **Orchestrator Catalog Repository Setup**: Create GitHub repository to serve as central document store for CatalogItem definitions
- **CatalogItem Schema Design**: Define structured document format for platform teams to describe their service offerings and fulfillment requirements

## Phase 2: REST API Foundation
- **API Framework Setup**: Establish REST API service framework that will be consumed by the Developer Experience Team's portal
- **Webhook Integration**: Implement webhook endpoint to receive catalog change notifications from GitHub repository
- **Database Setup**: Configure SQL database to track current state of provisioned resources using Terraform-like state management

## Phase 3: Core Orchestration Engine
- **State Management System**: Build Terraform-inspired state verification and reconciliation engine for resource lifecycle management
- **Catalog Processing**: Implement logic to consume and validate CatalogItem documents from repository into unified service catalog
- **Request Routing**: Develop system to route developer requests to appropriate platform teams (compute, databases, messaging, etc.)

## Phase 4: Platform Team Integration
- **Multi-Platform Support**: Create integration points for various platform teams to define and fulfill their service offerings
- **Progressive Automation**: Enable platform teams to evolve from manual JIRA-based fulfillment to full automation at their own pace
- **State Verification**: Implement pre-change verification to ensure resource state consistency before applying modifications