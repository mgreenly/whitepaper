# DevCtl - Platform Automation Orchestrator CLI

## Disclaimer

This document contains no proprietary, confidential, or sensitive organizational information and represents generalized industry practices and publicly available methodologies. The content was created with the assistance of agentic AI systems, with human oversight and review applied throughout the process. Users should verify all technical recommendations and adapt them to their specific requirements and constraints.

## Note on Implementation

This document serves as architectural guidance and conceptual inspiration for engineering teams developing catalog repository systems. It is not intended as a precise implementation specification or detailed blueprint. Engineering teams should interpret these concepts, adapt the proposed patterns to their specific technical environment and organizational requirements, and develop their own detailed work plans accordingly. While implementation approaches may vary, the core architectural concepts, data structures, and operational patterns described herein should be represented in the final system design to ensure consistency with the overall platform vision.

## Table of Contents

- [Overview](#overview)
- [Installation & Configuration](#installation--configuration)
- [Global Options](#global-options)
- [Subcommands](#subcommands)
  - [Catalog Management](#catalog-management)
  - [Request Operations](#request-operations)
  - [System Health](#system-health)
  - [Platform Team Tools](#platform-team-tools)
  - [Webhook Operations](#webhook-operations)
- [Authentication](#authentication)
- [Output Formats](#output-formats)
- [Examples](#examples)
- [Future Enhancements](#future-enhancements)

## Overview

DevCtl is a command-line interface for the Platform Automation Orchestrator (PAO) service. It provides developers and platform teams with direct access to all PAO endpoints for testing, automation, and troubleshooting.

**Usage Pattern**: `devctl [GLOBAL-OPTIONS] subcommand [SUB-COMMAND-OPTIONS]`

## Installation & Configuration

```bash
# Install devctl
curl -L https://releases.company.com/devctl/latest/devctl-linux-amd64 -o devctl
chmod +x devctl
sudo mv devctl /usr/local/bin/

# Configure AWS SSO (required for authentication)
aws configure sso
```

## Global Options

| Option | Description | Default |
|--------|-------------|---------|
| `--endpoint <url>` | PAO service endpoint | Uses AWS service discovery |
| `--region <region>` | AWS region | From AWS config |
| `--profile <profile>` | AWS SSO profile | default |
| `--output <format>` | Output format (json, yaml, table) | table |
| `--verbose, -v` | Verbose output | false |
| `--debug` | Debug mode with full HTTP traces | false |
| `--no-color` | Disable colored output | false |
| `--timeout <duration>` | Request timeout | 30s |

## Subcommands

### Catalog Management

Browse and discover available services in the platform catalog.

#### `devctl catalog list`
List all available catalog items and bundles.

**Options:**
- `--category <category>` - Filter by category (compute, databases, etc.)
- `--owner <team>` - Filter by owning team
- `--limit <number>` - Items per page (default: 50)
- `--cursor <token>` - Pagination cursor

**Example:**
```bash
devctl catalog list --category databases --limit 10
```

#### `devctl catalog get <item-id>`
Get detailed information about a specific catalog item.

**Options:**
- `--schema` - Include form schema details
- `--examples` - Show example configurations

**Example:**
```bash
devctl catalog get database-postgresql-standard --schema
```

#### `devctl catalog refresh`
Force refresh the catalog from the GitHub repository.

**Options:**
- `--wait` - Wait for refresh to complete
- `--timeout <duration>` - Refresh timeout (default: 60s)

### Request Operations

Submit and manage service provisioning requests.

#### `devctl request submit <item-id>`
Submit a new service request.

**Options:**
- `--config <file>` - JSON/YAML configuration file
- `--field <key=value>` - Set individual field values (repeatable)
- `--dry-run` - Validate request without submitting
- `--wait` - Wait for completion
- `--follow-logs` - Stream execution logs

**Example:**
```bash
devctl request submit database-postgresql-standard \
  --field instanceName=myapp-db \
  --field instanceClass=db.t3.medium \
  --field storageSize=100 \
  --wait
```

#### `devctl request list`
List your submitted requests.

**Options:**
- `--status <status>` - Filter by status (submitted, in-progress, completed, failed)
- `--catalog-item <item-id>` - Filter by catalog item
- `--since <duration>` - Show requests from last N duration (1h, 1d, 1w)
- `--limit <number>` - Items per page

**Example:**
```bash
devctl request list --status in-progress --since 24h
```

#### `devctl request get <request-id>`
Get detailed information about a specific request.

**Options:**
- `--logs` - Include execution logs
- `--actions` - Show action details

**Example:**
```bash
devctl request get req-123e4567-e89b-12d3-a456-426614174000 --logs
```

#### `devctl request status <request-id>`
Get current status of a request.

**Options:**
- `--watch, -w` - Watch for status changes
- `--interval <duration>` - Polling interval (default: 5s)

#### `devctl request logs <request-id>`
Stream or fetch execution logs for a request.

**Options:**
- `--follow, -f` - Follow log output
- `--tail <lines>` - Show last N lines
- `--action <action-id>` - Filter logs by specific action

### System Health

Monitor and verify system health and performance.

#### `devctl health check`
Check overall system health.

**Options:**
- `--components` - Show individual component health
- `--detailed` - Include performance metrics

#### `devctl health ready`
Check if system is ready to accept requests.

#### `devctl version`
Show service version and build information.

**Options:**
- `--full` - Include detailed build metadata

#### `devctl metrics`
Fetch Prometheus metrics from the service.

**Options:**
- `--filter <pattern>` - Filter metrics by name pattern
- `--format <format>` - Output format (prometheus, json)

### Platform Team Tools

Validation and testing tools for platform teams developing catalog items.

#### `devctl validate catalog-item <file>`
Validate a catalog item definition.

**Options:**
- `--strict` - Enable strict validation mode
- `--schema-version <version>` - Target schema version

**Example:**
```bash
devctl validate catalog-item ./my-service.yaml
```

#### `devctl preview form <file>`
Preview the form that would be generated from a catalog item.

**Options:**
- `--render` - Render as HTML (opens browser)
- `--interactive` - Interactive form preview

#### `devctl test variables <file>`
Test variable substitution in a catalog item.

**Options:**
- `--input <file>` - JSON file with test field values
- `--show-all` - Show all variable scopes
- `--action <action-id>` - Test specific action

**Example:**
```bash
devctl test variables ./my-service.yaml --input test-values.json
```

### Webhook Operations

Simulate and test webhook integrations.

#### `devctl webhook github <event-type>`
Simulate a GitHub webhook event.

**Options:**
- `--payload <file>` - JSON payload file
- `--repository <owner/repo>` - Repository identifier
- `--ref <ref>` - Git reference (branch/tag)

#### `devctl webhook jira <event-type>`
Simulate a JIRA webhook event.

**Options:**
- `--payload <file>` - JSON payload file
- `--issue <key>` - JIRA issue key
- `--status <status>` - Issue status

## Authentication

DevCtl uses AWS SSO for authentication and signs all requests using SigV4. Ensure you have:

1. AWS CLI configured with SSO: `aws configure sso`
2. Valid SSO session: `aws sso login --profile <profile>`
3. Appropriate IAM permissions for PAO service access

The tool automatically detects and uses your current AWS SSO session.

## Output Formats

### Table (Default)
Human-readable tabular output with colored formatting.

### JSON
Machine-readable JSON format suitable for scripting.

```bash
devctl catalog list --output json | jq '.data[].metadata.name'
```

### YAML
YAML format for configuration and pipeline integration.

```bash
devctl catalog get database-postgresql-standard --output yaml
```

## Examples

### Basic Workflow
```bash
# List available services
devctl catalog list --category compute

# Get service details
devctl catalog get compute-eks-containerapp --schema

# Submit a request
devctl request submit compute-eks-containerapp \
  --field appName=myapp \
  --field containerImage=nginx:latest \
  --field replicas=3 \
  --wait

# Check request status
devctl request list --status completed --since 1h
```

### Platform Team Development
```bash
# Validate new service definition
devctl validate catalog-item ./new-service.yaml --strict

# Preview the generated form
devctl preview form ./new-service.yaml --interactive

# Test variable substitution
devctl test variables ./new-service.yaml --input test-data.json
```

### System Monitoring
```bash
# Check system health
devctl health check --detailed

# Monitor metrics
devctl metrics --filter "pao_requests_*"

# Watch request status
devctl request status req-12345 --watch
```

### Automation & CI/CD
```bash
# Submit request and capture ID for pipeline
REQUEST_ID=$(devctl request submit database-postgresql-standard \
  --config production-db.json \
  --output json | jq -r '.id')

# Wait for completion with timeout
devctl request status $REQUEST_ID --watch --timeout 30m

# Get final status for pipeline decision
STATUS=$(devctl request get $REQUEST_ID --output json | jq -r '.status')
```

## Future Enhancements

This section outlines planned enhancements and advanced capabilities for DevCtl beyond the Q3 2025 Foundation Epic.

### Q4 2025: Production Epic Enhancements

#### Missing Core Commands
The following commands are specified in the roadmap but not yet implemented:

**Request Management Extensions**
- `devctl request retry <request-id>` - Retry failed actions with options (--action, --force)
- `devctl request abort <request-id>` - Abort failed requests with confirmation prompts
- `devctl request escalate <request-id>` - Escalate to manual support with context preservation

#### Enhanced Action Type Support

**Terraform Integration**
- `devctl request terraform <request-id>` - Terraform-specific operations (--plan, --apply, --destroy)
- Enhanced `request status` with Terraform plan/apply progress tracking
- Infrastructure state viewing and validation commands
- Terraform log parsing and filtering in `request logs`

**Batch Operations**
- `devctl request batch submit` - Bulk request submission (--config-dir, --parallel)
- `devctl request export` - Export request data for CI/CD integration (--format, --filter)
- Pipeline-friendly output formats and exit codes

#### Advanced Platform Team Tools

**Extended Validation**
- `devctl validate terraform <file>` - Terraform action validation
- `devctl test automation <file>` - End-to-end automation testing
- `devctl debug request <request-id>` - Advanced troubleshooting and diagnostics

**Local Development Support**
- Local mock service for offline development and testing
- Catalog item hot-reloading for rapid iteration
- Schema migration and compatibility testing tools

### Long-term Vision (2026+)

#### Advanced User Experience

**Interactive Mode**
- `devctl interactive` - Full-screen TUI for catalog browsing and request management
- Guided service request wizard with real-time validation
- Visual dependency mapping for complex service bundles
- Interactive troubleshooting assistant

**Smart Automation**
- AI-powered error diagnosis and recovery suggestions
- Predictive catalog recommendations based on usage patterns
- Automated dependency resolution and conflict detection
- Self-healing request retry strategies

#### Enterprise Integration

**Advanced Authentication**
- Multi-factor authentication support
- Role-based access control with fine-grained permissions
- Cross-account and federated identity support
- Just-in-time access requests

**Compliance and Governance**
- `devctl audit` - Comprehensive audit trail reporting
- `devctl compliance` - Compliance validation and reporting
- Policy enforcement with approval workflows
- Automated security scanning and vulnerability assessment

#### Performance and Scale

**High-Performance Operations**
- Parallel request processing with dependency management
- Streaming large dataset operations
- Distributed catalog caching with edge locations
- GraphQL query interface for complex data retrieval

**Advanced Monitoring**
- Real-time performance dashboards
- Predictive capacity planning
- Anomaly detection and alerting
- Custom metrics and reporting

### Technical Implementation Gaps

To support these future enhancements, the following technical foundations need to be established:

#### Architecture Requirements

**HTTP API Integration Layer**
- Comprehensive request/response schema mapping
- Retry and circuit breaker patterns for external service calls
- Streaming response handling for long-running operations
- WebSocket support for real-time status updates

**Configuration Management**
- Hierarchical configuration with environment-specific overrides
- Secure credential management and rotation
- Plugin architecture for extensible functionality
- Hot-reloading configuration without service restart

**Error Handling Framework**
- Structured error codes with localization support
- Context-aware error messages with recovery suggestions
- Progressive error disclosure (summary → details → debug)
- Integration with external error tracking systems

#### Development Workflow

**Build and Testing Infrastructure**
- Cross-platform compilation (Linux, macOS, Windows)
- Automated integration testing against live service
- Performance benchmarking and regression testing
- Security scanning and vulnerability assessment

**Release Management**
- Semantic versioning with backward compatibility guarantees
- Automated release notes generation
- Phased rollout with feature flags
- Rollback capabilities for breaking changes

### Implementation Priority

Enhancements should be prioritized based on:

1. **Q3 Foundation Gaps** - Complete missing core commands (retry, abort, escalate)
2. **Q4 Production Features** - Terraform integration and batch operations
3. **User Experience** - Interactive mode and guided workflows
4. **Enterprise Readiness** - Advanced authentication and compliance features
5. **Performance Optimization** - Parallel processing and caching improvements

This roadmap ensures DevCtl evolves from a functional CLI tool into a comprehensive platform automation interface that supports both developer productivity and enterprise governance requirements.