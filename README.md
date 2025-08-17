# Platform Automation Orchestrator - Catalog Repository

## Quick Start

This repository contains the service catalog definitions for the Platform Automation Orchestrator (PAO). Platform teams contribute service offerings through structured YAML documents that define both the user interface and fulfillment logic.

## Repository Structure

- **`catalog/`** - Service catalog organized by category
- **`schema/`** - JSON schemas for validation
- **`templates/`** - Example templates for new services
- **`repo.md`** - Comprehensive documentation and governance

## For Platform Teams

1. Choose the appropriate category under `catalog/`
2. Copy the template from `templates/catalog-item.template.yaml`
3. Define your service following the schema
4. Submit a pull request for review

## For Developers

Browse available services in the `catalog/` directory. Each service definition includes:
- Required inputs and validation rules
- Expected provisioning time and SLA
- Manual and automated fulfillment options

## Documentation

- [Repository Documentation](repo.md) - Detailed schema and governance
- [Whitepaper](whitepaper.md) - Platform strategy and architecture
- [Roadmap](roadmap.md) - Development timeline

## Validation

All catalog items are automatically validated against the schema on commit. Run local validation:

```bash
# Install validator
npm install -g yaml-schema-validator

# Validate a catalog item
yaml-schema-validator catalog/compute/container-app.yaml schema/catalog-item.schema.yaml
```

## Support

- Issues: Create an issue in this repository
- Slack: #platform-support
- Email: platform-team@company.com