# Azure Infra Components
Using DC/OS Terraform Infrastructure module to spin up a "cluster"-like infrastrcuture with the following components on Azure:

- Resource Group

- Network

- Network SG

- LB

- Bootstrap Node

- Master Node(s)

- Private Nodes(s)

- Private Node(s)

You can view all your components under the Resource Group Created (`dcos-$VAR.CLUSTER_NAME`). You can use this to delete all resources if needed or your TF state gets lost. 

All VMs will use the username `dcos_admin` user name with the specified ssh key.

# Prerequisites:
Terraform less than version 0.12, cloud credentials, and SSH keys:

## Installing Terraform.
If you're on a Mac environment with [homebrew](https://brew.sh/) installed, simply run the following command:
```bash
brew install terraform
```

For help installing Terraform on a different OS, please see [here](https://www.terraform.io/downloads.html):

## Install Azure CLI
You have to install the Azure CLI in order to provide credentials for the terraform provider.

Please checkout the [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) guide to get `az` installed and running


## Ensure your logged into azure
To retrieve credentials please issue

```
$ az login
```

the output will show the subscriptions your user has permissions in.

You can insure being logged in by listing your accounts subscriptions

```
$ az account
[
  {
    "cloudName": "AzureCloud",
    "id": "12345678-abcd-efgh-9876-abc123456789",
    "isDefault": true,
    "name": "Blah Blah Subscription",
    "state": "Enabled",
    "tenantId": "987654321-abcd-efgh-9876-abc123456789",
    "user": {
      "name": "myaccount@azuremesosphere.onmicrosoft.com",
      "type": "user"
    }
  }
]
```

## Ensure Azure Default Subscription
We have to provide the Azure subscription ID. This could be done by exporting `ARM_SUBSCRIPTION_ID`.

If you do not know your subscription id use `az account` to see a list of your subscriptions and copy the desired subscription id.

```bash
export ARM_SUBSCRIPTION_ID="desired-subscriptionid"
```
Example:
```bash
export ARM_SUBSCRIPTION_ID="12345678-abcd-efgh-9876-abc123456789"
```

Ensure it is set:
```bash
> echo $ARM_SUBSCRIPTION_ID
12345678-abcd-efgh-9876-abc123456789
```


## Usage
1) Create a `main.tf` from this repo in your current working directory. Modify any Variable you see fit. See this [README](https://github.com/geekbass/terraform-azurerm-infrastructure) for defaults and/or additional variables you can use within your `main.tf`.

2) Execute the following after you have auth'd to Azure (see above):
```bash
ssh-add ~/.ssh/YOUR_PRIVATE_KEY # adds to key to auth agent
terraform init -upgrade=true
terraform plan -out plan.out
terraform apply plan.out
```

Check out the Azure Console under your Resource Group.

Note: The `main.tf` also creates a local inventory file you can use with Ansible. You will just need to provide an `ansbile.cfg` in the same directory or it will use your default one.

```bash
ansible -m ping all -i inventory 
```

## Destroy
1) Be sure that you are auth'd to Azure (see above)

2) Execute following:

```bash
terraform destroy
```
