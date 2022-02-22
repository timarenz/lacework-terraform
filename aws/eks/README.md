# lacework-terraform / aws / eks

Terraform example to deploy an EKS cluster on AWS and integrate with Lacework.
For the integration the Lacework agent as well as the Lacework admission controller and proxy scanner are deployed.

Access to the EKS API endpoint is restricted to the public IP address of the machine that is used to deploy this example via Terraform.

Disclaimer: This is only for meant to be used in demonstrations and not intended for production deployments.

## Usage

Make sure that the different Terraform workspace are applied in the correct order:

1. eks-cluster
2. eks-config-and-nodes
3. lacework-integration

For the destroy operation it is obviously the other way around.

Terragrunt can be used to automate this by running `terragrunt run-all init`, `terragrunt run-all apply` or `terragrunt run-all destroy`.
The required `terragrund.hcl` files for the dependency mapping are included.
