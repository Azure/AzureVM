#' @export
az_vmss_template <- R6::R6Class("az_vmss_template", inherit=az_template,

public=list(
    dns_name=NULL,

    initialize=function(token, subscription, resource_group, name, ..., wait=TRUE)
    {
        super$initialize(token, subscription, resource_group, name, ..., wait=wait)

        if(wait)
        {
            private$vm <- az_vmss_resource$new(self$token, self$subscription,
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

    sync_vmss_status=function()
    private$vm$sync_vmss_status,

    list_instances=function()
    private$vm$list_instances,

    get_instance=function()
    private$vm$get_instance,

    start=function()
    private$vm$start,

    stop=function()
    private$vm$stop,

    restart=function()
    private$vm$restart,

    add_extension=function()
    private$vm$add_extension,

    redeploy=function()
    private$vm$redeploy,

    reimage=function()
    private$vm$reimage,

    run_deployed_command=function()
    private$vm$run_deployed_command,

    run_script=function()
    private$vm$run_script,

    get_load_balancer_address=function()
    private$vm$get_load_balancer_address,

    get_public_ip_addresses=function()
    private$vm$get_public_ip_addresses,

    get_private_ip_addresses=function()
    private$vm$get_private_ip_addresses,

    do_vmss_operation=function()
    private$vm$do_operation
),

private=list(
    vm=NULL
))
