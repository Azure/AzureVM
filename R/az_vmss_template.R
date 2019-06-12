#' Virtual machine scaleset (cluster) template class
#'
#' Class representing a virtual machine scaleset template.
#' @docType class
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

    get_vm_public_ip_addresses=function(nic=1, config=1)
    private$vmss$get_vm_public_ip_addresses,

    get_vm_private_ip_addresses=function(nic=1, config=1)
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
