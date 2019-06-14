# AzureVM 2.0.0

* Complete rewrite of package, to be less DSVM-centric and more flexible:
  * Separate out deployment of VMs and VM clusters; the latter are implemented as single scaleset resources, rather than simple arrays of individual VMs.
  * `vm_config` and `vmss_config` functions to fine-tune the deployment options, including specifying the base VM image; networking details like security rules, load balancers and autoscaling; datadisks to attach; use of low-priority VMs for scalesets; etc.
  * Several predefined configurations supplied to allow quick deployment of commonly used images (Ubuntu, Windows Server, RHEL, Debian).
  * Allow referring to existing resources in a deployment, by supplying `AzureRMR::az_resource` objects as arguments.
  * See the README and/or the vignette for more information.

# AzureVM 1.0.1

* Allow resource group and subscription accessor methods to work without AzureVM on the search path.

# AzureVM 1.0.0

* Submitted to CRAN

# AzureVM 0.9.0

* Moved to cloudyr organisation
