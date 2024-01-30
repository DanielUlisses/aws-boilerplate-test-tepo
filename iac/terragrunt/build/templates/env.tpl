---
# input variables
approvers_arn: "APPROVERS_ARN"
approvers_count: 1
branch: "main"
environment: "ENVIRONMENT"

# dependencies
build_s3_bucket_dependency_path: "reg-primary/s3-buckets/state"
build_s3_bucket_mock_output:
  s3_bucket_id: PREFIXENVIRONMENTtfstate
  s3_bucket_arn: arn:aws:s3:::PREFIXENVIRONMENTtfstate
  s3_bucket_region: REG_PRIMARY

build_kms_key_dependency_path: "reg-primary/kms-keys/state"
build_kms_key_mock_output:
  key_arn: arn:aws:kms:::key/1234abcd-12ab-34cd-56ef-1234567890ab