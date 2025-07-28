# Platform Solutions Automation (PSA) Specification

## 1. Overview

Platform Solutions Automation (PSA) is a lightweight orchestration system designed to standardize and automate infrastructure provisioning requests across multiple platform teams. The system achieves coordination through a shared Git repository containing the Platform Solutions Catalog—a collection of JSON-based platform solution definitions that eliminate the need for organizational restructuring while enabling progressive automation.

### 1.1 Core Components

PSA consists of two primary components:

1. **Platform Solutions Catalog**: A collection of platform solution definitions (JSON documents) that describe available platform solutions, their required inputs, validation rules, and fulfillment mechanisms
2. **Orchestration API**: A RESTful interface that processes requests based on the platform solution definitions and routes them to appropriate fulfillment channels

### 1.2 Design Principles

- **Decentralized Ownership**: Platform teams maintain full control over their platform solutions
- **Progressive Enhancement**: Supports manual fulfillment initially, with optional automation
- **Backwards Compatibility**: All platform solutions must support JIRA ticketing as a fallback
- **Schema-Driven**: All interactions validated against formal JSON schemas
- **Audit Trail**: Git provides complete versioning and compliance history

## 2. Architecture

### 2.1 Repository Structure

```
platform-solutions-catalog/
├── schemas/
│   ├── solution-schema.json       # Master schema for platform solution definitions
│   ├── field-types.json          # Reusable field type definitions
│   └── disposition-types.json    # Fulfillment mechanism schemas
├── solutions/
│   ├── compute/
│   │   ├── ec2-instance.json
│   │   ├── eks-cluster.json
│   │   └── lambda-function.json
│   ├── storage/
│   │   ├── rds-postgres.json
│   │   └── s3-bucket.json
│   └── networking/
│       ├── vpc.json
│       └── load-balancer.json
├── templates/
│   └── example-solution.json
└── README.md
```

### 2.2 Platform Solution Definition Schema

Each platform solution in the catalog is defined by a JSON document with three required sections:

```json
{
  "metadata": {
    "id": "string",
    "version": "string",
    "team": "string",
    "category": "string"
  },
  "fields": {
    // Field definitions
  },
  "dispositions": [
    // Fulfillment mechanisms (JIRA required)
  ],
  "presentation": {
    // UI rendering instructions
  }
}
```

## 3. Field Definitions

### 3.1 Field Structure

Each field in the `fields` section must specify:

```json
{
  "fieldName": {
    "type": "string|integer|float|select|boolean",
    "required": true|false,
    "default": "value",
    "validation": {
      // Type-specific validation rules
    },
    "description": "Human-readable field description",
    "helpText": "Extended help for UI display"
  }
}
```

### 3.2 Supported Field Types

#### 3.2.1 String Fields
```json
{
  "type": "string",
  "validation": {
    "pattern": "^[a-z0-9-]{3,63}$",
    "minLength": 3,
    "maxLength": 63
  }
}
```

#### 3.2.2 Integer Fields
```json
{
  "type": "integer",
  "validation": {
    "minimum": 1,
    "maximum": 1000
  }
}
```

#### 3.2.3 Float Fields
```json
{
  "type": "float",
  "validation": {
    "minimum": 0.0,
    "maximum": 100.0,
    "precision": 2
  }
}
```

#### 3.2.4 Selection Fields
```json
{
  "type": "select",
  "validation": {
    "options": [
      {"value": "t3.micro", "label": "T3 Micro (1 vCPU, 1GB RAM)"},
      {"value": "t3.small", "label": "T3 Small (2 vCPU, 2GB RAM)"}
    ],
    "multiple": false
  }
}
```

#### 3.2.5 Boolean Fields
```json
{
  "type": "boolean",
  "default": false
}
```

## 4. Disposition Mechanisms

### 4.1 Disposition Array

The `dispositions` array defines how requests are fulfilled. At least one JIRA disposition is required:

```json
"dispositions": [
  {
    "type": "jira",
    "config": {
      // JIRA-specific configuration
    }
  },
  {
    "type": "terraform",
    "config": {
      // Terraform generation configuration
    }
  },
  {
    "type": "workflow",
    "config": {
      // GitHub Actions workflow trigger
    }
  }
]
```

### 4.2 JIRA Disposition (Required)

Every platform solution must include a JIRA disposition for fallback processing:

```json
{
  "type": "jira",
  "config": {
    "project": "PLATFORM",
    "issueType": "Service Request",
    "templates": {
      "summary": "{{requestType}} - {{applicationName}}",
      "description": "## Request Details\n\n**Application**: {{applicationName}}\n**Environment**: {{environment}}\n**Instance Type**: {{instanceType}}\n\n## Business Justification\n{{businessJustification}}",
      "customFields": {
        "customfield_10001": "{{teamId}}",
        "customfield_10002": "{{costCenter}}"
      }
    },
    "routing": {
      "assignee": "platform-team-queue",
      "labels": ["psa-request", "{{category}}"]
    }
  }
}
```

### 4.3 Terraform Disposition

For automated infrastructure provisioning:

```json
{
  "type": "terraform",
  "config": {
    "moduleSource": "git::https://github.com/org/terraform-modules//ec2",
    "moduleVersion": "v2.1.0",
    "templates": {
      "instance_type": "{{instanceType}}",
      "instance_count": "{{instanceCount}}",
      "subnet_ids": "data.terraform_remote_state.network.outputs.{{environment}}_subnets",
      "tags": {
        "Name": "{{applicationName}}-{{environment}}",
        "Team": "{{teamId}}",
        "CostCenter": "{{costCenter}}"
      }
    },
    "backend": {
      "s3": {
        "bucket": "terraform-state-{{accountId}}",
        "key": "psa/{{requestId}}/terraform.tfstate"
      }
    }
  }
}
```

### 4.4 Workflow Disposition

For triggering automated workflows:

```json
{
  "type": "workflow",
  "config": {
    "repository": "org/platform-automation",
    "workflow": "provision-infrastructure.yml",
    "inputs": {
      "request_type": "{{_solution.id}}",
      "request_id": "{{_request.id}}",
      "parameters": "{{_json_encode(_request.fields)}}"
    }
  }
}
```

## 5. Presentation Layer

### 5.1 Presentation Structure

The `presentation` section defines how fields are rendered in user interfaces:

```json
"presentation": {
  "title": "EC2 Instance Request",
  "description": "Request a new EC2 instance for your application",
  "groups": [
    {
      "name": "basic_info",
      "label": "Basic Information",
      "order": 1,
      "fields": [
        {
          "field": "applicationName",
          "order": 1,
          "width": "half"
        },
        {
          "field": "environment",
          "order": 2,
          "width": "half"
        }
      ]
    },
    {
      "name": "instance_config",
      "label": "Instance Configuration",
      "order": 2,
      "collapsible": true,
      "fields": [
        {
          "field": "instanceType",
          "order": 1,
          "width": "full"
        }
      ]
    }
  ],
  "actions": {
    "submit": {
      "label": "Submit Request",
      "confirmation": "Are you sure you want to submit this request?"
    },
    "saveDraft": {
      "label": "Save as Draft",
      "enabled": true
    }
  }
}
```

### 5.2 YAML Input Support

Platform solutions can optionally support YAML-based bulk input:

```json
"presentation": {
  "yamlSchema": {
    "enabled": true,
    "example": "applicationName: my-app\nenvironment: production\ninstanceType: t3.medium\ninstanceCount: 3",
    "schema": {
      "$ref": "#/definitions/RequestInput"
    }
  }
}
```

## 6. Validation and Processing

### 6.1 Request Validation Flow

1. **Schema Validation**: Verify request conforms to platform solution schema
2. **Field Validation**: Apply field-specific validation rules
3. **Business Rules**: Execute any custom validation logic
4. **Cost Estimation**: Calculate and display estimated costs
5. **Approval Rules**: Check if request requires additional approvals

### 6.2 Processing Pipeline

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
Disposition Selection
       ↓
    ┌─────┴─────┐
    ↓           ↓
Automated    Manual
    ↓           ↓
Terraform    JIRA
Workflow     Ticket
```

## 7. API Specification

### 7.1 Endpoints

```
GET    /api/v1/catalog                # List all platform solutions
GET    /api/v1/catalog/{id}           # Get specific platform solution
POST   /api/v1/requests               # Submit new request
GET    /api/v1/requests/{id}          # Get request status
GET    /api/v1/requests/{id}/cost     # Get cost estimate
POST   /api/v1/validate               # Validate request without submitting
```

### 7.2 Request Format

```json
POST /api/v1/requests
{
  "solution_id": "compute/ec2-instance",
  "fields": {
    "applicationName": "my-app",
    "environment": "production",
    "instanceType": "t3.medium",
    "instanceCount": 2
  },
  "metadata": {
    "requestor": "user@company.com",
    "team": "mobile-team",
    "ticket": "PROJ-1234"
  }
}
```

## 8. Security and Compliance

### 8.1 Authentication

- All API requests must include valid authentication tokens
- Service-to-service communication uses mTLS
- Git repository access controlled via SSO

### 8.2 Authorization

Authorization is required for all operations.

### 8.3 Audit Trail

- All changes to platform solution definitions tracked in Git
- Request history maintained indefinitely
- Cost tracking integrated with FinOps systems

## 9. Implementation Guidelines

### 9.1 Platform Team Responsibilities

1. Define platform solutions in JSON format
2. Validate solution definitions against master schema
3. Implement fulfillment mechanisms (start with JIRA)
4. Provide cost models for estimation
5. Support progressive automation

### 9.2 Central Team Responsibilities

1. Maintain solution schemas and validation
2. Operate orchestration API
3. Integrate with developer portal (Stratus)
4. Provide libraries and tooling
5. Monitor adoption and usage

### 9.3 Migration Strategy

1. **Phase 1**: Define platform solutions, manual JIRA fulfillment
2. **Phase 2**: Add cost estimation and validation
3. **Phase 3**: Implement automated fulfillment
4. **Phase 4**: Advanced features (recommendations, optimization)

## 10. Example: Complete EC2 Platform Solution Definition

```json
{
  "metadata": {
    "id": "compute/ec2-instance",
    "version": "1.2.0",
    "team": "compute-platform",
    "category": "compute",
    "name": "EC2 Instance",
    "description": "Provision EC2 instances with standard configurations"
  },
  "fields": {
    "applicationName": {
      "type": "string",
      "required": true,
      "validation": {
        "pattern": "^[a-z][a-z0-9-]{2,39}$"
      },
      "description": "Application identifier",
      "helpText": "Lowercase letters, numbers, and hyphens only"
    },
    "environment": {
      "type": "select",
      "required": true,
      "validation": {
        "options": [
          {"value": "dev", "label": "Development"},
          {"value": "staging", "label": "Staging"},
          {"value": "prod", "label": "Production"}
        ]
      },
      "description": "Target environment"
    },
    "instanceType": {
      "type": "select",
      "required": true,
      "default": "t3.micro",
      "validation": {
        "options": [
          {"value": "t3.micro", "label": "T3 Micro (1 vCPU, 1GB RAM) - $0.0104/hour"},
          {"value": "t3.small", "label": "T3 Small (2 vCPU, 2GB RAM) - $0.0208/hour"},
          {"value": "t3.medium", "label": "T3 Medium (2 vCPU, 4GB RAM) - $0.0416/hour"}
        ]
      },
      "description": "EC2 instance type"
    },
    "instanceCount": {
      "type": "integer",
      "required": true,
      "default": 1,
      "validation": {
        "minimum": 1,
        "maximum": 10
      },
      "description": "Number of instances"
    },
    "storage": {
      "type": "integer",
      "required": true,
      "default": 20,
      "validation": {
        "minimum": 8,
        "maximum": 1000
      },
      "description": "Root volume size in GB"
    },
    "businessJustification": {
      "type": "string",
      "required": true,
      "validation": {
        "minLength": 10,
        "maxLength": 500
      },
      "description": "Business reason for this request"
    }
  },
  "dispositions": [
    {
      "type": "jira",
      "config": {
        "project": "PLATFORM",
        "issueType": "Service Request",
        "templates": {
          "summary": "EC2 Instance - {{applicationName}} ({{environment}})",
          "description": "## EC2 Instance Request\n\n**Application**: {{applicationName}}\n**Environment**: {{environment}}\n**Instance Type**: {{instanceType}}\n**Count**: {{instanceCount}}\n**Storage**: {{storage}}GB\n\n**Business Justification**:\n{{businessJustification}}\n\n**Estimated Monthly Cost**: ${{_cost.monthly}}",
          "customFields": {
            "customfield_10001": "{{_metadata.team}}",
            "customfield_10002": "{{_metadata.requestor}}"
          }
        }
      }
    },
    {
      "type": "terraform",
      "config": {
        "moduleSource": "git::https://github.com/company/terraform-modules//ec2",
        "templates": {
          "instance_type": "{{instanceType}}",
          "instance_count": "{{instanceCount}}",
          "root_volume_size": "{{storage}}",
          "application_name": "{{applicationName}}",
          "environment": "{{environment}}"
        }
      }
    }
  ],
  "presentation": {
    "title": "Request EC2 Instance",
    "description": "Provision EC2 instances using approved configurations",
    "groups": [
      {
        "name": "application",
        "label": "Application Details",
        "order": 1,
        "fields": [
          {"field": "applicationName", "order": 1},
          {"field": "environment", "order": 2},
          {"field": "businessJustification", "order": 3}
        ]
      },
      {
        "name": "infrastructure",
        "label": "Infrastructure Configuration",
        "order": 2,
        "fields": [
          {"field": "instanceType", "order": 1},
          {"field": "instanceCount", "order": 2},
          {"field": "storage", "order": 3}
        ]
      }
    ],
    "costEstimate": {
      "enabled": true,
      "formula": "instanceCount * instanceTypeHourlyRate * 730 + (storage - 20) * 0.10"
    }
  }
}
```