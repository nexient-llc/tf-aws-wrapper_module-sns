locals {
  sqs_name = "${var.naming_prefix}-sqs-${random_integer.priority.result}"
}
