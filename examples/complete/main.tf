// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

resource "random_integer" "priority" {
  min = 10000
  max = 50000
}


module "sns" {
  source = "../.."

  subscriptions = concat(var.subscriptions, [{ "protocol" = "sqs", "endpoint" = module.sqs_mock_recipient.queue_arn }])
  tags          = var.tags
}
module "sqs_mock_recipient" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~>4.0.2"

  name          = local.sqs_name
  delay_seconds = var.delay_seconds
  fifo_queue    = var.fifo_queue
  tags          = var.tags
}

resource "aws_sqs_queue_policy" "my_queue_policy" {
  queue_url = module.sqs_mock_recipient.queue_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:SendMessage"
        ],
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Resource = module.sqs_mock_recipient.queue_arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : module.sns.sns_topic_arn
          }
        }
      }
    ]
    }
  )
}
