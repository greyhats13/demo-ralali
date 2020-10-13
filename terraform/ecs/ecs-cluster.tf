resource "aws_iam_role" "demo-role" {
  name = "demo-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "demo-profile-attachment" {
  role       = aws_iam_role.demo-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "demo-profile" {
  name = "demo-profile"
  role = aws_iam_role.demo-role.name
}

resource "aws_security_group" "launch-templates-sg" {
  name        = "launch-template-sg"
  description = "Security Group for Launch Template"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "launch-template-security-group"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "deployer-key-autoscaling"
  public_key = tls_private_key.this.public_key_openssh
}

data "template_file" "user_data" {
  template = file("ecs/user_data.yml")
  vars = {
    cluster_name = "ecs-demo"
  }
}
resource "aws_launch_template" "ecs_instance_template" {
  name = "rll-instance-template-demo"
  iam_instance_profile {
    arn = aws_iam_instance_profile.demo-profile.arn
  }
  image_id                             = "ami-05c621ca32de56e7a" # ecs_optimized = ami-04f3eb384ebc387b3
  instance_type                        = "t3.large"
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids               = aws_security_group.launch-templates-sg.*.id
  key_name                             = aws_key_pair.this.key_name
  user_data                            = base64encode(data.template_file.user_data.rendered)
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "rll-instance-template-demo"
    }
  }
}

resource "aws_autoscaling_group" "autoscaling-demo" {
  name                      = "autoscaling-instance-demo"
  min_size                  = 1
  desired_capacity          = 3
  max_size                  = 5
  health_check_type         = "EC2"
  health_check_grace_period = 60

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        version              = "$Latest"
        launch_template_name = aws_launch_template.ecs_instance_template.name
      }
      # dynamic "override" {
      #   for_each = { type = "t3.large" }
      #   content {
      #     instance_type = override.value["type"]
      #   }
      # }
      override {
        instance_type     = "t3.large"
        weighted_capacity = "3"
      }

    }

    instances_distribution {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_max_price                           = ""
    }
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  vpc_zone_identifier   = var.vpc_zone_identifier
  protect_from_scale_in = true
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "capacity-provider-demo"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.autoscaling-demo.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster" "ecs-demo" {
  name               = "ecs-demo"
  capacity_providers = aws_ecs_capacity_provider.capacity_provider.*.name
}

resource "aws_security_group" "alb-demo-sg" {
  name        = "alb-demo-sg"
  description = "Security Group for application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

resource "aws_lb" "demo-alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-demo-sg.id]
  subnets            = var.public_subnet

  tags = {
    Name = "demo-alb"
  }
}

resource "aws_lb_target_group" "demo-tg" {
  name        = "demo-tg"
  vpc_id      = var.vpc_id
  target_type = "ip"
  port        = "80"
  protocol    = "HTTP"
  depends_on  = [aws_lb.demo-alb]
}

resource "aws_lb_listener" "demo-http-listener" {
  load_balancer_arn = aws_lb.demo-alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo-tg.arn
  }
}

# resource "aws_lb_listener" "service_lb_listener_https" {
#   load_balancer_arn = aws_lb.service_lb.arn

#   port            = 443
#   protocol        = "HTTPS"
#   certificate_arn = var.acm_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.service_tg.arn
#   }

# }
resource "aws_iam_role" "task-definition-role-demo" {
  name               = "task-definition-role-demo"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "Task Definition Role"
  }
}

resource "aws_iam_role_policy_attachment" "iam-role-policy-attachment-task-definition-demo" {
  role       = aws_iam_role.task-definition-role-demo.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task-execution-role-demo" {
  name               = "task-execution-role-demo"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "Task Execution Role"
  }
}

resource "aws_iam_role_policy_attachment" "iam-role-policy-attachment-task-execution-demo" {
  role       = aws_iam_role.task-execution-role-demo.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "task-definition-demo" {
  family                = "task-definition-family-demo"
  task_role_arn         = aws_iam_role.task-definition-role-demo.arn
  execution_role_arn    = aws_iam_role.task-execution-role-demo.arn
  network_mode          = "awsvpc"
  container_definitions = file("task-definitions/service.json")

  volume {
    name      = "demo-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-southeast-2a, ap-southeast-2b, ap-southeast-2c]"
  }
}

//Service
resource "aws_security_group" "ecs-service-demo-sg" {
  name        = "ecs-service-demo-sg"
  description = "Security Group for ECS Services"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-service-demo-sg"
  }
}

resource "aws_service_discovery_private_dns_namespace" "demo-service-discovery-private-dns" {
  name        = "demo.ralali.local"
  description = "Sample Service Discovery Private DNS"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "service-discovery-demo" {

  name         = "service-discovery-demo"
  namespace_id = aws_service_discovery_private_dns_namespace.demo-service-discovery-private-dns.id

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.demo-service-discovery-private-dns.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

}

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs-service-role-policy" {
  name = "ecs-service-role-policy"
  role = aws_iam_role.ecs-service-role.id

  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_ecs_service" "ecs-service-demo" {
  name            = "ecs-service-demo"
  cluster         = aws_ecs_cluster.ecs-demo.id
  task_definition = aws_ecs_task_definition.task-definition-demo.arn
  desired_count   = 3

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.demo-tg.arn
    container_name   = "go-demo-1"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-southeast-2a, ap-southeast-2b, ap-southeast-2c]"
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service-discovery-demo.arn
    container_name = "go-demo-1"
  }

  network_configuration {
    subnets         = var.vpc_zone_identifier
    security_groups = [aws_security_group.ecs-service-demo-sg.id]
  }
}

resource "aws_lb_target_group" "service-tg" {
  name   = "service-tg"
  vpc_id = var.vpc_id

  target_type          = "ip"
  port                 = tostring(80)
  protocol             = "HTTP"
  deregistration_delay = 15

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "listener-rule-demo" {
  depends_on = [aws_lb_target_group.service-tg]

  listener_arn = aws_lb_listener.demo-http-listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service-tg.arn
  }

  condition {
    http_request_method {
      values = ["GET", "HEAD"]
    }
  }

  ############## Uncomment, if use path_pattern condition
  # dynamic "condition" {
  #   for_each = ["/static/*"] == "" ? [] : ["true"]
  #   content {
  #     path_pattern {
  #       values = ["/static/*"]
  #     }
  #   }
  # }
}

resource "aws_iam_role" "ecs-autoscaling-role" {
  name = "ecs-autoscaling-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    env = "demo"
  }
}

resource "aws_iam_role_policy_attachment" "demo-role-attach" {
  role       = aws_iam_role.ecs-autoscaling-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_appautoscaling_target" "demo-service-target" {
  resource_id        = "service/ecs-demo/ecs-service-demo"
  max_capacity       = 6
  min_capacity       = 1
  role_arn           = aws_iam_role.ecs-autoscaling-role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "demo-task-autoscale-policy" {
  name               = "demo-task-autoscale-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.demo-service-target.resource_id
  scalable_dimension = aws_appautoscaling_target.demo-service-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.demo-service-target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = "80"
    scale_in_cooldown  = 300
    scale_out_cooldown = 300

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

