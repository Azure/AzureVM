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
    private$mapped_vm_operation,

    add_extension=function()
    private$vmss$add_extension,

    do_vmss_operation=function()
    private$vmss$do_operation
),

private=list(
    vmss=NULL
))
