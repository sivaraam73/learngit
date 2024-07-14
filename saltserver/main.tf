#==================  Set Terraform Openstack Block ===============
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
    openstack  =  {
      source   =  "terraform-provider-openstack/openstack"
      version  =  " >= 1.8.1"
    }
    ovh = {
      source   =  "ovh/ovh"
      version  =  ">= 0.40.0"
    }
  }
}


#==============  Configure Provider Access  ======================
provider "openstack" {

  auth_url          =  "https://auth.cloud.ovh.net/v3"
  user_name         =  "~/.openstack/user_name"
  password          =  "~/.openstack/password"
  user_domain_name  =  "Default"
  region            =  "GRA5"
}

provider "ovh" {

  application_key     =  "~/.ovh/application_key"
  application_secret  =  "~/.ovh/application_secret"
  consumer_key        =  "~/.ovh/consumer_key"

}

#  ===========  Data Source Section ===========
# The data keyword is useful if you know a resource
# by name and want the full resource associated to it,
# so we can access all the attributes


data "openstack_images_image_v2" "deployment_image" {
  name         =  var.deployment_image
  most_recent  =  true
}

data "openstack_compute_flavor_v2" "deployment_flavor" {
    name  =  var.deployment_flavor
}


#====================== Set the Public Network For Our Instance  ==================
data "openstack_networking_network_v2" "public_network" {
  # At OVH Cloud "Ext-Net" is the name of the public network
  # same in all regions
  name = "Ext-Net"
}


#===================  Set the Private Network For Our Instance  ===================

# data "openstack_networking_network_v2" "private_network" {
#   # At OVH Cloud "Ext-Net" is the name of the public network
#   # same in all regions
#   name = "VPN-Infra"
#   
# }

# #=========== The key to access your instance =========================
resource "openstack_compute_keypair_v2" "server_key" {
  name        =  "id_rsa_sivamac"
  public_key  =  file(var.pub_key)
}

data "openstack_images_image_v2" "deployment_image" {
  name        = var.deployment_image
  most_recent = true
}

data "openstack_compute_flavor_v2" "deployment_flavor" {
  name = var.deployment_flavor
}

#  =========== Resources =========================
# A resource is an object in Terraform
# that will persist in the state file
# In this test, we are using the openstack provider


#=========== Configure 1st Network Interface =========================
resource "openstack_networking_port_v2" "public_port" {
  count            =  var.instance_count # Default 1
  name             =  "${var.deployment_instances}"
  network_id       =  data.openstack_networking_network_v2.public_network.id
  admin_state_up   =  "true"
}

#=========== Configure 2nd Network Interface =========================
# resource "openstack_networking_port_v2" "private_port" {
#   count           =  var.instance_count # Default 1
#   name            =  "${var.deployment_instances}"
#   #name           =  "${var.deployment_instances}"
#   network_id      =  data.openstack_networking_network_v2.private_network.id
#   admin_state_up  =  "true"
# }

#=========== Configure 2nd Network Interface =========================
# resource "openstack_networking_port_v2" "private_port" {
#   count           =  var.instance_count # Default 1
#   name            =  "${var.deployment_instances}"
#   #name           =  "${var.deployment_instances}"
#   network_id      =  data.openstack_networking_network_v2.private_network.id
#   admin_state_up  =  "true"
# }

#=========== Configure Instance Parameters =========================
resource "openstack_compute_instance_v2" "deployment_instances" {
    count        =  var.instance_count
    name         =  "${var.deployment_instances}.ipatest.beebryte.uk"
    image_id     =  data.openstack_images_image_v2.deployment_image.id
    flavor_id    =  data.openstack_compute_flavor_v2.deployment_flavor.id
    key_pair     =  openstack_compute_keypair_v2.server_key.name
    region       =  "GRA5"
#   #user_data  = data.template_file.user_data.rendered
#   # user_data = data.template_file.user_data.rendered

  network {
    port = openstack_networking_port_v2.public_port[count.index].id
  }
#   network {
#     port = openstack_networking_port_v2.private_port[count.index].id
#   }

  lifecycle {
    ignore_changes  =  [image_id]
    #create_before_destroy = true
    #prevent_destroy = true
 }
}

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tmpl",
    {
      hosts = openstack_compute_instance_v2.deployment_instances.*.access_ip_v4
    }
  )
  filename = "${pwd}/playbooks/inventory"
  #depends_on = [openstack_compute_instance_v2.deployment_instances]
  depends_on = [ openstack_compute_instance_v2.deployment_instances[0] ]
}

output "deployserverip"	{
	value = "${openstack_compute_instance_v2.deployment_instances[0].access_ip_v4} initialized with success"
}



resource "null_resource" "run_ansible" {
  provisioner "remote-exec" {
    connection {
      host         =  openstack_compute_instance_v2.deployment_instances[0].access_ip_v4
      type         =  "ssh"
      user         =  "almalinux"
      private_key  =  file("${ansible_ssh_private_key_file}")
    }
    inline = ["echo Done!"]
  }

  provisioner "local-exec" {
    command   = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u almalinux -v -i ${pwd}/playbooks/inventory ${pwd}/playbooks/install-deployfr.yml" 
  }
}


