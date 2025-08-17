# Compute Services

Container orchestration, virtual machines, serverless functions, and batch processing services.

## Available Services

| Service | Description | SLA | Automation |
|---------|-------------|-----|------------|
| Container Application | Deploy containerized applications to Kubernetes | 2 hours | ✅ Full |
| Virtual Machine | Provision traditional VMs with custom configurations | 4 hours | ⚠️ Partial |
| Serverless Function | Deploy event-driven functions | 30 minutes | ✅ Full |
| Batch Job | Schedule and run batch processing workloads | 1 hour | ✅ Full |

## Service Patterns

### Container Applications
- **Standard**: Pre-configured with best practices
- **Custom**: Full control over configuration
- **Stateful**: With persistent storage attached

### Virtual Machines
- **Linux**: Ubuntu, RHEL, Amazon Linux
- **Windows**: Windows Server editions
- **Specialized**: GPU-enabled, high-memory, compute-optimized

### Serverless Functions
- **HTTP Triggered**: REST API endpoints
- **Event Triggered**: Message queue, S3, schedule
- **Workflows**: Step functions and orchestrations

## Best Practices

1. **Right-sizing**: Start small and scale based on metrics
2. **Environment Parity**: Use same configurations across environments
3. **Resource Tagging**: Always include cost center and project tags
4. **Health Checks**: Define liveness and readiness probes
5. **Auto-scaling**: Configure based on actual usage patterns

## Migration Guides

- [VM to Container Migration](docs/vm-to-container.md)
- [Monolith to Microservices](docs/monolith-decomposition.md)
- [Serverless Adoption](docs/serverless-patterns.md)

## Owner

Platform Compute Team
- Slack: #platform-compute
- Email: compute-team@company.com
- On-call: PagerDuty team "platform-compute"