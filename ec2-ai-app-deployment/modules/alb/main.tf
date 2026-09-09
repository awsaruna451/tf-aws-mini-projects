resource "aws_lb" "ai_app_alb" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

# ---------------------------------------------------------------------------
# Target groups — one per service, since each runs on a different host port
# on the same EC2 instances (frontend:5173, chat-be:8001, mcp-cal-server:8000)
# ---------------------------------------------------------------------------

resource "aws_lb_target_group" "chat_fe" {
  name     = "${var.name_prefix}-fe-tg"
  port     = 5173
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  deregistration_delay = 30
  tags                  = merge(var.tags, { Name = "${var.name_prefix}-fe-tg" })
}

resource "aws_lb_target_group" "chat_be" {
  name     = "${var.name_prefix}-be-tg"
  port     = 8001
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.backend_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  deregistration_delay = 30
  tags                  = merge(var.tags, { Name = "${var.name_prefix}-be-tg" })
}

resource "aws_lb_target_group" "mcp_cal_server" {
  name     = "${var.name_prefix}-mcp-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.mcp_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  deregistration_delay = 30
  tags                  = merge(var.tags, { Name = "${var.name_prefix}-mcp-tg" })
}

# ---------------------------------------------------------------------------
# HTTP listener — redirects to HTTPS if a cert is configured, otherwise
# forwards directly to the frontend (default) with path-based rules for
# the backend and mcp server
# ---------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ai_app_alb.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.chat_fe.arn
    }
  }
}

# Only needed when serving HTTP directly (no cert) — if HTTPS is configured,
# everything on :80 redirects to :443 and these rules never get evaluated.
resource "aws_lb_listener_rule" "http_chat_be" {
  count        = var.certificate_arn == null ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_be.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "http_mcp_cal_server" {
  count        = var.certificate_arn == null ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mcp_cal_server.arn
  }

  condition {
    path_pattern {
      values = ["/mcp/*"]
    }
  }
}

# ---------------------------------------------------------------------------
# HTTPS listener (only created when a certificate is provided)
# ---------------------------------------------------------------------------

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.ai_app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_fe.arn
  }
}

resource "aws_lb_listener_rule" "https_chat_be" {
  count        = var.certificate_arn != null ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_be.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "https_mcp_cal_server" {
  count        = var.certificate_arn != null ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mcp_cal_server.arn
  }

  condition {
    path_pattern {
      values = ["/mcp/*"]
    }
  }
}