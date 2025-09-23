# Web Tier Security Group
resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Security group for web tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-web-sg"
    Component = "security"
    Tier      = "web"
  })
}

# Web Tier Rules
resource "aws_security_group_rule" "web_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "HTTP traffic from allowed CIDRs"
}

resource "aws_security_group_rule" "web_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "HTTPS traffic from allowed CIDRs"
}

resource "aws_security_group_rule" "web_ssh_ingress" {
  count             = var.enable_ssh_access ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.web.id
  description       = "SSH access from VPC"
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "All outbound traffic"
}

# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-app-sg"
    Component = "security"
    Tier      = "application"
  })
}

# Application Rules - Only from web tier
resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.application.id
  description              = "Application traffic from web tier"
}

resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application.id
  description       = "All outbound traffic"
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for database tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-db-sg"
    Component = "security"
    Tier      = "database"
  })
}

# Database Rules - Only from application tier
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database.id
  description              = "MySQL traffic from application tier"
}

resource "aws_security_group_rule" "db_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "All outbound traffic"
}