---
# input variables
environment: "ENVIRONMENT"

# dependencies
build_s3_bucket_dependency_path: "reg-primary/s3-buckets/state"
build_s3_bucket_mock_output:
  s3_bucket_id: PREFIXENVIRONMENTtfstate
  s3_bucket_arn: arn:aws:s3:::PREFIXENVIRONMENTtfstate
  s3_bucket_region: REG_PRIMARY
