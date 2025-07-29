# Platform Solutions Automation (PSA) Specification

> **⚠️ DRAFT SPECIFICATION - IN ACTIVE DEVELOPMENT**
>
> This document represents a work-in-progress specification that is subject to significant changes. It should not be considered final or used for production implementations without further review and approval.
>
> **Status**: Draft v0.1
> **Last Updated**: In Progress
> **Review State**: Not Approved

## 1. Overview

Platform Solutions Automation (PSA) is a lightweight orchestration system designed to standardize and automate infrastructure provisioning requests across multiple platform teams. The system achieves coordination through a shared Git repository containing the Platform Solutions Catalog—a collection of YAML-based platform solution definitions validated against JSON Schemas, eliminating the need for organizational restructuring while enabling progressive automation.

### 1.1 Core Components

PSA consists of three primary components:

1. **Platform Solutions Catalog**: A collection of platform solution definitions (YAML documents) that describe available platform solutions, their required inputs, validation rules, and fulfillment mechanisms
2. **Application Templates**: Source code templates that provide developers with best-practice starting points for applications using specific platform solutions or bundles
3. **Orchestration API**: A RESTful interface that processes requests based on the platform solution definitions and routes them to appropriate fulfillment channels

### 1.2 Design Principles

- **Decentralized Ownership**: Platform teams maintain full control over their platform solutions
- **Progressive Enhancement**: Supports manual fulfillment initially, with optional automation
- **Backwards Compatibility**: All platform solutions must support JIRA ticketing as a fallback
- **Schema-Driven**: All interactions validated against formal JSON schemas
- **Audit Trail**: Git provides complete versioning and compliance history
- **Developer Experience**: Application templates accelerate development with proven patterns

## 2. Architecture

### 2.1 Repository Structure

```
platform-solutions-catalog/
├── schemas/
│   ├── solution-schema.json       # Master JSON Schema for platform solution definitions
│   ├── bundle-schema.json         # JSON Schema for solution bundles
│   ├── field-types.json          # Reusable field type definitions
│   └── fulfillment-types.json    # Fulfillment mechanism schemas
├── solutions/
│   ├── compute/
│   │   ├── ec2-instance.yaml
│   │   ├── eks-cluster.yaml
│   │   └── lambda-function.yaml
│   ├── storage/
│   │   ├── rds-postgres.yaml
│   │   └── s3-bucket.yaml
│   └── networking/
│       ├── vpc.yaml
│       └── load-balancer.yaml
├── bundles/
│   ├── microservice-standard.yaml
│   ├── web-application.yaml
│   └── data-pipeline.yaml
├── templates/
│   ├── example-solution.yaml
│   └── example-bundle.yaml
├── app-templates/
│   ├── microservice-standard/
│   │   ├── README.md
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── src/
│   │   │   └── main.py
│   │   ├── tests/
│   │   │   └── test_main.py
│   │   └── .github/
│   │       └── workflows/
│   │           └── deploy.yml
│   ├── web-application/
│   │   ├── backend/
│   │   ├── frontend/
│   │   └── infrastructure/
│   └── data-pipeline/
│       ├── etl/
│       └── config/
└── README.md
```

### 2.2 Platform Solution Definition Schema

Each platform solution in the catalog is defined by a YAML document validated against JSON Schema with three required sections:

```yaml
# Validated against schemas/solution-schema.json
metadata:
  id: string
  version: string
  team: string
  category: string

fields:
  # Field definitions

fulfillments:
  # Fulfillment mechanisms (JIRA required)

presentation:
  # UI rendering instructions
```

### 2.3 Bundle Definition Schema

Bundles group multiple platform solutions into a single requestable package:

```yaml
# Validated against schemas/bundle-schema.json
metadata:
  id: string
  version: string
  name: string
  description: string
  category: string

solutions:
  - solution_id: compute/ec2-instance
    required: true
    defaults:
      # Override default field values
  - solution_id: storage/rds-postgres
    required: true
    defaults:
      size: medium

presentation:
  title: Microservice Standard Bundle
  description: Complete infrastructure for a standard microservice
  estimatedCost: $850/month

appTemplate:
  repository: app-templates/microservice-standard
  description: Python-based microservice with FastAPI, Docker, and CI/CD
```

## 3. Field Definitions

### 3.1 Field Structure

Each field in the `fields` section must specify:

```yaml
fieldName:
  type: string|integer|float|select|boolean
  required: true|false
  default: value
  validation:
    # Type-specific validation rules
  description: Human-readable field description
  helpText: Extended help for UI display
```

### 3.2 Supported Field Types

#### 3.2.1 String Fields
```yaml
type: string
validation:
  pattern: ^[a-z0-9-]{3,63}$
  minLength: 3
  maxLength: 63
```

#### 3.2.2 Integer Fields
```yaml
type: integer
validation:
  minimum: 1
  maximum: 1000
```

#### 3.2.3 Float Fields
```yaml
type: float
validation:
  minimum: 0.0
  maximum: 100.0
  precision: 2
```

#### 3.2.4 Selection Fields
```yaml
type: select
validation:
  options:
    - value: t3.micro
      label: T3 Micro (1 vCPU, 1GB RAM)
    - value: t3.small
      label: T3 Small (2 vCPU, 2GB RAM)
  multiple: false
```

#### 3.2.5 Boolean Fields
```yaml
type: boolean
default: false
```

## 4. Fulfillment Mechanisms

### 4.1 Fulfillment Array

The `fulfillments` array defines how requests are fulfilled. At least one JIRA fulfillment is required. The list may also include fulfillment types that are not yet implemented but are being considered for future support, such as Crossplane.

```yaml
fulfillments:
  - type: jira
    config:
      # JIRA-specific configuration

  - type: terraform
    config:
      # Terraform generation configuration

  - type: crossplane # Speculative
    config:
      # Crossplane composition configuration

  - type: workflow
    config:
      # GitHub Actions workflow trigger
```

### 4.2 JIRA Fulfillment (Required)

Every platform solution must include a JIRA fulfillment for fallback processing:

```yaml
type: jira
config:
  project: PLATFORM
  issueType: Service Request
  templates:
    summary: "{{requestType}} - {{applicationName}}"
    description: |
      ## Request Details

      **Application**: {{applicationName}}
      **Environment**: {{environment}}
      **Instance Type**: {{instanceType}}

      ## Business Justification
      {{businessJustification}}
    customFields:
      customfield_10001: "{{teamId}}"
      customfield_10002: "{{costCenter}}"
  routing:
    assignee: platform-team-queue
    labels:
      - psa-request
      - "{{category}}"
```

### 4.3 Terraform Fulfillment

For automated infrastructure provisioning:

```yaml
type: terraform
config:
  moduleSource: "git::https://github.com/org/terraform-modules//ec2"
  moduleVersion: v2.1.0
  templates:
    instance_type: "{{instanceType}}"
    instance_count: "{{instanceCount}}"
    subnet_ids: "data.terraform_remote_state.network.outputs.{{environment}}_subnets"
    tags:
      Name: "{{applicationName}}-{{environment}}"
      Team: "{{teamId}}"
      CostCenter: "{{costCenter}}"
  backend:
    s3:
      bucket: "terraform-state-{{accountId}}"
      key: "psa/{{requestId}}/terraform.tfstate"
```

### 4.4 Crossplane Fulfillment (Speculative)

While not currently in use, Crossplane represents a likely future addition for automated provisioning, especially for platform teams that adopt a control plane model. This fulfillment type allows PSA to integrate with Crossplane Compositions.

```yaml
type: crossplane
config:
  compositionName: "composite-ec2-instance"
  compositionVersion: "v1.2.0"
  templates:
    parameters:
      instanceSize: "{{instanceType}}"
      nodeCount: {{instanceCount}}
      networkId: "{{environment}}"
    claim:
      name: "{{applicationName}}-{{environment}}"
      namespace: "psa-claims"
```

### 4.5 Workflow Fulfillment

For triggering automated workflows:

```yaml
type: workflow
config:
  repository: org/platform-automation
  workflow: provision-infrastructure.yml
  inputs:
    request_type: "{{_solution.id}}"
    request_id: "{{_request.id}}"
    parameters: "{{_json_encode(_request.fields)}}"
```

## 5. Presentation Layer

### 5.1 Presentation Structure

The `presentation` section defines how fields are rendered in user interfaces:

```yaml
presentation:
  title: EC2 Instance Request
  description: Request a new EC2 instance for your application
  groups:
    - name: basic_info
      label: Basic Information
      order: 1
      fields:
        - field: applicationName
          order: 1
          width: half
        - field: environment
          order: 2
          width: half

    - name: instance_config
      label: Instance Configuration
      order: 2
      collapsible: true
      fields:
        - field: instanceType
          order: 1
          width: full

  actions:
    submit:
      label: Submit Request
      confirmation: Are you sure you want to submit this request?
    saveDraft:
      label: Save as Draft
      enabled: true
```

### 5.2 YAML Input Support

Platform solutions can optionally support YAML-based bulk input:

```yaml
presentation:
  yamlSchema:
    enabled: true
    example: |
      applicationName: my-app
      environment: production
      instanceType: t3.medium
      instanceCount: 3
    schema:
      $ref: "#/definitions/RequestInput"
```

## 6. Validation and Processing

### 6.1 YAML Validation

All YAML files in the catalog must be validated against their corresponding JSON Schemas:

1. **Solution Definitions**: Validated against `schemas/solution-schema.json`
2. **Bundle Definitions**: Validated against `schemas/bundle-schema.json`
3. **Validation Tools**: Use standard JSON Schema validators that support YAML input
4. **CI/CD Integration**: Validate all YAML files on commit/merge

### 6.2 Request Validation Flow

1. **YAML Parsing**: Parse YAML to internal data structure
2. **Schema Validation**: Verify request conforms to platform solution schema
3. **Field Validation**: Apply field-specific validation rules
4. **Business Rules**: Execute any custom validation logic
5. **Cost Estimation**: Calculate and display estimated costs
6. **Approval Rules**: Check if request requires additional approvals

### 6.3 Processing Pipeline

```
Request Submission
       ↓
Schema Validation
       ↓
Field Validation
       ↓
Cost Estimation
       ↓
Approval Check
       ↓
Fulfillment Selection
       ↓
    ┌─────┴─────┐
    ↓           ↓
Automated    Manual
    ↓           ↓
Terraform    JIRA
Crossplane*  Ticket
Workflow
```
*\*Crossplane is a speculative future option.*

## 7. API Specification

### 7.1 Endpoints

```
GET    /api/v1/catalog                # List all platform solutions
GET    /api/v1/catalog/{id}           # Get specific platform solution
GET    /api/v1/bundles                # List all bundles
GET    /api/v1/bundles/{id}           # Get specific bundle with expanded solutions
POST   /api/v1/requests               # Submit new request (supports multiple solutions/bundles)
GET    /api/v1/requests/{id}          # Get request status
GET    /api/v1/requests/{id}/cost     # Get cost estimate for entire request
POST   /api/v1/validate               # Validate request without submitting
POST   /api/v1/estimate               # Get cost estimate for solutions/bundles
```

### 7.2 Request Format

#### 7.2.1 Single Solution Request

```yaml
POST /api/v1/requests
Content-Type: application/yaml

solutions:
  - solution_id: compute/ec2-instance
    fields:
      applicationName: my-app
      environment: production
      instanceType: t3.medium
      instanceCount: 2

metadata:
  requestor: user@company.com
  team: mobile-team
  ticket: PROJ-1234
```

#### 7.2.2 Bundle Request

```yaml
POST /api/v1/requests
Content-Type: application/yaml

bundles:
  - bundle_id: microservice-standard
    overrides:
      compute/ec2-instance:
        instanceType: t3.large

metadata:
  requestor: user@company.com
  team: mobile-team
  ticket: PROJ-1234
```

#### 7.2.3 Mixed Request (Bundle + Individual Solutions)

```yaml
POST /api/v1/requests
Content-Type: application/yaml

bundles:
  - bundle_id: microservice-standard

solutions:
  - solution_id: monitoring/datadog-integration
    fields:
      serviceName: my-app
      alertingEnabled: true

  - solution_id: storage/s3-bucket
    fields:
      bucketName: my-app-assets
      versioning: true

metadata:
  requestor: user@company.com
  team: mobile-team
  ticket: PROJ-1234
```

### 7.2.4 Request Data Precedence and Merging

When processing a request containing bundles, the final data for each solution is assembled using a clear order of precedence:

1.  **Base Defaults**: The system first loads the default values for each field as defined in the individual `solution.yaml` files.
2.  **Bundle Defaults**: It then applies the values from the `defaults` block within the `bundle.yaml` definition. These values override the base defaults from the individual solutions.
3.  **Request Overrides**: Finally, it applies any values from the `overrides` block in the API request payload. These values override both the base defaults and the bundle defaults.

The final, merged data is then validated to ensure all required fields have a value before the request is sent for fulfillment. This model allows bundle authors to create curated, best-practice configurations while giving consumers the flexibility to customize where necessary.

#### Example: Bundle Request with Override

Consider a bundle that includes a compute solution and a storage solution, each with its own defaults. The API request can override a specific field for just one of those solutions.

```yaml
bundles:
  - bundle_id: microservice-standard
    overrides:
      # Override a field for ONLY the rds-postgres solution.
      # The eks-container solution will use its defaults from the bundle.
      storage/rds-postgres:
        storage: 200 # Override default of 100GB from the bundle

metadata:
  requestor: user@company.com
  team: mobile-team
```

## 8. Security and Compliance

The security model for the Platform Solutions Automation (PSA) system is designed to be robust, auditable, and aligned with modern cloud-native and GitOps best practices.

### 8.1 PSA API Security

The core PSA Orchestration API is the central component of the system and is secured as follows:

-   **Runtime Environment**: The API runs as a containerized application on the AWS Elastic Kubernetes Service (EKS).
-   **AWS Permissions**: The API leverages **IAM Roles for Service Accounts (IRSA)**. This allows the Kubernetes service account to assume a fine-grained IAM role, granting the API pod temporary, least-privilege access to necessary AWS resources without the need for static credentials.
-   **Secret Management**: All internal secrets required by the API (e.g., database connection strings, credentials for external services) are stored securely in **AWS Parameter Store**. The IRSA role provides the API with the necessary permissions to retrieve these secrets at runtime.

### 8.2 Authentication and Authorization

-   **User Authentication**: All API requests from end-users must include a valid authentication token (e.g., OAuth 2.0 Bearer Token) issued by the organization's central identity provider. The specific authentication flow will be determined by the integrating client (e.g., the developer portal).
-   **Authorization Model**: A role-based access control (RBAC) model will be implemented to govern access to solutions and actions. This model will define which users or groups can request specific platform solutions, particularly for sensitive environments like production. For example, a request to a `prod` environment may require the user to be part of a specific Active Directory group.

### 8.3 Fulfillment and GitOps Workflow

The PSA system follows a strict GitOps pattern, ensuring a complete and auditable trail for all infrastructure changes.

-   **Separation of Duties**: The PSA API's responsibility ends with the creation of a Pull Request. It **does not** have the ability to directly modify infrastructure.
-   **GitHub Authentication**: To interact with GitHub, the PSA API authenticates as a **GitHub App**. This is a highly secure method that provides granular permissions and avoids the use of user-based Personal Access Tokens (PATs). The app's credentials are a secret managed by the API and stored in AWS Parameter Store.
-   **Governance**: The creation and permissions of the GitHub App are managed through an internal governance process that links its identity and access rights to the organization's Active Directory. This ensures that the service's ability to interact with code repositories is centrally managed and auditable.
-   **Audit Trail**: The entire lifecycle of a request is tracked:
    1.  The initial request is logged by the PSA API.
    2.  The proposed infrastructure change is captured immutably in a Git commit and Pull Request.
    3.  A separate, out-of-scope system is responsible for the approval and application of the PR, providing a final layer of human or automated review.

## 9. Governance

The Platform Solutions Catalog is a critical shared resource. A lightweight governance model is essential to ensure its stability, quality, and collaborative evolution. This model defines the "social contract" for how teams interact with the catalog.

### 9.1 Roles and Responsibilities

-   **Solution Owner**: A designated individual or group from a Platform Team responsible for the lifecycle of a specific platform solution definition. They create, maintain, and test their `solution.yaml` files.
-   **Catalog Maintainer**: A role filled by the Central Team (see 10.2) responsible for the overall health of the catalog. They manage the core schemas, validate contributions, and facilitate the change management process.

### 9.2 Change Management

All changes to the catalog are managed through pull requests to the `platform-solutions-catalog` repository.

-   **Review Process**: Pull requests must be reviewed and approved by at least one Catalog Maintainer and the designated Solution Owner(s) if the change affects an existing solution.
-   **Service Level Agreement (SLA)**: The goal is to review and provide feedback on all pull requests within two business days.
-   **Breaking Changes**: Any proposed change to the master schemas (`solution-schema.json`, etc.) requires a more rigorous review. This includes an announcement in the designated communication channel and a review period to allow all platform teams to assess the impact.

### 9.3 Platform Council

To facilitate collaboration and guide the evolution of the PSA system, a Platform Council will be established.

-   **Membership**: The council will consist of representatives (e.g., Solution Owners) from each participating platform team and members of the Central Team.
-   **Mandate**: The council will meet regularly (e.g., bi-weekly) to:
    -   Review significant or contentious proposed changes.
    -   Discuss new solution ideas and patterns.
    -   Resolve conflicts and make decisions on the evolution of the core schemas.
    -   Act as the primary forum for cross-team communication regarding the PSA ecosystem.

## 10. Implementation Guidelines

### 10.1 Platform Team Responsibilities

1. Define platform solutions in YAML format
2. Validate solution definitions against JSON Schema
3. Implement fulfillment mechanisms (start with JIRA)
4. Provide cost models for estimation
5. Support progressive automation
6. Collaborate with application teams to create relevant app templates

### 10.2 Central Team Responsibilities

1. Maintain solution schemas and validation
2. Operate orchestration API
3. Integrate with developer portal (Stratus)
4. Provide libraries and tooling
5. Monitor adoption and usage
6. Coordinate app template contributions across teams

### 10.3 Application Team Responsibilities

1. Contribute app templates for common use cases
2. Maintain templates with security updates and best practices
3. Provide documentation and examples
4. Test templates with platform solutions
5. Gather feedback from template users

### 10.4 Migration Strategy

1. **Phase 1**: Define platform solutions in YAML, manual JIRA fulfillment
2. **Phase 2**: Add cost estimation and JSON Schema validation, initial app templates
3. **Phase 3**: Implement automated fulfillment, expand template library
4. **Phase 4**: Advanced features (recommendations, optimization, template generation)

### 10.5 Communication Channels

To ensure clear and transparent communication across all participating teams, the following channels will be established:

-   **Primary Channel**: A dedicated public channel (e.g., `#platform-solutions` on Slack/Teams) will be the main hub for questions, announcements, and general discussion related to the PSA system.
-   **Platform Office Hours**: The Central Team will hold regular, scheduled office hours. This provides a dedicated time for any team to get help, ask questions about creating solutions, or demo new templates.

## 11. Examples

### 10.1 Complete EC2 Platform Solution Definition

```yaml
# Validated against schemas/solution-schema.json
metadata:
  id: compute/ec2-instance
  version: 1.2.0
  team: compute-platform
  category: compute
  name: EC2 Instance
  description: Provision EC2 instances with standard configurations
fields:
  applicationName:
    type: string
    required: true
    validation:
      pattern: ^[a-z][a-z0-9-]{2,39}$
    description: Application identifier
    helpText: Lowercase letters, numbers, and hyphens only

  environment:
    type: select
    required: true
    validation:
      options:
        - value: dev
          label: Development
        - value: staging
          label: Staging
        - value: prod
          label: Production
    description: Target environment

  instanceType:
    type: select
    required: true
    default: t3.micro
    validation:
      options:
        - value: t3.micro
          label: T3 Micro (1 vCPU, 1GB RAM) - $0.0104/hour
        - value: t3.small
          label: T3 Small (2 vCPU, 2GB RAM) - $0.0208/hour
        - value: t3.medium
          label: T3 Medium (2 vCPU, 4GB RAM) - $0.0416/hour
    description: EC2 instance type

  instanceCount:
    type: integer
    required: true
    default: 1
    validation:
      minimum: 1
      maximum: 10
    description: Number of instances

  storage:
    type: integer
    required: true
    default: 20
    validation:
      minimum: 8
      maximum: 1000
    description: Root volume size in GB

  businessJustification:
    type: string
    required: true
    validation:
      minLength: 10
      maxLength: 500
    description: Business reason for this request
fulfillments:
  - type: jira
    config:
      project: PLATFORM
      issueType: Service Request
      templates:
        summary: "EC2 Instance - {{applicationName}} ({{environment}})"
        description: |
          ## EC2 Instance Request

          **Application**: {{applicationName}}
          **Environment**: {{environment}}
          **Instance Type**: {{instanceType}}
          **Count**: {{instanceCount}}
          **Storage**: {{storage}}GB

          **Business Justification**:
          {{businessJustification}}

          **Estimated Monthly Cost**: ${{_cost.monthly}}
        customFields:
          customfield_10001: "{{_metadata.team}}"
          customfield_10002: "{{_metadata.requestor}}"

  - type: terraform
    config:
      moduleSource: "git::https://github.com/company/terraform-modules//ec2"
      templates:
        instance_type: "{{instanceType}}"
        instance_count: "{{instanceCount}}"
        root_volume_size: "{{storage}}"
        application_name: "{{applicationName}}"
        environment: "{{environment}}"
presentation:
  title: Request EC2 Instance
  description: Provision EC2 instances using approved configurations
  groups:
    - name: application
      label: Application Details
      order: 1
      fields:
        - field: applicationName
          order: 1
        - field: environment
          order: 2
        - field: businessJustification
          order: 3

    - name: infrastructure
      label: Infrastructure Configuration
      order: 2
      fields:
        - field: instanceType
          order: 1
        - field: instanceCount
          order: 2
        - field: storage
          order: 3

  costEstimate:
    enabled: true
    formula: instanceCount * instanceTypeHourlyRate * 730 + (storage - 20) * 0.10
```

### 10.2 Microservice Standard Bundle Definition

```yaml
# Validated against schemas/bundle-schema.json
metadata:
  id: bundles/microservice-standard
  version: 1.0.0
  name: Microservice Standard Bundle
  description: Complete infrastructure setup for a standard microservice including compute, database, and networking
  category: bundles
solutions:
  - solution_id: compute/eks-container
    required: true
    defaults:
      cpu: "2"
      memory: 4Gi
      replicas: 2

  - solution_id: storage/rds-postgres
    required: true
    defaults:
      instanceClass: db.t3.medium
      storage: 100
      multiAZ: true

  - solution_id: networking/load-balancer
    required: true
    defaults:
      type: application
      scheme: internal

  - solution_id: monitoring/basic-observability
    required: false
    defaults:
      logRetention: 30
      metricsEnabled: true
presentation:
  title: Microservice Standard Bundle
  description: Everything you need to deploy a production-ready microservice
  icon: microservice
  estimatedCost:
    monthly: $850
    breakdown:
      compute: $250
      database: $400
      networking: $150
      monitoring: $50
  tags:
    - recommended
    - production-ready
    - best-practice

appTemplate:
  repository: app-templates/microservice-standard
  description: Production-ready microservice with monitoring, logging, and CI/CD
  features:
    - Health checks and readiness probes
    - Structured logging with correlation IDs
    - Metrics collection for Prometheus
    - OpenAPI documentation
    - GitHub Actions deployment pipeline
```

### 10.3 Web Application Bundle with Nested Bundles

```yaml
# Validated against schemas/bundle-schema.json
metadata:
  id: bundles/web-application-complete
  version: 2.0.0
  name: Complete Web Application Stack
  description: Full-stack web application with frontend, backend, and data layer
  category: bundles

bundles:
  - bundle_id: bundles/microservice-standard
    required: true
    label: Backend Services

solutions:
  - solution_id: compute/cloudfront-distribution
    required: true
    label: Frontend CDN
    defaults:
      priceClass: PriceClass_100

  - solution_id: storage/s3-static-website
    required: true
    label: Frontend Assets
    defaults:
      versioning: true
      lifecycle: 90days

  - solution_id: security/waf-rules
    required: false
    label: Web Application Firewall
    defaults:
      ruleSet: standard

presentation:
  title: Complete Web Application Stack
  description: Production-ready web application with CDN, backend services, and security
  groups:
    - name: frontend
      label: Frontend Infrastructure
      solutions:
        - compute/cloudfront-distribution
        - storage/s3-static-website

    - name: backend
      label: Backend Infrastructure
      bundles:
        - bundles/microservice-standard

    - name: security
      label: Security & Compliance
      solutions:
        - security/waf-rules

  estimatedCost:
    monthly: $1,200
    note: Includes all nested bundle costs
```
