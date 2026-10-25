# This is a COST-OPTIMIZED teaching topology, not a production networking baseline.
# Public subnets are used by Fargate for outbound ECR/AWS API access; tasks have
# NO internet-facing inbound security group rules. RDS lives in private subnets.
resource "aws_vpc" "main" {

  cidr_block = "10.52.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
 Name = "${local.prefix}-vpc"
}

}
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
}
resource "aws_subnet" "public" {

  count = 2
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = false
  tags = {
 Name = "${local.prefix}-public-${count.index + 1}"
}

}
resource "aws_subnet" "private" {

  count = 2
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  tags = {
 Name = "${local.prefix}-db-${count.index + 1}"
}

}
resource "aws_route_table" "public" {
 vpc_id = aws_vpc.main.id
}
resource "aws_route" "internet" {

  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id

}
resource "aws_route_table_association" "public" {

  count = 2
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public[count.index].id

}
resource "aws_security_group" "gateway" {

  name_prefix = "${local.prefix}-vpc-link-"
  description = "Outbound-only VPC link endpoint"
  vpc_id = aws_vpc.main.id
  egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
}
  lifecycle {
 create_before_destroy = true
}

}
resource "aws_security_group" "tasks" {

  name_prefix = "${local.prefix}-tasks-"
  description = "Only VPC link and internal ECS tasks may connect"
  vpc_id = aws_vpc.main.id
  egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
}
  lifecycle {
 create_before_destroy = true
}

}
resource "aws_security_group_rule" "gateway_to_tasks_employee" {

  type = "ingress"
 security_group_id = aws_security_group.tasks.id
  source_security_group_id = aws_security_group.gateway.id
  protocol = "tcp"
 from_port = 8081
 to_port = 8081
  description = "HTTP API Gateway VPC link to employee"

}
resource "aws_security_group_rule" "gateway_to_tasks_leave" {

  type = "ingress"
 security_group_id = aws_security_group.tasks.id
  source_security_group_id = aws_security_group.gateway.id
  protocol = "tcp"
 from_port = 8082
 to_port = 8082
  description = "HTTP API Gateway VPC link to leave"

}
resource "aws_security_group_rule" "leave_to_employee" {

  type = "ingress"
 security_group_id = aws_security_group.tasks.id
  source_security_group_id = aws_security_group.tasks.id
  protocol = "tcp"
 from_port = 8081
 to_port = 8081
  description = "Internal leave-service to employee-service REST requests"

}
resource "aws_security_group" "database" {

  name_prefix = "${local.prefix}-db-"
  description = "Allow MySQL only from ECS tasks"
  vpc_id = aws_vpc.main.id
  ingress {
 from_port = 3306
 to_port = 3306
 protocol = "tcp"
 security_groups = [aws_security_group.tasks.id]
}
  lifecycle {
 create_before_destroy = true
}

}
resource "aws_db_subnet_group" "main" {

  name = "${local.prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

}
