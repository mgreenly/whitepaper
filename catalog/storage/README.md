# Storage Services

Object storage, file systems, block storage, and backup solutions.

## Available Services

| Service | Description | SLA | Automation |
|---------|-------------|-----|------------|
| Object Storage | S3-compatible object storage | 1 hour | ✅ Full |
| File System | Managed NFS/SMB file shares | 2 hours | ✅ Full |
| Block Storage | EBS volumes for compute instances | 30 minutes | ✅ Full |
| Backup Service | Automated backup and recovery | 2 hours | ⚠️ Partial |
| Archive Storage | Long-term cold storage | 4 hours | ✅ Full |

## Storage Classes

### Object Storage
- **Standard**: Frequently accessed data
- **Infrequent Access**: Lower cost for occasional access
- **Archive**: Lowest cost for rare access
- **Intelligent Tiering**: Automatic tier optimization

### File Systems
- **General Purpose**: Balanced performance
- **Max I/O**: Higher aggregate throughput
- **Provisioned**: Guaranteed performance levels

### Block Storage
- **GP3**: General purpose SSD
- **IO2**: High-performance SSD
- **ST1**: Throughput optimized HDD
- **SC1**: Cold HDD storage

## Configuration Options

### Performance
- **IOPS**: Input/output operations per second
- **Throughput**: MB/s transfer rate
- **Latency**: Sub-millisecond to seconds

### Data Protection
- **Replication**: Cross-AZ or cross-region
- **Versioning**: Keep multiple object versions
- **Lifecycle Policies**: Automatic archival/deletion
- **Encryption**: AES-256 at rest

### Access Control
- **IAM Policies**: Role-based access
- **Bucket Policies**: Resource-based permissions
- **ACLs**: Object-level permissions
- **Pre-signed URLs**: Temporary access

## Best Practices

1. **Lifecycle Management**: Automate data tiering and expiration
2. **Cost Optimization**: Use appropriate storage class
3. **Performance**: Enable transfer acceleration for large files
4. **Security**: Enable default encryption and versioning
5. **Monitoring**: Track storage metrics and access patterns

## Owner

Platform Storage Team
- Slack: #platform-storage
- Email: storage-team@company.com
- On-call: PagerDuty team "platform-storage"