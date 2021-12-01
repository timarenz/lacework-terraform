# lacework-terraform / aws / eks

Terraform example to deploy an EKS cluster on AWS and integrate with Lacework.
For the integration the Lacework agent as well as the Lacework admission controller and proxy scanner are deployed.

Access to the EKS API endpoint is restricted to the public IP address of the machine that is used to deploy this example via Terraform. Have a look at the resource `aws_eks_cluster.main` to change this to something different.

Disclaimer: This is only for meant to be used in demonstrations and not intended for production deployments.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.5.1 |
| <a name="requirement_lacework"></a> [lacework](#requirement\_lacework) | 0.12.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.67.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.4.1 |
| <a name="provider_http"></a> [http](#provider\_http) | 2.1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.5.1 |
| <a name="provider_lacework"></a> [lacework](#provider\_lacework) | 0.12.2 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_admission_controller_cert"></a> [admission\_controller\_cert](#module\_admission\_controller\_cert) | git::https://github.com/timarenz/terraform-tls-certificate.git | v0.2.1 |
| <a name="module_ca"></a> [ca](#module\_ca) | git::https://github.com/timarenz/terraform-tls-root-ca.git | v0.2.1 |
| <a name="module_environment"></a> [environment](#module\_environment) | git::https://github.com/timarenz/terraform-aws-environment.git | n/a |
| <a name="module_proxy_scanner_cert"></a> [proxy\_scanner\_cert](#module\_proxy\_scanner\_cert) | git::https://github.com/timarenz/terraform-tls-certificate.git | v0.2.1 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ec2_container_registry_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_worker_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.lacework_admission_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.lacework_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.lacework_proxy_scanner](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/2.5.1/docs/resources/config_map) | resource |
| [kubernetes_namespace.lacework](https://registry.terraform.io/providers/hashicorp/kubernetes/2.5.1/docs/resources/namespace) | resource |
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [http_http.current_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [lacework_agent_access_token.eks](https://registry.terraform.io/providers/lacework/lacework/0.12.2/docs/data-sources/agent_access_token) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where you want to deploy this EKS cluster. | `string` | `"eu-central-1"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Used as value of environment tag to identified resources in AWS. | `string` | `"lacework-eks"` | no |
| <a name="input_k8s_admin_role"></a> [k8s\_admin\_role](#input\_k8s\_admin\_role) | Map that contains the name and arn of an AWS role you want to assign the cluster-admin role in the EKS cluster. Example: `{ name = "admin", arn = "rn:aws:iam::123456789012:role/eks-admin-role" }`. | `map(string)` | n/a | yes |
| <a name="input_lacework_account_name"></a> [lacework\_account\_name](#input\_lacework\_account\_name) | Name of your Lacework account. Used for the proxy scanner integration. | `string` | n/a | yes |
| <a name="input_lacework_agent_server_url"></a> [lacework\_agent\_server\_url](#input\_lacework\_agent\_server\_url) | Lacework API Url the agent should connect to. By default the US region is used (`https://api.lacework.net`). If you are using the EU region, use `https://api.fra.lacework.net` as value. | `string` | `"https://api.lacework.net"` | no |
| <a name="input_lacework_agent_token_name"></a> [lacework\_agent\_token\_name](#input\_lacework\_agent\_token\_name) | Name of the Lacework agent token to use to deploy the Lacework agent. This token will not be created using Terraform and there has to be preexisting in your Lacework account. | `string` | n/a | yes |
| <a name="input_lacework_integration_access_token"></a> [lacework\_integration\_access\_token](#input\_lacework\_integration\_access\_token) | Lacework integration access token used for the proxy scanner integration. The integration has to be created within your Lacework account as type "proxy-scanner". | `string` | n/a | yes |
| <a name="input_lacework_proxy_scanner_config"></a> [lacework\_proxy\_scanner\_config](#input\_lacework\_proxy\_scanner\_config) | Lacework proxy scanner configuration. By default only support public images hosted on Docker Hub. Add additional registries as per documentation: https://docs.lacework.com/integrate-proxy-scanner#configure-for-on-demand-scans. | `string` | `"config:\n  default_registry: index.docker.io\n  registries:\n"` | no |
| <a name="input_owner_name"></a> [owner\_name](#input\_owner\_name) | Used as value of owner tag to identified resources in AWS. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_ca_cert"></a> [eks\_cluster\_ca\_cert](#output\_eks\_cluster\_ca\_cert) | EKS cluster CA certificate. |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS cluster API endpoint. |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS cluster name. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig in YAML format. |
