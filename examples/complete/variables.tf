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

variable "subscriptions" {
  description = "A map of subscription definitions to create"
  type        = any
  default     = {}
}

### TF Module Resource variables
variable "naming_prefix" {
  description = "Prefix for the provisioned resources."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment in which the resource should be provisioned like dev, qa, prod etc."
  type        = string
  default     = "dev"
}

variable "environment_number" {
  description = "The environment count for the respective environment. Defaults to 000. Increments in value of 1"
  default     = "000"
}

variable "region" {
  description = "AWS Region in which the infra needs to be provisioned"
  default     = "us-east-2"
}

variable "resource_number" {
  description = "The resource count for the respective resource. Defaults to 000. Increments in value of 1"
  default     = "000"
}

variable "resource_names_map" {
  description = "A map of key to resource_name that will be used by cloudposse/label/null module to generate resource names"
  type        = map(string)
  default = {
    codebuild  = "cb",
    iam_role   = "iamr",
    iam_policy = "iamp"
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to add to the resources created by the module."
}


variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes)"
  type        = number
  default     = null
}
