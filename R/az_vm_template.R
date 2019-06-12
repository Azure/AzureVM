#' Virtual machine template class
#'
#' Class representing a virtual machine template. This class keeps track of all resources that are created as part of deploying a VM or cluster of VMs, and exposes methods for managing them. In this page, "VM" refers to both a cluster of virtual machines, as well as a single virtual machine (which is treated as the special case of a cluster containing a single node).
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_template] class:
#' - `new(...)`: Initialize a new VM object. See 'Initialization' for more details.
#' - `start(wait=TRUE)`: Start the VM. By default, wait until the startup process is complete.
#' - `stop(deallocate=TRUE, wait=FALSE)`: Stop the VM. By default, deallocate it as well.
#' - `restart(wait=TRUE)`: Restart the VM.
#' - `run_deployed_command(command, parameters, script)`: Run a PowerShell command on the VM.
#' - `run_script(script, parameters)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `sync_vm_status()`: Update the VM status fields in this object with information from the host.
#' - `resize(size, deallocate=FALSE, wait=FALSE)`: Resize the VM. Optionally deallocate it first (may sometimes be necessary).
#'
#' @section Fields:
#' The following fields are available, in addition to those provided by the `AzureRMR::az_template` class. Each is a list with one element per node in the cluster.
#' - `disks`: The status of any attached disks.
#' - `ip_address`: The IP address. NULL if the node is currently deallocated.
#' - `dns_name`: The fully qualified domain name.
#' - `status`: The status of the node, giving the provisioning state and power state.
#'
#' @details
#' A single virtual machine in Azure is actually a collection of resources, including any and all of the following. A cluster can share a storage account and virtual network, but each individual node will still have its own IP address and network interface.
#' - Storage account
#' - Network interface
#' - Network security group
#' - Virtual network
#' - IP address
#' - The VM itself
#'
#' By wrapping the deployment template used to create these resources, the `az_vm_template` class allows managing them all as a single entity.
#'
#' @section Initialization:
#' Initializing a new object of this class can either retrieve an existing VM template, or deploy a new VM template on the host. Generally, the best way to initialize an object is via the VM-related methods of the [az_subscription] and [az_resource_group] class, which handle the details automatically.
#'
#' A new VM can be created in _exclusive_ mode, meaning a new resource group is created solely to hold the VM. This simplifies deleting a VM considerably, as deleting the resource group will also automatically delete all the VM's resources. This can be done asynchronously, meaning that the `delete()` method returns immediately while the process continues on the host. Otherwise, deleting a VM will explicitly delete each of its resources, a task that must be done synchronously to allow for dependencies.
#'
#' @seealso
#' [AzureRMR::az_resource], [create_vm], [create_vm_cluster], [get_vm], [get_vm_cluster], [list_vms],
#' [delete_vm], [delete_vm_cluster],
#' [VM API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines)
#'
#' @examples
#' \dontrun{
#'
#' # recommended way to retrieve a VM: via a resource group or subscription object
#' sub <- AzureRMR::az_rm$
#'     new(tenant="myaadtenant.onmicrosoft.com", app="app_id", password="password")$
#'     get_subscription("subscription_id")
#'
#' vm <- sub$get_vm("myLinuxDSVM")
#'
#' # start the VM
#' vm$start()
#'
#' # run a shell command
#' vm$run_script("ifconfig > /tmp/ifc.out")
#'
#' # stop (and deallocate) the VM
#' vm$stop()
#'
#' # resize the VM
#' vm$resize("Standard_DS13_v2")
#'
#' # get the VM status
#' vm$sync_vm_status()
#'
#' }
#' @format An R6 object of class `az_vm_template`, inheriting from `AzureRMR::az_template`.
#' @export
az_vm_template <- R6::R6Class("az_vm_template", inherit=az_template,

public=list(
    dns_name=NULL,

    initialize=function(token, subscription, resource_group, name, ..., wait=TRUE)
    {
        super$initialize(token, subscription, resource_group, name, ..., wait=wait)

        if(wait)
        {
            private$vm <- az_vm_resource$new(self$token, self$subscription, id=self$properties$outputs$vmResource$value)

            # get the hostname/IP address for the VM
            outputs <- unlist(self$properties$outputResources)
            ip_id <- grep("publicIPAddresses/.+$", outputs, ignore.case=TRUE, value=TRUE)

            if(!is_empty(ip_id))
            {
                ip <- az_resource$new(self$token, self$subscription, id=ip_id)
                self$dns_name <- ip$properties$dnsSettings$fqdn
            }
        }
        else message("Deployment started. Call the sync_vm_status() method to track the status of the deployment.")
    },

    delete=function(confirm=TRUE, free_resources=TRUE)
    {
        # must reorder template output resources so that freeing resources will work
        private$reorder_for_delete()
        super$delete(confirm=confirm, free_resources=free_resources)
    },

    print=function(...)
    {
        cat("<Azure virtual machine ", self$name, ">\n", sep="")

        osProf <- names(private$vm$properties$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"
        exclusive <- self$properties$mode == "Complete"
        status <- if(is_empty(private$vm$status))
            "<unknown>"
        else paste0(names(private$vm$status), "=", private$vm$status, collapse=", ")

        cat("  Operating system:", os, "\n")
        cat("  Exclusive resource group:", exclusive, "\n")
        cat("  Domain name:", self$dns_name, "\n")
        cat("  Status:", status, "\n")
        cat("---\n")

        exclude <- c("subscription", "resource_group", "name", "dns_name")

        cat(AzureRMR::format_public_fields(self, exclude=exclude))
        cat(AzureRMR::format_public_methods(self))
        invisible(NULL)
    }
),

# propagate resource methods up to template
active=list(

    sync_vm_status=function()
    private$vm$sync_vm_status,

    start=function()
    private$vm$start,

    stop=function()
    private$vm$stop,

    restart=function()
    private$vm$restart,

    add_extension=function()
    private$vm$add_extension,

    resize=function()
    private$vm$resize,

    run_deployed_command=function()
    private$vm$run_deployed_command,

    run_script=function()
    private$vm$run_script,

    get_public_ip_address=function()
    private$vm$get_public_ip_address,

    get_private_ip_address=function()
    private$vm$get_private_ip_address,

    do_vm_operation=function()
    private$vm$do_operation
),

private=list(
    vm=NULL,

    reorder_for_delete=function()
    {
        is_type <- function(id, type)
        {
            grepl(type, id, fixed=TRUE)
        }
        new_order <- sapply(self$properties$outputResources, function(x)
        {
            id <- x$id
            if(is_type(id, "Microsoft.Compute/virtualMachines")) 1
            else if(is_type(id, "Microsoft.Network/networkInterfaces")) 2
            else if(is_type(id, "Microsoft.Network/virtualNetworks")) 3
            else if(is_type(id, "Microsoft.Network/publicIPAddresses")) 4
            else if(is_type(id, "Microsoft.Network/networkSecurityGroups")) 5
            else 0 # delete all other resources first
        })
        self$properties$outputResources <- self$properties$outputResources[order(new_order)]
    }
))

