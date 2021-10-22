# Lacework with Nomad on AWS

This Terraform workspace allows you to deploy a simple (insecure) Nomad cluster on top of AWS.
In addition a simple and also insecure Consul cluster is deployed and configured for DNS resolution.

Access to the Nomad (4646) and Consul (8500) API is limited to the public IP of the machine that Terraform is executed on.

The Lacework agent is installed on the Nomad server and client directly and is not scheduled via Nomad.

Make sure you configure your AWS and Lacework provider to point to the correct accounts