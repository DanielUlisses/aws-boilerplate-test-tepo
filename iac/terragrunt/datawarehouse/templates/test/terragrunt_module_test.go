package test

import (
	"flag"
	//"fmt"
	"os"
	//"regexp"
	//"sort"
	//"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	//"github.com/thedevsaddam/gojsonq/v2"
	"gopkg.in/yaml.v3"
)

// Flags
var destroy = flag.Bool("destroy", false, "destroy environment after tests")
var moddir = flag.String("moddir", "../../reg-primary/resource-groups/template", "path to directory of the module to test")
var rootdir = flag.String("rootdir", "../../.", "path to directory of the deployment to test")

func TestTerragruntModule(t *testing.T) {

	// Terraform options
	binary := "terragrunt"
	moddir := *moddir
	rootdir := *rootdir

	// Define the module options
	terraformModuleOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    moddir,
		TerraformBinary: binary,
	})

	// Define the deployment options
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
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/azure.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/reg-primary/region.yaml") {
		t.Fail()
	}
	if !fileExists(terraformDeploymentOptions.TerraformDir + "/reg-secondary/region.yaml") {
		t.Fail()
	}

	// Check for standard module files
	if !fileExists(terraformModuleOptions.TerraformDir + "/inputs.yaml") {
		t.Fail()
	}
	if !fileExists(terraformModuleOptions.TerraformDir + "/remotestate.tf") {
		t.Fail()
	}
	if !fileExists(terraformModuleOptions.TerraformDir + "/terragrunt.hcl") {
		t.Fail()
	}

	// Sanity test
	terraform.Validate(t, terraformModuleOptions)

	// Reusable vars for unmarshalling YAML files
	var err error
	var yfile []byte

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
	yfile, err = os.ReadFile(terraformDeploymentOptions.TerraformDir + "/azure.yaml")
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

	// Read and store the inputs.yaml
	yfile, err = os.ReadFile(terraformModuleOptions.TerraformDir + "/inputs.yaml")
	if err != nil {
		t.Fail()
	}

	inputs := make(map[string]interface{})
	err = yaml.Unmarshal(yfile, &inputs)
	if err != nil {
		t.Fail()
	}

	// Read and store the terragrunt.hcl
	hclfile, err := os.ReadFile(terraformModuleOptions.TerraformDir + "/terragrunt.hcl")
	if err != nil {
		t.Fail()
	}

	hclstring := string(hclfile)

	// Make sure the path referes to the correct parent hcl file
	assert.Contains(t, hclstring, "path = find_in_parent_folders(\"templates_terragrunt.hcl\")")

	// Clean up after ourselves if flag is set
	if *destroy {
		defer terraform.Destroy(t, terraformModuleOptions)
	}
	// Deploy the composition
	terraform.Apply(t, terraformModuleOptions)

	// Read the provider output and verify configured version
	providers := terraform.RunTerraformCommand(t, terraformModuleOptions, terraform.FormatArgs(terraformModuleOptions, "providers")...)

	// Collect the outputs
	outputs := terraform.OutputAll(t, terraformModuleOptions)

	// The following collections are available for tests:
	//   platform, env, mregion, pregion, sregion, inputs, outputs, providers
	// Two key patterns are available.
	// 1. Reference the output map returned by terraform.OutputAll (ie. the output of "terragrunt output")
	//		require.Equal(t, pregion["location"], outputs["location"])
	// 2. Query the json string representing state returned by terraform.Show (ie. the output of "terragrunt show -json")
	//		modulejson := gojsonq.New().JSONString(terraform.Show(t, terraformOptions)).From("values.root_module.resources").
	//			Where("address", "eq", "azurerm_resource_group.main").
	//			Select("values")
	//		// Execute the above query; since it modifies the pointer we can only do this once, so we add it to a variable
	//		values := modulejson.Get()

	// Make sure the provider version is correct
	assert.Contains(t, providers, "provider[registry.terraform.io/hashicorp/azurerm] ~> "+conf["azure_provider_version"].(string))

	// Check for a string in the terragrunt.hcl
	assert.Contains(t, hclstring, "prevent_destroy")

	// Make sure the module is deployed in the correct region
	require.Equal(t, pregion["location"], outputs["location"])

	// Make sure the group name contains the prefix, environment and base name
	assert.Contains(t, outputs["name"], platform["prefix"].(string))
	assert.Contains(t, outputs["name"], env["environment"].(string))
	assert.Contains(t, outputs["name"], inputs["name"].(string))

	// Test to debug goes here

}

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}
