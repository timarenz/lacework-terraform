# Lacework with Nomad on AWS

This Terraform workspace allows you to deploy a simple (insecure) Nomad cluster on top of AWS.
In addition a simple and also insecure Consul cluster is deployed and configured for DNS resolution.

Access to the Nomad (4646) and Consul (8500) API is limited to the public IP of the machine that Terraform is executed on.

The Lacework agent is installed on the Nomad server and client directly and is not scheduled via Nomad.

Make sure you configure your AWS and Lacework provider to point to the correct accounts.

To deploy just run: `terraform apply` and make sure you provide the required variables.

## voteapp

To deploy the vote app (`files/voteapp.nomad`) you need to set the host ip addresses of the respective nomads client nodes as variable of the host file.
This is required to get service discovery working. If there is a better way of doing this, let me know!

```bash
nomad job run -address "http://$(terraform output -json nomad_server_public_ips | jq -r '.[0]'):4646" \
    -var "ui_host_ip=$(terraform output -json nomad_client_private_ips | jq -r '.[0]')" \
    -var "data_host_ip=$(terraform output -json nomad_client_private_ips | jq -r '.[1]')" \
    -var "worker_host_ip=$(terraform output -json nomad_client_private_ips | jq -r '.[2]')" \
    ./files/voteapp.nomad
```