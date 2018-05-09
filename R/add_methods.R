## extend subscription methods
AzureRMR::az_subscription$set("public", "list_vm_sizes", function(location, all_info=TRUE)
{
    provider <- "Microsoft.Compute"
    path <- "locations"
    api_version <- self$get_provider_api_version(provider, path)

    op <- file.path("providers", provider, path, location, "vmSizes")
    res <- call_azure_rm(self$token, self$id, op, api_version=api_version)

    if(all_info)
        do.call(rbind, lapply(res$value, data.frame, stringsAsFactors=FALSE))
    else lapply(res$value, `[[`, "name")
})


AzureRMR::az_subscription$set("public", "create_vm", function(name, location, ..., resource_group=name)
{
    if(is_resource_group(resource_group))
    {
        if(missing(location))
            location <- resource_group$location
        resource_group <- resource_group$name
    }

    rgnames <- names(self$list_resource_groups())
    exclusive_group <- !(resource_group %in% rgnames)
    if(exclusive_group)
    {
        message("Creating resource group '", resource_group, "'")
        self$create_resource_group(resource_group, location=location)
    }
    az_vm_template$new(self$token, self$id, resource_group, name, location, ..., exclusive_group=exclusive_group)
})


AzureRMR::az_subscription$set("public", "get_vm", function(name, resource_group=name)
{
    if(!is_resource_group(resource_group))
        resource_group <- self$get_resource_group(resource_group)

    resource_group$get_vm(name)
})


AzureRMR::az_subscription$set("public", "delete_vm", function(name, confirm=TRUE, free_resources=TRUE,
    resource_group=vm_name)
{
    if(!is_resource_group(resource_group))
        resource_group <- self$get_resource_group(resource_group)

    resource_group$delete_vm(name, confirm=confirm, free_resources=free_resources)
})


##
## extend resource group methods
AzureRMR::az_resource_group$set("public", "create_vm", function(name, location, ...)
{
    az_vm_template$new(self$token, self$subscription, self$name, name, location, ...)
})


AzureRMR::az_resource_group$set("public", "get_vm", function(name)
{
    az_vm_template$new(self$token, self$id, name)
})


AzureRMR::az_resource_group$set("public", "delete_vm", function(name, confirm=TRUE, free_resources=TRUE)
{
    self$get_vm(name)$delete(confirm=confirm, free_resources=free_resources)
})


#' @export
list_vm_sizes <- function(token, subscription, location, all_info=TRUE)
{
    AzureRMR::az_subscription$new(token, subscription)$list_vm_sizes(location, all_info)
}
