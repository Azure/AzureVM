#' Virtual machine template class
#'
#' Class representing a virtual machine deployment template. This class keeps track of all resources that are created as part of deploying a VM, and exposes methods for managing them.
#'
#' @docType class
#' @section Fields:
#' The following fields are exposed, in addition to those provided by the [AzureRMR::az_template] class.
#' - `dns_name`: The DNS name for the VM. Will be NULL if the VM is not publicly visible, or doesn't have a domain name assigned to its public IP address.
#' - `identity`: The managed identity details for the VM. Will be NULL if the VM doesn't have an identity assigned.
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_template] class.
#' - `start(wait=TRUE)`: Start the VM. By default, wait until the startup process is complete.
#' - `stop(deallocate=TRUE, wait=FALSE)`: Stop the VM. By default, deallocate it as well.
#' - `restart(wait=TRUE)`: Restart the VM.
#' - `run_deployed_command(command, parameters, script)`: Run a PowerShell command on the VM.
#' - `run_script(script, parameters)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `sync_vm_status()`: Check the status of the VM.
#' - `resize(size, deallocate=FALSE, wait=FALSE)`: Resize the VM. Optionally stop and deallocate it first (may sometimes be necessary).
#' - `redeploy()`: Redeploy the VM.
#' - `reimage()`: Reimage the VM.
#' - `get_public_ip_address(nic=1, config=1)`: Get the public IP address of the VM. Returns NA if the VM is stopped, or is not publicly accessible.
#' - `get_private_ip_address(nic=1, config=1)`: Get the private IP address of the VM.
#' - `add_extension(publisher, type, version, settings=list(), protected_settings=list(), key_vault_settings=list())`: Add an extension to the VM.
#' - `do_vm_operation(...)`: Carries out an arbitrary operation on the VM resource. See the `do_operation` method of the [AzureRMR::az_resource] class for more details.
#'
#' @details
#' The VM operations listed above are actually provided by the [az_vm_resource] class, and propagated to the template as active bindings.
#'
#' A single virtual machine in Azure is actually a collection of resources, including any and all of the following.
#' - Network interface (Azure resource type `Microsoft.Network/networkInterfaces`)
#' - Network security group (Azure resource type `Microsoft.Network/networkSecurityGroups`)
#' - Virtual network (Azure resource type `Microsoft.Network/virtualNetworks`)
#' - Public IP address (Azure resource type `Microsoft.Network/publicIPAddresses`)
#' - The VM itself (Azure resource type `Microsoft.Compute/virtualMachines`)
#'
#' By wrapping the deployment template used to create these resources, the `az_vm_template` class allows managing them all as a single entity.
#'
#' @seealso
#' [AzureRMR::az_template], [create_vm], [get_vm], [delete_vm]
#'
#' [VM API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines)
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")
#'
#' vm <- sub$get_vm("myvm")
#'
#' vm$identity
#'
#' vm$start()
#' vm$get_private_ip_address()
#' vm$get_public_ip_address()
#'
#' vm$run_script("echo hello world! > /tmp/hello.txt")
#'
#' vm$stop()
#' vm$get_private_ip_address()
#' vm$get_public_ip_address()  # NA, assuming VM has a dynamic IP address
#'
#' vm$resize("Standard_DS13_v2")
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

    identity=function()
    private$vm$identity,

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

    get_public_ip_resource=function()
    private$vm$get_public_ip_resource,

    get_nic=function()
    private$vm$get_nic,

    get_vnet=function()
    private$vm$get_vnet,

    get_nsg=function()
    private$vm$get_nsg,

    get_disk=function()
    private$vm$get_disk,

    redeploy=function()
    private$vm$redeploy,

    reimage=function()
    private$vm$reimage,

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

        # insert managed disks into deletion queue
        stor <- private$vm$properties$storageProfile
        managed_disks <- c(
            stor$osDisk$managedDisk$id,
            lapply(stor$dataDisks, function(x) x$managedDisk$id)
        )
        outs <- unique(c(unlist(self$properties$outputResources), unlist(managed_disks)))

        new_order <- sapply(outs, function(id)
        {
            if(is_type(id, "Microsoft.Compute/virtualMachines")) 1
            else if(is_type(id, "Microsoft.Compute/disks")) 2
            else if(is_type(id, "Microsoft.Network/networkInterfaces")) 3
            else if(is_type(id, "Microsoft.Network/virtualNetworks")) 4
            else if(is_type(id, "Microsoft.Network/publicIPAddresses")) 5
            else if(is_type(id, "Microsoft.Network/networkSecurityGroups")) 6
            else 0 # delete all other resources first
        })

        outs <- outs[order(new_order)]
        self$properties$outputResources <- lapply(outs, function(x) list(id=x))
    }
))

