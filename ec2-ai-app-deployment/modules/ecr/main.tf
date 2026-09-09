resource "aws_ecr_repository" "ai_app_ecr" {
  for_each             = toset(var.repo_names)
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-${each.value}" })
}

resource "aws_ecr_lifecycle_policy" "ai_app_ecr_lifecycle" {
  for_each   = aws_ecr_repository.ai_app_ecr
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
