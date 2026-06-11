#!/bin/bash
awslocal sqs create-queue --queue-name clinic-tasks
echo "SQS queue 'clinic-tasks' created"
