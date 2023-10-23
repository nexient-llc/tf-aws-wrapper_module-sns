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

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 5.3.0"

  name = module.resource_names["sns"].standard

  use_name_prefix                 = var.use_name_prefix
  application_feedback            = var.application_feedback
  content_based_deduplication     = var.content_based_deduplication
  delivery_policy                 = var.delivery_policy
  display_name                    = var.display_name
  fifo_topic                      = var.fifo_topic
  firehose_feedback               = var.firehose_feedback
  http_feedback                   = var.http_feedback
  kms_master_key_id               = var.kms_master_key_id
  lambda_feedback                 = var.lambda_feedback
  topic_policy                    = var.topic_policy
  sqs_feedback                    = var.sqs_feedback
  signature_version               = var.signature_version
  tracing_config                  = var.tracing_config
  create_topic_policy             = var.create_topic_policy
  source_topic_policy_documents   = var.source_topic_policy_documents
  override_topic_policy_documents = var.override_topic_policy_documents
  enable_default_topic_policy     = var.enable_default_topic_policy
  topic_policy_statements         = var.topic_policy_statements
  create_subscription             = var.create_subscription
  subscriptions                   = local.subscriptions
  data_protection_policy          = var.data_protection_policy

  tags = merge(local.tags, { resource_name = module.resource_names["sns"].standard })
}

module "resource_names" {
  source = "git::https://github.com/nexient-llc/tf-module-resource_name.git?ref=0.1.0"

  for_each = var.resource_names_map

  logical_product_name = var.naming_prefix
  region               = join("", split("-", var.region))
  class_env            = var.environment
  cloud_resource_type  = each.value
  instance_env         = var.environment_number
  instance_resource    = var.resource_number
}
