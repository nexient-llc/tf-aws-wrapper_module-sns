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

output "sns_topic_arn" {
  description = "The ARN of the SNS topic, as a more obvious property (clone of id)"
  value       = module.sns.sns_topic_arn
}

output "sns_topic_id" {
  description = "The ARN of the SNS topic"
  value       = module.sns.sns_topic_id
}

output "sns_resource_name" {
  value       = module.sns.sns_resource_name
  description = "sns Resource Name"
}

output "sns_subscriptions" {
  description = "Map of subscriptions created and their attributes"
  value       = module.sns.sns_topic_subscriptions
}

output "random_int" {
  description = "Random Int postfix"
  value       = random_integer.priority.result
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = module.sqs_mock_recipient.queue_arn
}
