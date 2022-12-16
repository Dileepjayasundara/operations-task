resource "random_password" "db_random_password" {
  length           = 20
  special          = false
}

resource "aws_ssm_parameter" "db_password_parameter" {
  name        = "/database/password"
  description = "DB password"
  type        = "SecureString"
  value       = random_password.db_random_password.result
  
  lifecycle {
    ignore_changes  = [value]
  }
}


resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = aws_subnet.rds.*.id
  tags = {
    Name       = "${var.app_name}_db_subnet_group"
  }
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  name   = "${var.app_name}-parameter-group"
  family = "postgres13"
}

# Create RDS MySQL database instance
resource "aws_db_instance" "rds_db" {
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "13.5"
  instance_class            = "db.t3.micro"
  identifier                = "${var.app_name}"
  username                  = "postgres"
  password                  = aws_ssm_parameter.db_password_parameter.value
  parameter_group_name      = aws_db_parameter_group.rds_parameter_group.name
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
  final_snapshot_identifier = "${var.app_name}-db-final-snapshot"
  skip_final_snapshot       = false
  deletion_protection       = true
  backup_retention_period   = 7
  storage_encrypted         = false
  publicly_accessible       = true
  tags = {
    Name       = "${var.app_name}_db_instance"
    Type       = "private"
  }
  lifecycle {
    ignore_changes = [password]
  }
}

# Define the security group for database
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg_${var.app_name}_db"
  description = "RDS security group to allow traffic from servers"
  vpc_id      = aws_vpc.aws-vpc.id
  tags = {
    Name       = "rds_sg_${var.app_name}"
  }
}

resource "aws_ssm_parameter" "db_host_parameter" {
  name        = "/database/host"
  description = "DB Host"
  type        = "SecureString"
  value       = aws_db_instance.rds_db.address
  lifecycle {
    ignore_changes  = [value]
  }
}

resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.service_security_group.id
}