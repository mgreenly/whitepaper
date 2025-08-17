# DevCtl - Platform Automation Orchestrator CLI

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