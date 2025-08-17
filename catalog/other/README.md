# Other Services

Miscellaneous services that don't fit into the standard categories.

## Available Services

| Service | Description | SLA | Automation |
|---------|-------------|-----|------------|
| Email Service | Transactional email sending | 1 hour | ✅ Full |
| Scheduled Jobs | Cron-like job scheduling | 2 hours | ⚠️ Partial |
| Feature Flags | Dynamic feature toggling | 30 minutes | ✅ Full |
| Configuration Store | Centralized configuration management | 1 hour | ✅ Full |
| Service Registry | Service discovery and registration | 1 hour | ⚠️ Partial |

## Service Descriptions

### Email Service
- Transactional email delivery
- Template management
- Bounce and complaint handling
- Analytics and tracking

### Scheduled Jobs
- Cron expression scheduling
- One-time scheduled tasks
- Recurring maintenance jobs
- Job dependency management

### Feature Flags
- Progressive rollouts
- A/B testing support
- User segment targeting
- Real-time toggle updates

### Configuration Store
- Environment-specific configs
- Encrypted sensitive values
- Version history
- Change notifications

### Service Registry
- Service endpoint discovery
- Health check integration
- Load balancing support
- Metadata management

## Best Practices

1. **Documentation**: Clearly document non-standard services
2. **Ownership**: Establish clear service owners
3. **Migration Plans**: Have paths to standard categories
4. **Cost Tracking**: Monitor usage and costs
5. **Deprecation**: Plan sunset for legacy services

## Adding New Services

Services in this category should:
1. Not fit cleanly into other categories
2. Have a clear business justification
3. Include migration path to standard categories
4. Have identified platform team owner

## Owner

Platform Architecture Team
- Slack: #platform-architecture
- Email: platform-architects@company.com