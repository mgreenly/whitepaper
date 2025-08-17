# Fix: Use static Terraform labels; pass dynamic values via attributes

Problem
- In catalog.md, several Terraform examples build resource/module labels from user input, e.g.:
  - resource "aws_ssm_parameter" "{{fields.secretName}}" { ... }
  - module "rds_{{fields.instanceName}}" { ... }
  - module "eks_app_{{fields.appName}}" { ... }
- Terraform labels (resource names and module names) must be static identifiers (letters, digits, underscores). Interpolations and characters like - or / are not allowed. Examples in catalog.md can generate invalid labels such as app-name/secrets, which will cause terraform plan/apply to fail.

Goal
- Make all Terraform labels static and valid, while keeping dynamic behavior through attribute values.

General Rule
- Do not template inside Terraform labels. Only template in attribute values.
- Use short, static labels like secret, rds, eks_app, etc.
- If outputs reference a label, update them to the new static label.

Concrete changes to catalog.md

1) AWS Parameter Store example
Before
```yaml
resource "aws_ssm_parameter" "{{fields.secretName}}" {
  name  = "/{{fields.secretName}}"
  type  = "SecureString"
  value = jsonencode({{json(fields.secrets)}})
}
...
outputs:
  - secretArn: "aws_ssm_parameter.{{fields.secretName}}.arn"
```
After
```yaml
resource "aws_ssm_parameter" "secret" {
  name  = "/{{fields.secretName}}"
  type  = "SecureString"
  value = jsonencode({{json(fields.secrets)}})
}
...
outputs:
  - secretArn: "aws_ssm_parameter.secret.arn"
```

2) PostgreSQL (RDS) module example
Before
```yaml
module "rds_{{fields.instanceName}}" {
  source            = "terraform-aws-modules/rds/aws"
  identifier        = "{{fields.instanceName}}"
  engine            = "postgres"
  instance_class    = "{{fields.instanceClass}}"
  allocated_storage = {{fields.storageSize}}
}
...
outputs:
  - connectionString: "module.rds_{{fields.instanceName}}.connection_string"
  - host: "module.rds_{{fields.instanceName}}.endpoint"
  - port: "module.rds_{{fields.instanceName}}.port"
```
After
```yaml
module "rds" {
  source            = "terraform-aws-modules/rds/aws"
  identifier        = "{{fields.instanceName}}"
  engine            = "postgres"
  instance_class    = "{{fields.instanceClass}}"
  allocated_storage = {{fields.storageSize}}
}
...
outputs:
  - connectionString: "module.rds.connection_string"
  - host: "module.rds.endpoint"
  - port: "module.rds.port"
```

3) EKS container app module example
Before
```yaml
module "eks_app_{{fields.appName}}" {
  source   = "./modules/eks-app"
  name     = "{{fields.appName}}"
  image    = "{{fields.containerImage}}"
  replicas = {{fields.replicas}}
}
```
After
```yaml
module "eks_app" {
  source   = "./modules/eks-app"
  name     = "{{fields.appName}}"
  image    = "{{fields.containerImage}}"
  replicas = {{fields.replicas}}
}
```

Checklist
- Replace any resource/module label that contains {{ ... }} with a static, valid identifier.
- Ensure any outputs referencing those labels are updated accordingly.
- Keep all dynamic values in attribute values (e.g., name, identifier, tags, etc.).

Rationale
- Prevents invalid identifier errors and keeps Terraform plans stable and reproducible.
- Aligns with Terraform syntax: labels are compile-time constants; runtime values belong in attributes.
