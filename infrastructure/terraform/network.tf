resource "aws_vpc" "this" { cidr_block = var.vpc_cidr; enable_dns_support = true; enable_dns_hostnames = true; tags = { Name = "${local.prefix}-vpc" } }
resource "aws_internet_gateway" "this" { vpc_id = aws_vpc.this.id; tags = { Name = "${local.prefix}-igw" } }
resource "aws_subnet" "public" {
  count = 2; vpc_id = aws_vpc.this.id; availability_zone = local.azs[count.index]
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${local.prefix}-public-${count.index + 1}" }
}
resource "aws_subnet" "private" {
  count = 2; vpc_id = aws_vpc.this.id; availability_zone = local.azs[count.index]
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 8)
  tags = { Name = "${local.prefix}-private-${count.index + 1}" }
}
resource "aws_route_table" "public" { vpc_id = aws_vpc.this.id; tags = { Name = "${local.prefix}-public-rt" } }
resource "aws_route" "public_default" { route_table_id = aws_route_table.public.id; destination_cidr_block = "0.0.0.0/0"; gateway_id = aws_internet_gateway.this.id }
resource "aws_route_table_association" "public" { count = 2; subnet_id = aws_subnet.public[count.index].id; route_table_id = aws_route_table.public.id }
resource "aws_eip" "nat" { count = var.private_ecs_with_nat ? 1 : 0; domain = "vpc"; tags = { Name = "${local.prefix}-nat-eip" } }
resource "aws_nat_gateway" "nat" { count = var.private_ecs_with_nat ? 1 : 0; allocation_id = aws_eip.nat[0].id; subnet_id = aws_subnet.public[0].id; depends_on = [aws_internet_gateway.this]; tags = { Name = "${local.prefix}-nat" } }
resource "aws_route_table" "private" { vpc_id = aws_vpc.this.id; tags = { Name = "${local.prefix}-private-rt" } }
resource "aws_route" "private_default" { count = var.private_ecs_with_nat ? 1 : 0; route_table_id = aws_route_table.private.id; destination_cidr_block = "0.0.0.0/0"; nat_gateway_id = aws_nat_gateway.nat[0].id }
resource "aws_route_table_association" "private" { count = 2; subnet_id = aws_subnet.private[count.index].id; route_table_id = aws_route_table.private.id }
resource "aws_security_group" "vpclink" { name = "${local.prefix}-vpclink-sg"; vpc_id = aws_vpc.this.id; description = "API Gateway VPC link"; egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] } }
resource "aws_security_group" "alb" {
  name = "${local.prefix}-alb-sg"; vpc_id = aws_vpc.this.id; description = "Internal ALB"
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; security_groups = [aws_security_group.vpclink.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "ecs" {
  name = "${local.prefix}-ecs-sg"; vpc_id = aws_vpc.this.id; description = "Employee and Leave ECS tasks"
  ingress { from_port = 8081; to_port = 8082; protocol = "tcp"; security_groups = [aws_security_group.alb.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "rds" {
  name = "${local.prefix}-rds-sg"; vpc_id = aws_vpc.this.id; description = "MySQL from ECS only"
  ingress { from_port = 3306; to_port = 3306; protocol = "tcp"; security_groups = [aws_security_group.ecs.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_ecs" {
  security_group_id = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol = "tcp"; from_port = 80; to_port = 80
}
