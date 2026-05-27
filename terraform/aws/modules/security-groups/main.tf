# Flujo de tráfico: ALB (80/443) -> web app (3000, 5000) -> MySQL (3306).
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-sg-${var.environment}"
      Type = "load-balancer"
    }
  )
}

resource "aws_security_group" "web_app" {
  name        = "${var.project_name}-web-app-sg-${var.environment}"
  description = "Security group for web application"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Frontend from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "HTTP app from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-web-app-sg-${var.environment}"
      Type = "application"
    }
  )
}

resource "aws_security_group" "mysql" {
  name        = "${var.project_name}-mysql-sg-${var.environment}"
  description = "Security group for MySQL database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from web app tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-mysql-sg-${var.environment}"
      Type = "database"
    }
  )
}

# Regla self-referential: Terraform no permite [aws_security_group.mysql.id] dentro del mismo SG.
resource "aws_security_group_rule" "mysql_self_ingress" {
  type              = "ingress"
  description       = "MySQL from same security group (RDS, rotation Lambda, etc.)"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.mysql.id
  self              = true
}
