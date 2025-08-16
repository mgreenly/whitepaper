# devctl - PAO Development CLI Tool

## NAME
devctl - Command-line interface for testing and interacting with the PAO Service

## SYNOPSIS
```
devctl [global-options] <command> [command-options] [arguments]
```

## DESCRIPTION
devctl is a development and testing tool for the Platform Automation Orchestrator (PAO) service. It provides commands to interact with the PAO REST API, validate YAML documents, and manage service requests.

## GLOBAL OPTIONS
```
--api-url URL         PAO API endpoint (default: $PAO_API_URL or http://localhost:8080)
--token TOKEN         Bearer token for authentication (default: $PAO_TOKEN)
--output FORMAT       Output format: json, yaml, table (default: table)
--verbose, -v         Enable verbose output
--debug               Enable debug output with HTTP traces
--config FILE         Config file path (default: ~/.devctl/config.yaml)
--no-color           Disable colored output
--help, -h           Show help
--version            Show version information
```

## COMMANDS

### catalog
Manage and browse the service catalog

#### catalog list
List all catalog items
```
devctl catalog list [options]
  --category CATEGORY   Filter by category (compute, databases, storage, etc.)
  --owner OWNER        Filter by owner team
  --tags TAGS          Filter by tags (comma-separated)
  --limit N            Maximum items to return (default: 50)
  --cursor CURSOR      Pagination cursor
```

#### catalog get
Get details of a specific catalog item
```
devctl catalog get <item-name>
  --version VERSION    Specific version (default: latest)
  --show-yaml         Show original YAML source
```

#### catalog validate
Validate a local YAML file against catalog schema
```
devctl catalog validate <file.yaml>
  --type TYPE         Document type: item, bundle, upgrade, update (auto-detect if not specified)
  --strict           Enable strict validation
```

#### catalog sync
Trigger catalog synchronization
```
devctl catalog sync
  --wait             Wait for sync to complete
  --sha SHA          Sync to specific git SHA
```

### bundle
Manage catalog bundles

#### bundle list
List available bundles
```
devctl bundle list [options]
  --tags TAGS         Filter by tags
```

#### bundle get
Get bundle details
```
devctl bundle get <bundle-name>
  --expand           Show expanded item details
```

### upgrade
Manage service upgrades (Day 2 operations)

#### upgrade list
List available upgrade operations
```
devctl upgrade list [options]
  --target-item ITEM  Filter by target catalog item
  --destructive       Show only destructive upgrades
  --tags TAGS         Filter by tags
```

#### upgrade get
Get upgrade operation details
```
devctl upgrade get <upgrade-name>
  --target ITEM       Show compatibility with specific item
```

#### upgrade apply
Apply an upgrade to existing service
```
devctl upgrade apply <upgrade-name> [options]
  --service-id ID     Target service instance
  --params FILE       Parameters file (JSON or YAML)
  --param KEY=VALUE   Set individual parameter
  --maintenance-window TIME  Schedule maintenance window
  --dry-run          Validate without applying
  --wait             Wait for completion

Example:
  devctl upgrade apply postgres-major-upgrade \
    --service-id svc-postgres-customer-db \
    --param target_version=15.3 \
    --maintenance-window "2025-08-17T02:00:00-05:00"
```

### update
Manage service updates (non-destructive changes)

#### update list
List available update operations
```
devctl update list [options]
  --target-item ITEM  Filter by target catalog item
  --tags TAGS         Filter by tags
```

#### update get
Get update operation details
```
devctl update get <update-name>
  --target ITEM       Show compatibility with specific item
```

#### update apply
Apply an update to existing service
```
devctl update apply <update-name> [options]
  --service-id ID     Target service instance
  --params FILE       Parameters file (JSON or YAML)
  --param KEY=VALUE   Set individual parameter
  --dry-run          Validate without applying
  --wait             Wait for completion

Example:
  devctl update apply postgres-scale-update \
    --service-id svc-postgres-customer-db \
    --param instance_class=db.t3.large \
    --param allocated_storage=200
```

### service
Manage deployed service instances

#### service list
List deployed service instances
```
devctl service list [options]
  --status STATUS     Filter by status (running, stopped, failed, updating)
  --owner OWNER       Filter by owner/requester
  --item ITEM         Filter by catalog item type
  --environment ENV   Filter by environment
  --tags TAGS         Filter by tags
  --limit N           Maximum items to return
  --cursor CURSOR     Pagination cursor
```

#### service get
Get service instance details
```
devctl service get <service-id>
  --show-config      Show current configuration
  --show-outputs     Show service outputs
  --show-history     Show change history
```

#### service status
Check service health and status
```
devctl service status <service-id>
  --watch, -w        Watch for status changes
  --health-check     Run health checks
```

#### service logs
Get service logs
```
devctl service logs <service-id> [options]
  --since DURATION   Show logs since duration (e.g., 1h, 30m)
  --lines N          Number of lines to show
  --follow, -f       Follow log output
  --component COMP   Filter by component
```

#### service history
Show service change history
```
devctl service history <service-id> [options]
  --limit N          Number of changes to show
  --since DATE       Changes since date
  --type TYPE        Filter by change type (create, update, upgrade)
```

### request
Manage service requests

#### request template
Generate parameter template file
```
devctl request template <item-name> [options]
  --output FILE       Output file path (default: stdout)
  --format FORMAT     Output format: json, yaml (default: yaml)
  --with-help        Include help text in template
  --bundle BUNDLE     Generate template for bundle

Example:
  devctl request template postgres-database --output postgres-params.yaml
```

#### request validate
Validate parameters before submission
```
devctl request validate [options]
  --item ITEM         Catalog item name
  --bundle BUNDLE     Catalog bundle name
  --params FILE       Parameters file to validate
  --param KEY=VALUE   Individual parameters to validate

Example:
  devctl request validate --item postgres-database --params postgres-params.yaml
```

#### request submit
Submit a new service request
```
devctl request submit [options]
  --item ITEM         Catalog item name
  --bundle BUNDLE     Catalog bundle name
  --params FILE       Parameters file (JSON or YAML)
  --param KEY=VALUE   Set individual parameter
  --dry-run          Validate without submitting
  --wait             Wait for completion
  --interactive, -i   Interactive parameter entry

Example:
  devctl request submit --item postgres-database \
    --param database_name=mydb \
    --param instance_class=db.t3.small
```

#### request clone
Clone existing request with new parameters
```
devctl request clone <request-id> [options]
  --params FILE       Override parameters file
  --param KEY=VALUE   Override individual parameter
  --name NEW_NAME     New service name
  --dry-run          Validate without submitting

Example:
  devctl request clone req-20250816-abc123 \
    --param database_name=customer_db_prod \
    --param environment=production
```

#### request list
List service requests
```
devctl request list [options]
  --status STATUS     Filter by status (submitted, in_progress, completed, failed)
  --user USER         Filter by requester
  --limit N           Maximum items to return
  --since DATE        Requests since date
```

#### request get
Get request details
```
devctl request get <request-id>
  --steps            Show detailed step information
  --logs             Include step logs
  --watch, -w        Watch for updates
```

#### request resume
Resume a failed request
```
devctl request resume <request-id>
  --from-step STEP   Resume from specific step
  --skip-failed      Skip failed steps
```

#### request abort
Abort an in-progress request
```
devctl request abort <request-id>
  --cleanup          Create cleanup ticket
  --reason REASON    Abort reason
```

#### request retry
Retry a failed step
```
devctl request retry <request-id> <step-id>
  --override-verification   Skip verification
  --timeout DURATION       Override timeout
```

### webhook
Webhook management and testing

#### webhook test
Test webhook connectivity
```
devctl webhook test
  --secret SECRET     Webhook secret
  --event EVENT       Event type (ping, push)
```

#### webhook simulate
Simulate a webhook event
```
devctl webhook simulate [options]
  --event FILE        Event payload file
  --type TYPE         Event type (push, pull_request)
  --sha SHA           Commit SHA to simulate
```

### admin
Administrative commands

#### admin health
Check service health
```
devctl admin health
  --full             Include detailed component status
```

#### admin stats
Get catalog statistics
```
devctl admin stats
  --by-owner         Group by owner
  --by-category      Group by category
```

#### admin validate-all
Validate all catalog items in repository
```
devctl admin validate-all [options]
  --repo-path PATH    Local repository path
  --fix              Attempt to fix issues
```

### config
Manage devctl configuration

#### config init
Initialize configuration
```
devctl config init
  --api-url URL       PAO API URL
  --token TOKEN       Authentication token
```

#### config set
Set configuration value
```
devctl config set <key> <value>

Example:
  devctl config set api-url https://pao.example.com
  devctl config set output json
```

#### config get
Get configuration value
```
devctl config get <key>
```

#### config list
List all configuration
```
devctl config list
```

## AUTHENTICATION

devctl supports multiple authentication methods:

1. **Bearer Token** (recommended for development)
   ```
   export PAO_TOKEN="your-bearer-token"
   devctl catalog list
   ```

2. **AWS IAM** (for production)
   ```
   devctl --auth-type aws catalog list
   ```

3. **Config File**
   ```yaml
   # ~/.devctl/config.yaml
   api_url: https://pao.example.com
   auth:
     type: bearer
     token: your-token-here
   ```

## OUTPUT FORMATS

### Table (default)
Human-readable table format
```
NAME                VERSION    OWNER                  TAGS
postgres-database   2.1.0      platform-data-team    database,postgres
mysql-database      1.5.0      platform-data-team    database,mysql
```

### JSON
Machine-readable JSON format
```
devctl catalog list --output json
```

### YAML
YAML format for easy editing
```
devctl catalog get postgres-database --output yaml
```

## EXAMPLES

### Basic Catalog Operations
```bash
# List all catalog items
devctl catalog list

# Get specific item details
devctl catalog get postgres-database

# Validate a local YAML file
devctl catalog validate ./my-catalog-item.yaml
```

### Submit a Service Request
```bash
# Interactive mode (prompts for required fields)
devctl request submit --item postgres-database

# With parameters file
cat params.json
{
  "database_name": "customer_db",
  "instance_class": "db.t3.medium",
  "allocated_storage": 100
}
devctl request submit --item postgres-database --params params.json

# With inline parameters
devctl request submit --item postgres-database \
  --param database_name=customer_db \
  --param instance_class=db.t3.medium \
  --param allocated_storage=100
```

### Monitor Request Progress
```bash
# Get request status
devctl request get req-20250816-abc123

# Watch request progress
devctl request get req-20250816-abc123 --watch

# Get detailed step information
devctl request get req-20250816-abc123 --steps
```

### Handle Failed Requests
```bash
# Resume from failure
devctl request resume req-20250816-abc123

# Retry specific step
devctl request retry req-20250816-abc123 step-002

# Abort and cleanup
devctl request abort req-20250816-abc123 --cleanup
```

### Test Webhook Integration
```bash
# Test webhook connectivity
devctl webhook test

# Simulate a push event
cat push-event.json | devctl webhook simulate --type push
```

### Administrative Tasks
```bash
# Check service health
devctl admin health

# Get catalog statistics
devctl admin stats --by-owner

# Validate entire catalog
devctl admin validate-all --repo-path /path/to/pao-repository
```

## ENVIRONMENT VARIABLES

```
PAO_API_URL          Default API endpoint
PAO_TOKEN            Default authentication token
PAO_OUTPUT           Default output format
PAO_REPO_PATH        Default repository path for validation
NO_COLOR             Disable colored output
DEBUG                Enable debug output
```

## FILES

```
~/.devctl/config.yaml    User configuration file
~/.devctl/cache/         Response cache directory
~/.devctl/history        Command history
```

## EXIT STATUS

```
0    Success
1    General error
2    Invalid arguments
3    API error
4    Authentication error
5    Validation error
10   Request failed
11   Request aborted
```

## INTERACTIVE MODE

Some commands support interactive mode when required parameters are not provided:

```bash
$ devctl request submit --item postgres-database
? Database Name: customer_db
? Instance Class: (Use arrow keys)
  ▸ db.t3.micro
    db.t3.small
    db.t3.medium
    db.t3.large
? Allocated Storage (GB): 100
? Backup Retention (days): 7

✓ Request submitted: req-20250816-xyz789
```

## SHELL COMPLETION

Generate shell completion scripts:

```bash
# Bash
devctl completion bash > /etc/bash_completion.d/devctl

# Zsh
devctl completion zsh > "${fpath[1]}/_devctl"

# Fish
devctl completion fish > ~/.config/fish/completions/devctl.fish
```

## TROUBLESHOOTING

### Enable Debug Output
```bash
devctl --debug catalog list
# Shows full HTTP request/response
```

### Check Configuration
```bash
devctl config list
devctl admin health
```

### Common Issues

1. **Authentication Failed**
   - Check PAO_TOKEN environment variable
   - Verify token hasn't expired
   - Use `devctl --debug` to see auth headers

2. **Connection Refused**
   - Verify PAO_API_URL is correct
   - Check service is running: `devctl admin health`
   - Check network connectivity

3. **Invalid Response**
   - Service may be returning HTML (check URL)
   - Use `--debug` to see raw response
   - Check API version compatibility

## SEE ALSO

- PAO REST API Specification: pao-rest-spec.md
- PAO YAML Specification: pao-yaml-spec.md
- PAO SQL Schema: sql-schema.md

## VERSION

devctl version 0.1.0 (development)

## AUTHORS

Platform Engineering Team

## REPORTING BUGS

Report bugs to: platform-team@example.com
GitHub Issues: https://github.com/org/pao-devctl/issues