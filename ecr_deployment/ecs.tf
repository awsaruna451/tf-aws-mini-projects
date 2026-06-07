resource "aws_ecs_cluster" "main" {
  name = "java-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-ex1-repo"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "my-ex1-repo"
      image = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/my-ex1-repo:latest"

      portMappings = [
        {
          containerPort = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

   network_configuration {
    subnets         = [aws_subnet.public[0].id, aws_subnet.public[1].id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "my-ex1-repo"
    container_port   = 8080
  }
}