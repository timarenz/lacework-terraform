# aws / nexus

This repo will set up two EC2 instances, one containing a Nexus repo and another one running the Lacwork proxy scanner.

## Initial Terraform apply

The inital `terraform apply` run might fail, as the ACM certificate needs to manually verified. This is especially true if a new FQDN is choosen.

For the manual verification, log on to the AWS console and verfiy the certificate in the ACM console.
After this is done, rerun `terraform apply`

Another error might be that the certificate is not created in time. See error below.

```bash
Error: error creating ELBv2 Listener (arn:aws:elasticloadbalancing:eu-central-1:950194951070:loadbalancer/app/nexus-alb-c16051/8eead5017ac0b3e4): UnsupportedCertificate: The certificate 'arn:aws:acm:eu-central-1:950194951070:certificate/f1fa7e16-4390-431d-8498-e2c0e0325f26' must have a fully-qualified domain name, a supported signature, and a supported key size.
│ 	status code: 400, request id: cef471b1-c706-471e-8da6-f13073dcd90d
│
│   with aws_lb_listener.main,
│   on main.tf line 238, in resource "aws_lb_listener" "main":
│  238: resource "aws_lb_listener" "main" {
```

If this is the case, just rerun `terraform apply`.

## Nexus setup

For the Nexus repo manual configuration steps are required.

First, log on using ssh to the nexus server and read the admin password.

```bash
ssh ubuntu@3.68.213.187 
Warning: Permanently added '3.68.213.187' (ED25519) to the list of known hosts.
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue Dec 21 08:31:48 UTC 2021

  System load:  0.66              Processes:                116
  Usage of /:   4.6% of 61.98GB   Users logged in:          0
  Memory usage: 58%               IPv4 address for docker0: 172.17.0.1
  Swap usage:   0%                IPv4 address for ens5:    192.168.30.168


16 updates can be applied immediately.
9 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable


Last login: Tue Dec 21 08:28:42 2021 from 93.224.193.203
ubuntu@ip-192-168-30-168:~$ cat /opt/nexus-data/admin.password
cda6052b-1b16-42b5-ab36-51c7841558b2
```

Now connect to the `http://<IPofNexusEC2Instance:8081` and set the default password to the same as specified in the `nexus_password` variable.

After that create a new registry with the name of `docker` that listens on HTTP port `5000`.

![docker-repo-configuration](https://github.com/timarenz/lacework-terraform/blob/main/aws/nexus/assets/images/docker-repo-config.png?raw=true)

## Proxy scanner setup

After the docker registry is set up, proxy scanner needs to be restarted.

For that log on the the proxy scanner EC2 instance and restart the container.

```bash
sshi ubuntu@3.68.199.208
Warning: Permanently added '3.68.199.208' (ED25519) to the list of known hosts.
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue Dec 21 08:37:29 UTC 2021

  System load:  0.0               Processes:                107
  Usage of /:   27.1% of 7.69GB   Users logged in:          0
  Memory usage: 7%                IPv4 address for docker0: 172.17.0.1
  Swap usage:   0%                IPv4 address for ens5:    192.168.30.117


16 updates can be applied immediately.
9 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable


Last login: Tue Dec 21 08:29:28 2021 from 93.224.193.203

ubuntu@ip-192-168-30-117:~$ sudo docker restart proxy-scanner
proxy-scanner
```

After that you are good to go an upload container images.


## Login to registry

To login to the registry just us `docker login nexus.domain.example` and authenticate using the user `admin` and the password you choose to set up the Nexus server.