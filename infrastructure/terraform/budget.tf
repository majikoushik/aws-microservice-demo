# Cost alerts are NOT spending limits. An AWS Paid account can incur charges.
resource "aws_budgets_budget" "monthly" {

  name="${local.prefix}-monthly-warning"
 budget_type="COST"
  limit_amount=var.monthly_budget_usd
limit_unit="USD"
  time_unit="MONTHLY"
  notification {

    comparison_operator="GREATER_THAN"
    threshold=60
    threshold_type="PERCENTAGE"
    notification_type="ACTUAL"
    subscriber_email_addresses=[var.budget_email]

}
  notification {

    comparison_operator="GREATER_THAN"
    threshold=90
    threshold_type="PERCENTAGE"
    notification_type="ACTUAL"
    subscriber_email_addresses=[var.budget_email]

}

}
