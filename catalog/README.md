# Service Catalog

This directory contains all service offerings available through the Platform Automation Orchestrator. Services are organized by category to help you find what you need.

## Categories

### [Compute](compute/)
Container orchestration, virtual machines, serverless functions, and batch processing services.

### [Databases](databases/)
Relational databases, NoSQL stores, caching solutions, and data warehousing services.

### [Messaging](messaging/)
Message queues, event streaming, pub/sub systems, and notification services.

### [Networking](networking/)
Load balancers, DNS, CDN, VPN, and network security services.

### [Storage](storage/)
Object storage, file systems, block storage, and backup solutions.

### [Security](security/)
Identity management, secrets management, certificates, and compliance services.

### [Monitoring](monitoring/)
Logging, metrics, tracing, alerting, and observability services.

### [Other](other/)
Miscellaneous services that don't fit into the above categories.

## Adding a New Service

1. Identify the appropriate category
2. Create a new YAML file following the naming convention: `{service-type}-{variant}.yaml`
3. Use the template from `/templates/catalog-item.template.yaml`
4. Follow the schema defined in `/repo.md`
5. Update the category's README with your service
6. Submit a pull request

## Service Lifecycle

Services progress through these stages:

1. **Draft** - Initial definition, not yet available
2. **Preview** - Available for testing in non-production
3. **GA** - Generally available for all environments
4. **Deprecated** - Scheduled for removal, migrate to alternatives
5. **Archived** - No longer available, kept for reference

## Validation

All services must:
- Pass schema validation
- Include complete manual fulfillment instructions
- Define clear SLA expectations
- Have platform team owner approval

## Questions?

Contact the Platform Team or refer to the main [repository documentation](../repo.md).