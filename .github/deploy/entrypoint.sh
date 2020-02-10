#!/bin/sh

set -e

mkdir -p ~/.aws
touch ~/.aws/credentials

echo "[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}" > ~/.aws/credentials

echo 'Uploading CloudFormation Templates to s3 bucket ...'
aws s3 sync ${SOURCE_DIR} s3://${AWS_S3_BUCKET} --delete --region ${AWS_REGION}

echo "Checking if stack exists ..."

if ! aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME} ; then

  echo -e "\nStack does not exist, creating ..."

  aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME} --template-url "https://s3.amazonaws.com/${AWS_S3_BUCKET}/sinatra-stack.yaml" --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=Environment,ParameterValue=${AWS_ENVIRONMENT}

else

  echo -e "\nStack exists, attempting update ..."

  aws cloudformation update-stack --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME} --template-url "https://s3.amazonaws.com/${AWS_S3_BUCKET}/sinatra-stack.yaml" --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=Environment,ParameterValue=${AWS_ENVIRONMENT}

fi

rm -rf ~/.aws
