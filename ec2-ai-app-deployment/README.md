# AI Agent Platform — Production Terraform (Multi-AZ, Auto Scaling)

Deploys a Dockerized AI agent stack (LangGraph agent + FastAPI + MCP server + React frontend)
to EC2 behind an ALB, across multiple Availability Zones, with Auto Scaling and CloudWatch/SNS alerting.

## Architecture

```
Internet → ALB (multi-AZ, public subnets)
              │
              ▼
   Auto Scaling Group (private subnets, 2+ AZs)
   ┌─────────────────────────────────────┐
   │  EC2 instance                        │
   │  ├── nginx (reverse proxy, :80)       │
   │  ├── frontend (React build)             │
   │  ├── fastapi (:8000)                      │
   │  ├── ai-agent (LangGraph, :8100)             │
   │  └── mcp-server (:9000)                        │
   └─────────────────────────────────────┘
              │
              ▼
        RDS PostgreSQL (Multi-AZ, private subnets)

  ECR (4 repos)   Secrets Manager   CloudWatch + SNS (CPU alarms → scale + email alert)
```

## Modules

| Module        | Purpose                                                              |
|---------------|------------------------------------------------------------------------|
| `network`     | VPC, public/private subnets across N AZs, IGW, NAT gateway(s)             |
| `security`    | Security groups: ALB (public), app (ALB-only), RDS (app-only)               |
| `ecr`         | 4 ECR repos: `ai-agent`, `fastapi`, `mcp-server`, `frontend`                   |
| `secrets`     | Secrets Manager entry with DB creds + LLM API key                               |
| `rds`         | Multi-AZ PostgreSQL instance                                                       |
| `alb`         | Application Load Balancer + target group + HTTP/HTTPS listeners                       |
| `asg`         | Launch template + Auto Scaling Group, spread across AZs, pulls images from ECR           |
| `monitoring`  | CloudWatch CPU alarms wired to scaling policies + SNS email alerts                          |

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured
- An S3 bucket for remote state (set in `versions.tf` backend block)
- Docker images for all 4 services already built — or plan to push them to the ECR repos this creates (`terraform apply` creates the repos; push images before instances boot, or the ASG will fail to pull)
- (Optional but recommended for production) an ACM certificate for HTTPS on the ALB

## Usage

```bash
cd infra
cp envs/prod.tfvars.example envs/prod.tfvars   # fill in real values

terraform init
terraform plan  -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

After `apply`, build and push your 4 images to the ECR repos in the output, then either
wait for the next scheduled instance refresh or trigger one manually:

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ecr_registry>
docker build -t <repo_url>:latest ./ai-agent && docker push <repo_url>:latest
# repeat for fastapi, mcp-server, frontend

aws autoscaling start-instance-refresh --auto-scaling-group-name <asg_name>
```

## Notes / Production Considerations

- **Multi-AZ**: app instances and RDS both span `az_count` AZs (default 2). NAT Gateway is also one-per-AZ by default for full HA — set `single_nat_gateway = true` in the network module call to cut cost if full NAT redundancy isn't needed.
- **Stateless instances**: app instances have no local persistent state — all durable data goes to RDS. This is what makes Auto Scaling safe.
- **Instance refresh**: changing the launch template (new image tags, instance type, etc.) triggers a rolling replacement automatically.
- **Secrets**: never bake API keys into the AMI or Docker image — they're injected at boot via Secrets Manager.
- **HTTPS**: set `certificate_arn` to enable HTTPS on the ALB; without it, the ALB serves HTTP only.
- **CI/CD next step**: wire image builds/pushes and `start-instance-refresh` into a pipeline (GitHub Actions, CodePipeline, etc.) instead of doing it manually.
