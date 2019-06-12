#' Virtual machine scaleset (cluster) template class
#'
#' Class representing a virtual machine scaleset deployment template. This class keeps track of all resources that are created as part of deploying a scaleset, and exposes methods for managing them.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_template] class.
#' - `sync_vmss_status`: Check the status of the scaleset.
#' - `list_instances()`: Return a list of [az_vm_resource] objects, one for each VM instance in the scaleset. Note that if the scaleset has a load balancer attached, the number of instances will vary depending on the load.
#' - `get_instance(id)`: Return a specific VM instance in the scaleset.
#' - `start(id=NULL, wait=FALSE)`: Start the scaleset. In this and the other methods listed here, `id` can be an optional character vector of instance IDs; if supplied, only carry out the operation for those instances.
#' - `restart(id=NULL, wait=FALSE)`: Restart the scaleset.
#' - `stop(deallocate=TRUE, id=NULL, wait=FALSE)`: Stop the scaleset.
#' - `get_public_ip_address()`: Get the public IP address of the scaleset (technically, of the load balancer). If the scaleset doesn't have a load balancer attached, returns NULL.
#' - `get_vm_public_ip_addresses(id=NULL, nic=1, config=1)`: Get the public IP addresses for the instances in the scaleset. Returns NULL if the instances are not publicly accessible.
#' - `get_vm_private_ip_addresses(id=NULL, nic=1, config=1)`: Get the private IP addresses for the instances in the scaleset.
#' - `run_deployed_command(command, parameters=NULL, script=NULL, id=NULL)`: Run a PowerShell command on the instances in the scaleset.
#' - `run_script(script, parameters=NULL, id=NULL)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `reimage(id=NULL, datadisks=FALSE)`: Reimage the instances in the scaleset. If `datadisks` is TRUE, reimage any attached data disks as well.
#' - `redeploy(id=NULL)`: Redeploy the instances in the scaleset.
#' - `mapped_vm_operation(..., id=NULL)`: Carry out an arbitrary operation on the instances in the scaleset. See the `do_operation` method of the [AzureRMR::az_resource] class for more details.
#' - `add_extension(publisher, type, version, settings=list(), protected_settings=list(), key_vault_settings=list())`: Add an extension to the scaleset.
#' - `do_vmss_operation(...)` Carry out an arbitrary operation on the scaleset resource (as opposed to the instances in the scaleset).
#'
#' @details
#' A virtual machine scaleset in Azure is actually a collection of resources, including any and all of the following.
#' - Network security group (Azure resource type `Microsoft.Network/networkSecurityGroups`)
#' - Virtual network (Azure resource type `Microsoft.Network/virtualNetworks`)
#' - Load balancer (Azure resource type `Microsoft.Network/loadBalancers`)
#' - Public IP address (Azure resource type `Microsoft.Network/publicIPAddresses`)
#' - Autoscaler (Azure resource type `Microsoft.Insights/autoscaleSettings`)
#' - The scaleset itself (Azure resource type `Microsoft.Compute/virtualMachineScaleSets`)
#'
#' By wrapping the deployment template used to create these resources, the `az_vmss_template` class allows managing them all as a single entity.
#'
#' @seealso
#' [AzureRMR::az_template], [create_vm_scaleset], [get_vm_scaleset], [delete_vm_scaleset]
#'
#' [VM scaleset API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachinescalesets)
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")
#'
#' vmss <- sub$get_vm_scaleset("myscaleset")
#'
#' # start the VM
#' vmss$start()
#'
#' # run a shell command
#' vmss$run_script("ifconfig > /tmp/ifc.out")
#'
#' # get private IP addresses
#' vmss$get_vm_private_ip_addresses()
#'
#' # get the VM status
#' vmss$sync_vmss_status()
#'
#' }
#' @format An R6 object of class `az_vmss_template`, inheriting from `AzureRMR::az_template`.
#' @export
az_vmss_template <- R6::R6Class("az_vmss_template", inherit=az_template,

public=list(
    dns_name=NULL,

    initialize=function(token, subscription, resource_group, name, ..., wait=TRUE)
    {
        super$initialize(token, subscription, resource_group, name, ..., wait=wait)

        if(wait)
        {
            private$vmss <- az_vmss_resource$new(self$token, self$subscription,
                id=self$properties$outputs$vmResource$value)

            # get the hostname/IP address for the VM
            outputs <- unlist(self$properties$outputResources)
            ip_id <- grep("publicIPAddresses/.+$", outputs, ignore.case=TRUE, value=TRUE)
            if(!is_empty(ip_id))
            {
                ip <- az_resource$new(self$token, self$subscription, id=ip_id)
                self$dns_name <- ip$properties$dnsSettings$fqdn
            }
        }
        else message("Deployment started. Call the sync_vmss_status() method to track the status of the deployment.")
    },

    delete=function(confirm=TRUE, free_resources=TRUE)
    {
        # must reorder template output resources so that freeing resources will work
        private$reorder_for_delete()
        super$delete(confirm=confirm, free_resources=free_resources)
    },

    print=function(...)
    {
        cat("<Azure virtual machine scaleset ", self$name, ">\n", sep="")

        osProf <- names(private$vmss$properties$virtualMachineProfile$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"
        exclusive <- self$properties$mode == "Complete"

        cat("  Operating system:", os, "\n")
        cat("  Exclusive resource group:", exclusive, "\n")
        cat("  Domain name:", self$dns_name, "\n")
        cat("  Status:\n")
        if(is_empty(private$vmss$status))
            cat("    <unknown>\n")
        else
        {
            status <- head(private$vmss$status)
            row.names(status) <- paste0("     ", row.names(status))
            print(status)
            if(nrow(private$vmss$status) > nrow(status))
            cat("    ...\n")
        }
        cat("---\n")

        exclude <- c("subscription", "resource_group", "name", "dns_name")

        cat(AzureRMR::format_public_fields(self, exclude=exclude))
        cat(AzureRMR::format_public_methods(self))
        invisible(NULL)
    },

    get_public_ip_address=function()
    {
        outputs <- unlist(self$properties$outputResources)
        ip_id <- grep("publicIPAddresses/.+$", outputs, ignore.case=TRUE, value=TRUE)
        if(!is_empty(ip_id))
        {
            ip <- az_resource$new(self$token, self$subscription, id=ip_id)
            ip$properties$ipAddress
        }
        else NULL
    }),

# propagate resource methods up to template
active=list(

    sync_vmss_status=function()
    private$vmss$sync_vmss_status,

    list_instances=function()
    private$vmss$list_instances,

    get_instance=function()
    private$vmss$get_instance,

    start=function()
    private$vmss$start,

    stop=function()
    private$vmss$stop,

    restart=function()
    private$vmss$restart,

    get_vm_public_ip_addresses=function()
    private$vmss$get_vm_public_ip_addresses,

    get_vm_private_ip_addresses=function()
    private$vmss$get_vm_private_ip_addresses,

    run_deployed_command=function()
    private$vmss$run_deployed_command,

    run_script=function()
    private$vmss$run_script,

    reimage=function()
    private$vmss$reimage,

    redeploy=function()
    private$vmss$redeploy,

    mapped_vm_operation=function()
    private$vmss$mapped_vm_operation,

    add_extension=function()
    private$vmss$add_extension,

    do_vmss_operation=function()
    private$vmss$do_operation
),

private=list(
    vmss=NULL,

    reorder_for_delete=function()
    {
        is_type <- function(id, type)
        {
            grepl(type, id, fixed=TRUE)
        }
        new_order <- sapply(self$properties$outputResources, function(x)
        {
            id <- x$id
            if(is_type(id, "Microsoft.Compute/virtualMachineScaleSets")) 1
            else if(is_type(id, "Microsoft.Insights/autoscaleSettings")) 2
            else if(is_type(id, "Microsoft.Network/loadBalancers")) 3
            else if(is_type(id, "Microsoft.Network/publicIPAddresses")) 4
            else if(is_type(id, "Microsoft.Network/virtualNetworks")) 5
            else if(is_type(id, "Microsoft.Network/networkSecurityGroups")) 6
            else 0
        })
        self$properties$outputResources <- self$properties$outputResources[order(new_order)]
    }
))
