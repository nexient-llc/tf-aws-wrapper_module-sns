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
  value       = module.sns_topic.topic_arn
}

output "sns_topic_id" {
  description = "The ARN of the SNS topic"
  value       = module.sns_topic.topic_id
}

output "sns_resource_name" {
  value       = module.resource_names["sns"].standard
  description = "sns Resource Name"
}


output "sns_created_by" {
  description = "The resource that created this topic."
  value       = var.created_by
}

output "sns_topic_subscriptions" {
  description = "Map of subscriptions created and their attributes"
  value       = module.sns_topic.subscriptions
}

output "sns_topic_name" {
  description = "The name of the topic."
  value       = module.sns_topic.topic_name
}
