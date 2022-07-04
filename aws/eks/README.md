# lacework-terraform / aws / eks

Terraform example to deploy an EKS cluster on AWS and integrate with Lacework.
For the integration the Lacework agent as well as the Lacework admission controller and proxy scanner are deployed.

Access to the EKS API endpoint is restricted to the public IP address of the machine that is used to deploy this example via Terraform.

Disclaimer: This is only for meant to be used in demonstrations and not intended for production deployments.
