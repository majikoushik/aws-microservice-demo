resource "aws_lb" "internal" {
  name = substr("${local.prefix}-internal-alb", 0, 32)
  internal = true; load_balancer_type = "application"; security_groups = [aws_security_group.alb.id]
  subnets = aws_subnet.private[*].id
  enable_deletion_protection = var.deletion_protection
}
resource "aws_lb_target_group" "employee" {
  name = substr("${local.prefix}-employee-tg", 0, 32)
  port = 8081; protocol = "HTTP"; target_type = "ip"; vpc_id = aws_vpc.this.id
  health_check { path = "/actuator/health"; matcher = "200"; healthy_threshold = 2; unhealthy_threshold = 3 }
}
resource "aws_lb_target_group" "leave" {
  name = substr("${local.prefix}-leave-tg", 0, 32)
  port = 8082; protocol = "HTTP"; target_type = "ip"; vpc_id = aws_vpc.this.id
  health_check { path = "/actuator/health"; matcher = "200"; healthy_threshold = 2; unhealthy_threshold = 3 }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn; port = 80; protocol = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.employee.arn }
}
resource "aws_lb_listener_rule" "leave" {
  listener_arn = aws_lb_listener.http.arn; priority = 10
  action { type = "forward"; target_group_arn = aws_lb_target_group.leave.arn }
  condition { path_pattern { values = ["/api/leaves", "/api/leaves/*", "/api/attendance", "/api/attendance/*"] } }
}
