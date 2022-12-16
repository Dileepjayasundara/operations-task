resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-cluster"
  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.app_environment
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "/ecs/${var.app_name}-app"

  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }
}

data "template_file" "env_vars" {
  template = file("env_vars.json")
}

data "template_file" "app_template" {
  template = file("./container-def/app.json.tpl")
  vars = {
    name        =   "${var.app_name}-app"
    image       = "${aws_ecr_repository.aws-ecr.repository_url}:latest"
    awslogs-group = "${aws_cloudwatch_log_group.log-group.id}"

    #account_id  = data.aws_caller_identity.current.account_id
    region      = var.aws_region
    environment = var.app_environment
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = data.template_file.app_template.rendered

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener]
}