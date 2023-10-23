# Replace the <> with the actual values
subscriptions = [
  {
    protocol = "email"
    endpoint = "john.doe@example.com"
  },
  {
    protocol = "email"
    endpoint = "jane.doe@example.com"
  }
]
tags = {
  "provisioner" : "Terraform"
}
resource_number    = "000"
region             = "us-east-2"
environment        = "dev"
environment_number = "000"
naming_prefix      = "demo-app"
delay_seconds      = 0
fifo_queue         = false
