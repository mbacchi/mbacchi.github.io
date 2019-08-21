---
layout: post
title: "Setting up an EC2 Instance as an Inlets Exit Node"
date: 2019-08-21 12:00:00
comments: true
published: true
tags: terraform inlets aws ec2
---

[Inlets](https://github.com/alexellis/inlets) is a fairly new project that
allows you to setup reverse proxy, websocket tunnels, or other endpoints to the
public internet, it is similar to [ngrok](https://ngrok.com/). The [video
overview from Alex Ellis](https://youtu.be/jrAqqe8N3q4) shows how simple it
makes setting up the environment.

Also, there are scripts in the Inlets repository to provision DigitalOcean
droplets. Let's setup an AWS EC2 instance, though AWS is more expensive than DO,
it's obviously a popular platform. The steps below are [required to setup an AWS
VPC and related
networking](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-subnets-commands-example.html)
before launching our instance.

In this blog post we'll set up an exit node using the AWS CLI, then make it
simpler with Terraform.

## Using the AWS CLI

Here is an example of the commands that would need to be run from the AWS CLI if
you wanted to use that method for starting up the EC2 instance. (*Note*: Do not
copy all these commands directly, many of them reference objects in my AWS
account such as VPC IDs, SG IDs etc. and which were removed after this blog post
was written.)

```
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region us-east-2

aws ec2 create-security-group --group-name "temp-inlets-sg" --vpc-id vpc-0492e18d8bda513ab --description \
"Inlets security group" --region us-east-2

aws ec2 authorize-security-group-ingress --group-id sg-08754da824fc991bc --protocol tcp --port 22 --cidr \
161.97.199.201/32 --region us-east-2

aws ec2 authorize-security-group-ingress --group-id sg-08754da824fc991bc --protocol tcp --port 8090 --cidr \
161.97.199.201/32 --region us-east-2

aws ec2 create-key-pair --key-name inlets-test-keypair --region us-east-2 | jq -r ".KeyMaterial" \
> inlets-keypair.pem

aws ec2 create-subnet --vpc-id vpc-0492e18d8bda513ab --availability-zone us-east-2a --cidr-block 10.0.5.0/20 \
--region us-east-2

aws ec2 create-internet-gateway --region us-east-2

aws ec2 attach-internet-gateway --vpc-id vpc-0492e18d8bda513ab --internet-gateway-id igw-07411b46a0ce5ae46 \
--region us-east-2

aws ec2 create-route-table --vpc-id vpc-0492e18d8bda513ab --region us-east-2

aws ec2 create-route --route-table-id rtb-0423d1a8bf3f1a226 --destination-cidr-block 0.0.0.0/0 --gateway-id \
igw-07411b46a0ce5ae46 --region us-east-2

aws ec2 associate-route-table  --subnet-id subnet-00de3c90045c569db --route-table-id rtb-0423d1a8bf3f1a226 \
--region us-east-2

aws ec2 run-instances --image-id ami-0eaecb2e7d28d5f33 --count 1 --instance-type t3a.micro --security-group-ids \
sg-08754da824fc991bc --key-name inlets-test-keypair --region us-east-2 --tag-specifications \
'ResourceType=instance,Tags=[{Key="Purpose",Value="TESTING"}]' --associate-public-ip-address
```

That's a lot of typing to setup an AWS instance before deploying the inlets
project. Lets see if we can do this with less effort using Terraform.

## Terraform

The terraform equivalent to setup an EC2 instance with all the plumbing is quite
a bit more concise. You can view the Terraform I wrote in [this
repository](https://github.com/mbacchi/inlets-aws-ec2-terraform).

**Note**: We don't create an AWS keypair in Terraform, I consider that bad form.
In order to avoid any security concerns we expect that you use a keypair
previously generated or uploaded to your AWS account. You can use the `aws ec2
create-key-pair` command [above](#Using-the-AWS-CLI) as an example if you want
to use the CLI.

### Prerequisites

* Terraform
* An AWS account
* An AWS Keypair

### Prepare to run terraform

These steps include:

* Install terraform
* Clone the [inlets-aws-ec2-terraform
repository](https://github.com/mbacchi/inlets-aws-ec2-terraform) (i.e. `git clone https://github.com/mbacchi/inlets-aws-ec2-terraform`)
* `cd inlets-aws-ec2-terraform`
* Run `terraform init`
* Export environment variables for your AWS_PROFILE and AWS_REGION. This looks
  something like: `export AWS_PROFILE=PROFILE_NAME && export AWS_REGION=us-east-2`
* Don't forget to change the `PROFILE_NAME` in the export command above!
* Change the `key_name` on [line
64](https://github.com/mbacchi/inlets-aws-ec2-terraform/blob/master/main.tf#L64)
of `main.tf` to the name of your own keypair!

### Create the terraform plan

Create the token and run the `terraform plan` command with the single command line:

```
token=$(head -c 16 /dev/urandom | sha256sum | cut -d" " -f1); terraform plan -out=terraform_plan.$(date +%F.%H.%M.%S).out  -var "token=$token"
```

This will output a file to be used in the next step, named something like: `terraform_plan.2019-08-20.23.04.54.out`

**Note**: You might not have `sha256sum` on your system, it can be replaced
with `shasum`.

### Apply the terraform plan

Apply the plan that you created in the previous step after reviewing the plan output.

```
terraform apply terraform_plan.2019-08-20.23.04.54.out
...
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

inlets_token = 2395590c8b333cb2cb9f54ac152aac03e0365c1c69ce20348a3124b84c98ec62
public_ip_address = 3.19.218.92
```

The terraform output that you see in the last few lines provides the Inlets
token required by the client to authenticate with the server, and the public IP
address of the EC2 instance. Use this info in the below steps.

## Connecting to Inlets

Now that you have deployed the AWS infrastructure using Terraform, we will run
an application locally and serve it on the public internet from the Inlets exit
node.

This is documented in the [Inlets
README](https://github.com/alexellis/inlets#install-the-cli), but basically on
your client machine you need an application such as a webserver running. For
example my jekyll blog:

```
cd blog
make serve 
JEKYLL_ENV=development jekyll serve
Configuration file: _config.yml
            Source: .
       Destination: _site
 Incremental build: disabled. Enable with --incremental
      Generating... 
                    done in 1.149 seconds.
 Auto-regeneration: enabled for 'myblog'
    Server address: http://127.0.0.1:4000
  Server running... press ctrl-c to stop.
```

In another terminal session I can start the Inlets client:

```
export TOKEN="2395590c8b333cb2cb9f54ac152aac03e0365c1c69ce20348a3124b84c98ec62"

export REMOTE="3.19.218.92:8090"

inlets client  --remote=$REMOTE --upstream=http://127.0.0.1:4000 --token $TOKEN
```

In a web browser, I can open the url `3.19.218.92:8090` and see my
application that was running locally only.

## Remove the Terraformed infrastructure

When you want to remove this infrastructure, run `terraform destroy` from the
cloned `inlets-aws-ec2-terraform` directory where you ran `terraform apply` etc.
