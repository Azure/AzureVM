# AzureVM 2.0.0.9000

* Add methods to retrieve Azure resources used by a VM: `get_disk`, `get_vnet`, `get_nic`, `get_nsg`, `get_public_ip_resource`. These return objects of class `AzureRMR::az_resource`, or `NULL` if not present.
* Add similar methods to retrieve Azure resources used by a scaleset: `get_vnet`, `get_nsg`, `get_public_ip_resource`, `get_load_balancer`, `get_autoscaler`.
* Add `redeploy` and `reimage` methods for VMs, to match those for VM scalesets.
* Fix error in documentation for VMSS public IP address methods: these return `NA`, not `NULL` if the public address is unavailable.

# AzureVM 2.0.0

* Complete rewrite of package, to be less DSVM-centric and more flexible:
  * Separate out deployment of VMs and VM clusters; the latter are implemented as scalesets, rather than simplistic arrays of individual VMs. The methods to work with scalesets are named `get_vm_scaleset`, `create_vm_scaleset` and `delete_vm_scaleset`; `get/create/delete_vm_cluster` are now defunct.
  * New UI for VM/scaleset creation, with many more ways to fine-tune the deployment options, including specifying the base VM image; networking details like security rules, load balancers and autoscaling; datadisks to attach; use of low-priority VMs for scalesets; etc.
  * Several predefined configurations supplied to allow quick deployment of commonly used images (Ubuntu, Windows Server, RHEL, Debian, Centos, DSVM).
  * Allow referring to existing resources in a deployment (eg placing VMs into an existing vnet), by supplying `AzureRMR::az_resource` objects as arguments.
  * Clear distinction between a VM deployment template and a resource. `get_vm` and `get_vm_scaleset` will always attempt to retrieve the template; to get the resource, use `get_vm_resource` and `get_vm_scaleset_resource`.
  * New VM resource methods: `get_public_ip_address`, `get_private_ip_address`.
  * New cluster/scaleset resource methods: `get_public_ip_address` (technically the address for the load balancer, if present), `get_vm_public_ip_addresses`, `get_vm_private_ip_addresses`, `list_instances`, `get_instance`.
  * Use a pool of background processes to talk to scalesets in parallel when carrying out instance operations. The pool size can be controlled with the global options `azure_vm_minpoolsize` and `azure_vm_maxpoolsize`.
  * See the README and/or the vignette for more information.

# AzureVM 1.0.1

* Allow resource group and subscription accessor methods to work without AzureVM on the search path.

# AzureVM 1.0.0

* Submitted to CRAN

# AzureVM 0.9.0

* Moved to cloudyr organisation
