"""Stateful backend services. Each keeps working in process memory and switches to AWS (DynamoDB, SNS,
Kinesis, S3, Secrets Manager), Redis or FCM as soon as that piece is configured."""
