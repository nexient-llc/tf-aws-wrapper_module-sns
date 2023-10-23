package test

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	base            = "../../examples/"
	testVarFileName = "/test.tfvars"
)

var standardTags = map[string]string{
	"provisioner": "Terraform",
}

func TestWrapperSNS(t *testing.T) {
	t.Parallel()
	stage := test_structure.RunTestStage

	files, err := os.ReadDir(base)
	assert.NoError(t, err)
	basePath, _ := filepath.Abs(base)
	for _, file := range files {
		dir := filepath.Join(basePath, file.Name()) //base + file.Name()
		if file.IsDir() {
			defer stage(t, "teardown_wrapper_sns", func() { tearDownWrapperSNS(t, dir) })
			stage(t, "setup_test_wrapper_sns", func() { setupTestWrapperSNS(t, dir) })
			stage(t, "test_sns_wrapper", func() { testSNSWrapper(t, dir) })
		}
	}
}

// We use this interface to test the function using a mocked service.
type SNSPublishAPI interface {
	Publish(ctx context.Context,
		params *sns.PublishInput,
		optFns ...func(*sns.Options)) (*sns.PublishOutput, error)
}

func PublishMessage(c context.Context, api SNSPublishAPI, input *sns.PublishInput) (*sns.PublishOutput, error) {
	return api.Publish(c, input)
}

type SQSReceiveMessageAPI interface {
	GetQueueUrl(ctx context.Context,
		params *sqs.GetQueueUrlInput,
		optFns ...func(*sqs.Options)) (*sqs.GetQueueUrlOutput, error)

	ReceiveMessage(ctx context.Context,
		params *sqs.ReceiveMessageInput,
		optFns ...func(*sqs.Options)) (*sqs.ReceiveMessageOutput, error)
}

func GetQueueURL(c context.Context, api SQSReceiveMessageAPI, input *sqs.GetQueueUrlInput) (*sqs.GetQueueUrlOutput, error) {
	return api.GetQueueUrl(c, input)
}

func GetMessages(c context.Context, api SQSReceiveMessageAPI, input *sqs.ReceiveMessageInput) (*sqs.ReceiveMessageOutput, error) {
	return api.ReceiveMessage(c, input)
}

func setupTestWrapperSNS(t *testing.T, dir string) {

	terraformOptions := &terraform.Options{
		TerraformDir: dir,
		VarFiles:     []string{dir + testVarFileName},
		NoColor:      true,
		Logger:       logger.Discard,
	}

	test_structure.SaveTerraformOptions(t, dir, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	expectedName := terraform.Output(t, terraformOptions, "sns_resource_name")
	assert.NotEmpty(t, expectedName, "Expected Name is empty")
	standardTags["resource_name"] = expectedName

}
func testSNSWrapper(t *testing.T, dir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, dir)
	terraformOptions.Logger = logger.Discard

	expectedPatternSNSTopicARN := "^arn:aws:sns:[a-z0-9-]+:[0-9]+:[a-zA-Z0-9-]+$"

	actualSnsTopicId := terraform.Output(t, terraformOptions, "sns_topic_id")
	assert.NotEmpty(t, actualSnsTopicId, "SNS Topic ID is empty")

	actualSnsTopicARN := terraform.Output(t, terraformOptions, "sns_topic_arn")
	assert.NotEmpty(t, actualSnsTopicARN, "SNS Topic ARN is empty")

	assert.Regexp(t, expectedPatternSNSTopicARN, actualSnsTopicARN, "SNS topic ARN does not match expected pattern")
	actualSnsSubscriptions := terraform.OutputMap(t, terraformOptions, "sns_subscriptions")
	assert.NotEmpty(t, actualSnsSubscriptions, "SNS Subscriptions are empty")

	actualRandomId := terraform.Output(t, terraformOptions, "random_int")
	assert.NotEmpty(t, actualRandomId, "Random ID is empty")

	expectedNamePrefix := terraform.GetVariableAsStringFromVarFile(t, dir+testVarFileName, "naming_prefix")
	expectedSqsName := expectedNamePrefix + "-sqs-" + actualRandomId

	messageForTopic := "hello sqs from sns"
	topicARN := flag.String("t", actualSnsTopicARN, "The ARN of the topic to which the user subscribes")
	queue := flag.String("q", expectedSqsName, "The name of the queue")

	flag.Parse()

	require.NotEmpty(t, *topicARN, "Topic ARN cannot be empty")
	require.NotEmpty(t, *queue, "Queue name cannot be empty")

	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithSharedConfigProfile(os.Getenv("AWS_PROFILE")),
	)
	if err != nil {
		assert.Error(t, err, "can't connect to aws")
	}
	clientSNS := sns.NewFromConfig(cfg)
	clientSQS := sqs.NewFromConfig(cfg)

	// Publish message to SNS
	publishInput := &sns.PublishInput{
		Message:  aws.String(messageForTopic),
		TopicArn: topicARN,
	}

	publishResp, err := PublishMessage(context.TODO(), clientSNS, publishInput)
	require.NoError(t, err, "Error publishing message to SNS")
	require.NotNil(t, publishResp.MessageId, "Message ID should not be nil")

	t.Logf("Message published to SNS. Message ID: %s", *publishResp.MessageId)

	gQInput := &sqs.GetQueueUrlInput{
		QueueName: queue,
	}

	urlResult, err := GetQueueURL(context.TODO(), clientSQS, gQInput)
	require.NoError(t, err, "Error getting SQS queue URL")
	require.NotNil(t, urlResult.QueueUrl, "Queue URL should not be nil")

	queueURL := urlResult.QueueUrl
	gMInput := &sqs.ReceiveMessageInput{
		MessageAttributeNames: []string{
			string(types.QueueAttributeNameAll),
		},
		QueueUrl:            queueURL,
		MaxNumberOfMessages: 1,
		WaitTimeSeconds:     10,
		VisibilityTimeout:   15, // Set the visibility timeout as needed
	}

	msgResult, err := GetMessages(context.TODO(), clientSQS, gMInput)
	require.NoError(t, err, "Error receiving messages from SQS")
	var data map[string]string

	if assert.NotNil(t, msgResult.Messages, "No messages found in SQS queue") {
		t.Logf("Received message from SQS")
	}

	errJsonMsg := json.Unmarshal([]byte(*msgResult.Messages[0].Body), &data)
	if errJsonMsg != nil {
		assert.Error(t, errJsonMsg, "An error occured while parsing the data ")
		return
	}

	actualsqsMessage := data["Message"]
	fmt.Println("Message Received:", actualsqsMessage)

	if messageForTopic != actualsqsMessage {
		assert.Fail(t, "The Expected Message doesnot match the Actual Message")

	}
	checkTagsMatch(t, dir, actualSnsTopicARN, clientSNS)
}

func checkTagsMatch(t *testing.T, dir string, actualARN string, client *sns.Client) {
	expectedTags, err := terraform.GetVariableAsMapFromVarFileE(t, dir+testVarFileName, "tags")
	assert.NoError(t, err)

	result, err := client.ListTagsForResource(context.TODO(), &sns.ListTagsForResourceInput{ResourceArn: aws.String(actualARN)})

	assert.NoError(t, err, "Failed to retrieve tags from AWS")
	actualTags := map[string]string{}
	for _, tag := range result.Tags {
		actualTags[*tag.Key] = *tag.Value
	}
	assert.True(t, reflect.DeepEqual(actualTags, standardTags), fmt.Sprintf("tags did not match, expected: %v\nactual: %v", expectedTags, actualTags))

}

func tearDownWrapperSNS(t *testing.T, dir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, dir)
	terraformOptions.Logger = logger.Discard
	terraform.Destroy(t, terraformOptions)

}
