# Messaging Services

Message queues, event streaming, pub/sub systems, and notification services.

## Available Services

| Service | Description | SLA | Automation |
|---------|-------------|-----|------------|
| Message Queue | Standard message queuing (SQS-like) | 1 hour | ✅ Full |
| Event Stream | Kafka-based event streaming | 4 hours | ✅ Full |
| Pub/Sub Topic | Publish-subscribe messaging | 1 hour | ✅ Full |
| Notification Service | Email, SMS, push notifications | 2 hours | ⚠️ Partial |

## Messaging Patterns

### Queue Types
- **Standard Queue**: At-least-once delivery, best-effort ordering
- **FIFO Queue**: Exactly-once processing, strict ordering
- **Dead Letter Queue**: Failed message handling

### Event Streaming
- **Single Topic**: Simple event stream
- **Multi-Topic**: Complex event routing
- **Compacted Topics**: Latest state per key

### Pub/Sub Models
- **Fan-out**: One publisher, multiple subscribers
- **Fan-in**: Multiple publishers, one subscriber
- **Topic Exchange**: Content-based routing

## Configuration Options

### Performance
- **Throughput**: Messages per second limits
- **Retention**: How long to keep messages
- **Partitions**: Parallelism for streaming

### Reliability
- **Replication**: Cross-AZ or cross-region
- **Delivery Guarantees**: At-least-once, exactly-once
- **Retry Policies**: Exponential backoff settings

### Security
- **Authentication**: API keys, IAM roles
- **Encryption**: In-transit and at-rest
- **Access Control**: Topic/queue level permissions

## Best Practices

1. **Idempotency**: Design consumers to handle duplicate messages
2. **Error Handling**: Implement dead letter queues
3. **Monitoring**: Track queue depth and consumer lag
4. **Scaling**: Auto-scale consumers based on queue metrics
5. **Message Size**: Keep messages small, use references for large data

## Owner

Platform Messaging Team
- Slack: #platform-messaging
- Email: messaging-team@company.com
- On-call: PagerDuty team "platform-messaging"