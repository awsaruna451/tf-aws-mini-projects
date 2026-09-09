locals {
  name_prefix = "${var.app_name}-${var.environment}"
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Network (multi-AZ VPC)
# ---------------------------------------------------------------------------
module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = local.name_prefix
  az_count    = var.az_count
  tags        = local.common_tags
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
module "security" {
  source            = "../../modules/security"
  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidr  = var.ssh_allowed_cidr
  tags              = local.common_tags
}

# ---------------------------------------------------------------------------
# ECR repositories — one per service image
# ---------------------------------------------------------------------------
module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = local.name_prefix
  repo_names  = ["ai-agent", "mcp-server", "frontend"]
  tags        = local.common_tags
}

# ---------------------------------------------------------------------------
# Secrets (DB creds + LLM API key, pulled by instances on boot)
# ---------------------------------------------------------------------------
module "secrets" {
  source      = "../../modules/secrets"
  name_prefix = local.name_prefix
  tags        = local.common_tags

  secret_values = {
    OPENAI_API_KEY       = var.openai_api_key
    GOOGLE_API_KEY        = var.google_api_key
    OPENWEATHER_API_KEY   = var.openweather_api_key
    ALPHAVANTAGE_API_KEY  = var.alphavantage_api_key
  #  POSTGRES_HOST         = module.rds.endpoint
   # POSTGRES_PORT         = tostring(module.rds.port)
   # POSTGRES_DB           = module.rds.db_name
    POSTGRES_USER         = "agent"
  #  POSTGRES_PASSWORD     = var.db_password
  }
}

# ---------------------------------------------------------------------------
# RDS Postgres (Multi-AZ)
# ---------------------------------------------------------------------------

/*
module "rds" {
  source              = "../../modules/rds"
  name_prefix         = local.name_prefix
  private_subnet_ids  = module.vpc.private_subnet_ids
  rds_sg_id           = module.security.rds_sg_id
  db_password         = var.db_password
  instance_class      = var.rds_instance_class
  multi_az            = var.rds_multi_az
  tags                = local.common_tags
}
*/
# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------
module "alb" {
  source             = "../../modules/alb"
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  certificate_arn    = var.certificate_arn
  tags               = local.common_tags
}

# ---------------------------------------------------------------------------
# IAM role for EC2 instances (Secrets Manager read, ECR pull, SSM access)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = module.secrets.secret_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------------------------------------------------------
# ECR registry URL (shared prefix, derived from any one repo URL)
# ---------------------------------------------------------------------------
/*locals {
  ecr_registry = split("/", module.ecr.repository_urls["ai-agent"])[0]
}
*/
# ---------------------------------------------------------------------------
# Minimal instance bootstrap — installs Docker + Docker Compose only.
# GitHub Actions deploys the actual containers post-boot via SSM Send-Command
# after each image push (no app logic baked into user_data anymore).
# ---------------------------------------------------------------------------
/*locals {
  bootstrap_user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    apt_retry() {
      for i in 1 2 3 4 5; do
        if "$@"; then return 0; fi
        echo "Command failed, retrying in 10s ($i/5): $*"
        sleep 10
      done
      return 1
    }

    apt_retry apt-get update -y
    apt_retry apt-get install -y ca-certificates curl unzip jq gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt_retry apt-get update -y
    apt_retry apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker
    usermod -aG docker ssm-user || true
    mkdir -p /opt/app

    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
  EOT
}*/

locals {
  ecr_registry = split("/", module.ecr.repository_urls["ai-agent"])[0]
  secret_name  = "ai-agent-platform-dev-secrets"

  bootstrap_user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    apt_retry() {
      for i in 1 2 3 4 5; do
        if "$@"; then return 0; fi
        echo "Command failed, retrying in 10s ($i/5): $*"
        sleep 10
      done
      return 1
    }

    apt_retry apt-get update -y
    apt_retry apt-get install -y ca-certificates curl unzip jq gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt_retry apt-get update -y
    apt_retry apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker
    usermod -aG docker ssm-user || true
    mkdir -p /opt/app

    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # =====================================================
    # Self-healing deploy: pulls and runs the current
    # :latest image for all three services. This is what
    # makes a freshly-launched instance (from instance
    # refresh, scale-out, or a health-check replacement)
    # immediately correct, without waiting for the next
    # `git push` to happen to trigger a fresh SSM deploy.
    #
    # This intentionally mirrors deploy.sh in
    # .github/workflows/_build-push-ecr.yml exactly, so the
    # two paths (CI-triggered fast redeploy, and boot-time
    # self-heal) never drift apart in behavior.
    # =====================================================
    ECR_REGISTRY="${local.ecr_registry}"
    SECRET_NAME="${local.secret_name}"

    aws ecr get-login-password --region ${var.aws_region} | \
      docker login --username AWS --password-stdin "$ECR_REGISTRY"

    docker network create app-net 2>/dev/null || true

    deploy_container() {
      local repo="$1"
      local name="$2"
      local host_port="$3"
      local container_port="$4"
      local use_secret="$5"

      local image="$ECR_REGISTRY/$repo:latest"
      docker pull "$image"
      docker stop "$name" 2>/dev/null || true
      docker rm "$name" 2>/dev/null || true

      local env_flags=""
      if [ "$use_secret" = "yes" ]; then
        set +x
        SECRET_JSON=$(aws secretsmanager get-secret-value \
          --secret-id "$SECRET_NAME" --region ${var.aws_region} \
          --query SecretString --output text)
        env_flags=$(echo "$SECRET_JSON" | jq -r 'to_entries | map("-e " + .key + "=" + (.value|@sh)) | join(" ")')
        unset SECRET_JSON
        set -x
      fi

      eval docker run -d --name "$name" --network app-net --restart unless-stopped \
        -p "$host_port:$container_port" $env_flags "$image"
    }

    deploy_container "frontend"   "chat-fe"        5173 80   "no"  || echo "WARNING: chat-fe deploy failed, continuing"
    deploy_container "ai-agent"   "chat-be"        8001 8000 "yes" || echo "WARNING: chat-be deploy failed, continuing"
    deploy_container "mcp-server" "mcp-cal-server" 8000 8000 "yes" || echo "WARNING: mcp-cal-server deploy failed, continuing"
  EOT
}



# ---------------------------------------------------------------------------
# Auto Scaling Group (multi-AZ, pulls Docker images from ECR on boot)
# ---------------------------------------------------------------------------
module "asg" {
  source                 = "../../modules/asg"
  name_prefix            = local.name_prefix
  instance_type          = var.instance_type
  private_subnet_ids     = module.vpc.private_subnet_ids
  app_sg_id              = module.security.app_sg_id
  instance_profile_name  = aws_iam_instance_profile.ec2_profile.name
  key_pair_name          = var.key_pair_name
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  tags                   = local.common_tags
  user_data              = local.bootstrap_user_data
  target_group_arns      =  module.alb.target_group_arns 
}

# ---------------------------------------------------------------------------
# Monitoring — CloudWatch alarms + SNS alerts, wired to ASG scaling policies
# ---------------------------------------------------------------------------
module "monitoring" {
  source                = "../../modules/monitoring"
  name_prefix           = local.name_prefix
  asg_name              = module.asg.asg_name
  scale_out_policy_arn  = module.asg.scale_out_policy_arn
  scale_in_policy_arn   = module.asg.scale_in_policy_arn
  cpu_high_threshold    = var.cpu_high_threshold
  cpu_low_threshold     = var.cpu_low_threshold
  alert_email           = var.alert_email
  min_healthy_instances = var.asg_min_size
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC — lets each repo's workflow push to its ECR repo and
# trigger a deploy via SSM Send-Command, with no long-lived AWS keys stored
# in GitHub.
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "${local.name_prefix}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Immutable subject format (GitHub, as of July 2026): repo:OWNER@OWNER_ID/REPO@REPO_ID:*
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}@83629626/*"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${local.name_prefix}-github-ecr-push"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository"
        ]
        Resource = [for url in values(module.ecr.repository_urls) : "arn:aws:ecr:${var.aws_region}:*:repository/${split("/", url)[1]}"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${local.name_prefix}-github-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
      },
      {
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = "arn:aws:ec2:${var.aws_region}:*:instance/*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Environment" = var.environment
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "github_actions_ec2_lookup" {
  name = "${local.name_prefix}-github-ec2-lookup"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}