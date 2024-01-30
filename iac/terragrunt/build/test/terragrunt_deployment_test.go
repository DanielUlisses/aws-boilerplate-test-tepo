package test

import (
	"flag"
	"fmt"
	"os"

	// "regexp"
	"sort"
	// "strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

// Flag to destroy the target environment after tests
var destroy = flag.Bool("destroy", false, "destroy environment after tests")

func TestTerragruntDeployment(t *testing.T) {

	// Terraform options
	binary := "terragrunt"
	rootdir := "../."
	moddirs := make(map[string]string)

	// Non-local vars to evaluate state between modules
	// var statestorage string

	// Reusable vars for unmarshalling YAML files
	var err error
	var yfile []byte

	// Define the deployment root
	terraformDeploymentOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    rootdir,
		TerraformBinary: binary,
	})

	// Check for standard global configuration files
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/terragrunt_conf.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/env.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/aws.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/reg-primary/region.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/reg-secondary/region.yaml") {
		t.Fail()
	}

	// Define modules
	moddirs["0-kmskeys"] = "../reg-primary/kms-keys/state"
	moddirs["0-statestorage"] = "../reg-primary/s3-buckets/state"
	moddirs["0-dynamodbtables"] = "../reg-primary/dynamodb-tables/state"

	// Maps are unsorted, so sort the keys to process the modules in order
	modkeys := make([]string, 0, len(moddirs))
	for k := range moddirs {
		modkeys = append(modkeys, k)
	}
	sort.Strings(modkeys)

	for _, module := range modkeys {
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir:    moddirs[module],
			TerraformBinary: binary,
		})

		fmt.Println("Validating module:", module)

		// Sanity test
		terraform.Validate(t, terraformOptions)

		// Check for standard files
		if !fileExists(terraformOptions.TerraformDir + "/inputs.yaml") {
			t.Fail()
		}
		if !fileExists(terraformOptions.TerraformDir + "/remotestate.tf") {
			t.Fail()
		}
		if !fileExists(terraformOptions.TerraformDir + "/terragrunt.hcl") {
			t.Fail()
		}
	}

	// Read and store the terragrunt_conf.yaml
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/terragrunt_conf.yaml")
	if err != nil {
		t.Fail()
	}

	conf := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &conf)
	if err != nil {
		t.Fail()
	}

	// Read and store the env.yaml
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/env.yaml")
	if err != nil {
		t.Fail()
	}

	env := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &env)
	if err != nil {
		t.Fail()
	}

	// Read and store the azure.yaml
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/aws.yaml")
	if err != nil {
		t.Fail()
	}

	platform := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &platform)
	if err != nil {
		t.Fail()
	}

	// Read and store the reg-primary/region.yaml
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/reg-primary/region.yaml")
	if err != nil {
		t.Fail()
	}

	pregion := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &pregion)
	if err != nil {
		t.Fail()
	}

	// Read and store the reg-secondary/region.yaml
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/reg-secondary/region.yaml")
	if err != nil {
		t.Fail()
	}

	sregion := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &sregion)
	if err != nil {
		t.Fail()
	}

	// Clean up after ourselves if flag is set
	if *destroy {
		defer terraform.TgDestroyAll(t, terraformDeploymentOptions)
	}
	// Deploy the composition
	terraform.TgApplyAll(t, terraformDeploymentOptions)

	for _, module := range modkeys {
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir:    moddirs[module],
			TerraformBinary: binary,
		})

		fmt.Println("Testing module:", module)

		// Read the provider output and verify configured version
		providers := terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "providers")...)
		assert.Contains(t, providers, "provider[registry.terraform.io/hashicorp/aws] ~> "+conf["aws_provider_version"].(string))

		// Read the inputs.yaml
		yfile, err := os.ReadFile(terraformOptions.TerraformDir + "/inputs.yaml")
		if err != nil {
			t.Fail()
		}

		inputs := make(map[string]interface{})
		err = yaml.Unmarshal(yfile, &inputs)
		if err != nil {
			t.Fail()
		}

		// Read the terragrunt.hcl
		hclfile, err := os.ReadFile(terraformOptions.TerraformDir + "/terragrunt.hcl")
		if err != nil {
			t.Fail()
		}

		hclstring := string(hclfile)

		// Make sure the path referes to the correct parent hcl file
		assert.Contains(t, hclstring, "path = find_in_parent_folders(\"build_terragrunt.hcl\")")

		// Collect the outputs
		outputs := terraform.OutputAll(t, terraformOptions)

		// Add module-specific tests below
		// Remember that we're in a loop, so group tests by module name (modules range keys)
		// The following collections are available for tests:
		//   platform, env, mregion, pregion, sregion, inputs, outputs
		// Two key patterns are available.
		// 1. Reference the output map returned by terraform.OutputAll (ie. the output of "terragrunt output")
		//		require.Equal(t, pregion["location"], outputs["location"])
		// 2. Query the json string representing state returned by terraform.Show (ie. the output of "terragrunt show -json")
		//		modulejson := gojsonq.New().JSONString(terraform.Show(t, terraformOptions)).From("values.root_module.resources").
		//			Where("address", "eq", "azurerm_resource_group.main").
		//			Select("values")
		//		// Execute the above query; since it modifies the pointer we can only do this once, so we add it to a variable
		//		values := modulejson.Get()

		// Module-specific tests
		switch module {

		// Kms Keys module
		case "0-kmskeys":
			// Make sure the account name contains the prefix, environment and base name
			// assert.Contains(t, outputs["key_arn"], platform["prefix"].(string))
			// assert.Contains(t, outputs["key_arn"], env["environment"].(string))
			// assert.Contains(t, outputs["key_arn"], inputs["name"].(string))

			// Make sure that prevent_destroy is set to true
			assert.Contains(t, hclstring, "prevent_destroy = true")

		// State Storage module
		case "0-statestorage":
			// Make sure the account is in the correct region
			require.Equal(t, pregion["region"], outputs["s3_bucket_region"])

			// Make sure the account name contains the prefix, environment and base name
			assert.Contains(t, outputs["s3_bucket_arn"], platform["prefix"].(string))
			assert.Contains(t, outputs["s3_bucket_arn"], env["environment"].(string))
			assert.Contains(t, outputs["s3_bucket_arn"], inputs["name"].(string))

			// Store the storage account id for reference
			// statestorage = outputs["s3_bucket_id"].(string)

			// Make sure that prevent_destroy is set to true
			assert.Contains(t, hclstring, "prevent_destroy = true")

		// Dynamodb State module
		case "1-dynamodbState":
			// Make sure the account name contains the prefix, environment and base name
			assert.Contains(t, outputs["dynamodb_table_arn"], platform["prefix"].(string))
			assert.Contains(t, outputs["dynamodb_table_arn"], env["environment"].(string))
			assert.Contains(t, outputs["dynamodb_table_arn"], inputs["name"].(string))

			// Make sure that prevent_destroy is set to true
			assert.Contains(t, hclstring, "prevent_destroy = true")

		}
	}
}

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}
