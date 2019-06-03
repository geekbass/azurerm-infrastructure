data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

variable "cluster_name" {
  description = "Name of your DC/OS Cluster"
  default     = "test"
}

variable "key_public_key_file" {
  description = "The actual SSH public key to use to provision instances with."
  default     = "~/.ssh/id_rsa.pub"
}

variable "infra_dcos_instance_os" {
  description = "Global Infra Tested OSes Image"
  default     = "centos_7.5"
}

variable "infra_admin_username" {
  description = "Global Infra SSH User"
  default     = "dcos_admin"
}

# Azure Region
variable "location" {
  description = "Azure Region"
  default     = "West US"
}

variable "num_masters" {
  description = "Specify the amount of masters. For redundancy you should have at least 3"
  default     = "3"
}

# Number of Private Agents
variable "num_private_agents" {
  description = "Specify the amount of private agents. These agents will provide your main resources"
  default     = "1"
}

# Number of Public Agents
variable "num_public_agents" {
  description = "Specify the amount of public agents. These agents will host marathon-lb and edgelb"
  default     = "0"
}

variable "custom_data" {
  description = "User data to be used on these instances (cloud-init). This prevents kickoff of DC/OS pre-reqs"
  default     = "echo DONE"
}

# Begin Modules
module "dcos-infrastructure" {
  source  = "git::https://github.com/geekbass/terraform-azurerm-infrastructure?ref=user_data"

  # This is used to name resources
  cluster_name = "${var.cluster_name}"

  # Which region to create
  location = "${var.location}"

  # Automatically picks the image for Centos 7.5
  infra_dcos_instance_os = "${var.infra_dcos_instance_os}"

  # SSH key to use
  ssh_public_key_file = "${var.key_public_key_file}"

  # Uses current Public IP... you can add more as a list 
  admin_ips = ["${data.http.whatismyip.body}/32"]

  # SSH username
  infra_admin_username = "${var.infra_admin_username}"

  # Master Nodes Number
  num_masters = "${var.num_masters}"

  # Private Agents Number
  num_private_agents = "${var.num_private_agents}"

  # Public Agents Number
  num_public_agents = "${var.num_public_agents}"

  # Cloud-Init file if desired
  custom_data = "${var.custom_data}"

  # ANY specific tags here  
  tags = {
    owner      = "wbassler"
    expiration = "4hrs"
  }

}

# Local Variables to help create Ansible Inventory and for Creating Ansible config file
locals {
  bootstrap_ansible_ips         = "${join("\n", flatten(list(module.dcos-infrastructure.bootstrap.public_ip)))}"
  bootstrap_ansible_private_ips = "${module.dcos-infrastructure.bootstrap.private_ip}"
  masters_ansible_ips           = "${join("\n", flatten(list(module.dcos-infrastructure.masters.public_ips)))}"
  masters_ansible_private_ips   = "${join("\n      - ", flatten(list(module.dcos-infrastructure.masters.private_ips)))}"
  private_agents_ansible_ips    = "${join("\n", flatten(list(module.dcos-infrastructure.private_agents.public_ips)))}"
  public_agents_ansible_ips     = "${join("\n", flatten(list(module.dcos-infrastructure.public_agents.public_ips)))}"
}

# Build the vars file
/*
resource "local_file" "vars_file" {
  filename = "./ansible/group_vars/all/dcos.yml"

  content = <<EOF
---
dcos:
  download: "https://downloads.dcos.io/dcos/stable/1.11.0/dcos_generate_config.sh"
  version: "1.11.0"
  version_to_upgrade_from: "1.11.0"
  enterprise_dcos: false
  
  config:
    cluster_name: "${var.cluster_name}"
    security: permissive
    bootstrap_url: http://${local.bootstrap_ansible_private_ips}:8080
    exhibitor_storage_backend: static
    master_discovery: static
    master_list:
      - ${local.masters_ansible_private_ips}
    oauth_enabled: true
    enable_ipv6: false
    telemetry_enabled: false
    process_timeout: 600

EOF
}
*/

resource "local_file" "ansible_inventory" {
  filename = "./inventory"

  content = <<EOF
[bootstraps]
${local.bootstrap_ansible_ips}
[masters]
${local.masters_ansible_ips}
[agents_private]
${local.private_agents_ansible_ips}
[agents_public]
${local.public_agents_ansible_ips}
[bootstraps:vars]
node_type=bootstrap
[masters:vars]
node_type=master
dcos_legacy_node_type_name=master
[agents_private:vars]
node_type=agent
dcos_legacy_node_type_name=slave
[agents_public:vars]
node_type=agent_public
dcos_legacy_node_type_name=slave_public
[agents:children]
agents_private
agents_public
[dcos:children]
bootstraps
masters
agents
agents_public
EOF
}

resource "local_file" "ansible_config" {
  filename = "./ansible.cfg"

  content = <<EOF
[defaults]
inventory = inventory
host_key_checking = False
remote_user = ${var.infra_admin_username}
forks = 100
hash_behaviour = replace
[ssh_connection]
control_path = %(directory)s/%%C
pipelining = True
ssh_args = -o PreferredAuthentications=publickey -o ControlMaster=auto -o ControlPersist=5m
EOF
}
/*output "cluster-address" {
  value = "${module.dcos-infrastructure.lb.masters_dns_name}"
}
*/

