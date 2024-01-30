---
# input variables
environment: "ENVIRONMENT"

# dependencies
dataprocess_s3_bucket_dependency_path: "reg-primary/s3-buckets/dataprocess"
dataprocess_s3_bucket_mock_output:
  s3_bucket_id: PREFIXENVIRONMENTdataprocess
  s3_bucket_arn: arn:aws:s3:::PREFIXENVIRONMENTdataprocess
  s3_bucket_region: REG_PRIMARY

