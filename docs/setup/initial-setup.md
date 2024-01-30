# Initial Setup
1. navigate to the directory `iac/terragrunt`
1. execute the command `make prod_config` - this command can be replaced for another environment. This example uses [prod] environment
1. comment the remote state block in the file `iac/terragrunt/build_terragrunt.hcl`
1. navigate to the folder `iac/terragrunt/build/reg-primary/kms-keys/state`
1. rename the file `remotestate.tf` to `remotestate.t_`
1. execute a `terragrunt init`
1. execute a `terragrunt apply`
1. navigate to the folder `iac/terragrunt/build/reg-primary/s3-buckets/state`
1. rename the file `remotestate.tf` to `remotestate.t_`
1. execute a `terragrunt init`
1. execute a `terragrunt apply`
1. execute the same proccess in the folder `iac/terragrunt/build/reg-primary/dynamodb-tables/state`
1. rename the file `remotestate.tf` to `remotestate.t_`
1. execute a `terragrunt init`
1. execute a `terragrunt apply`
1. uncomment the remote state block and rollback the file name change to `remotestate.tf` on both folders
1. run a `terragrunt init --reconfigure` command on all folders
1. confirm the changes on the s3 bucket
1. starting here all zones can be deployed running the commands from the Makefile
