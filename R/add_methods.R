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
    else sapply(res$value, `[[`, "name")
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
        mode <- "Complete"
    }
    else mode <- "Incremental"
    az_vm_template$new(self$token, self$id, resource_group, name, location, ..., mode=mode)
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


AzureRMR::az_subscription$set("public", "list_vms", function()
{
    provider <- "Microsoft.Compute"
    path <- "virtualMachines"
    api_version <- self$get_provider_api_version(provider, path)

    op <- file.path("providers", provider, path)

    cont <- call_azure_rm(self$token, self$id, op, api_version=api_version)
    lst <- lapply(cont$value,
        function(parms) az_vm_resource$new(self$token, self$id, deployed_properties=parms))
    # keep going until paging is complete
    while(!is_empty(cont$nextLink))
    {
        cont <- call_azure_url(self$token, cont$nextLink)
        lst <- lapply(cont$value,
            function(parms) az_vm_resource$new(self$token, self$id, deployed_properties=parms))
    }

    # get templates corresponding to raw VMs (if possible)
    lapply(named_list(lst), convert_to_vm_template)
})


##
## extend resource group methods
AzureRMR::az_resource_group$set("public", "create_vm", function(name, location, ...)
{
    az_vm_template$new(self$token, self$subscription, self$name, name, location, ...)
})


AzureRMR::az_resource_group$set("public", "get_vm", function(name)
{
    res <- try(az_vm_template$new(self$token, self$subscription, self$name, name), silent=TRUE)

    # if we couldn't find a VM deployment template, get the raw VM resource
    if(inherits(res, "try-error"))
    {
        warning("No deployment template found for VM '", name, "'", call.=FALSE)
        res <- az_vm_resource$new(self$token, self$subscription, self$name,
            type="Microsoft.Compute/virtualMachines", name=name)
    }
    res
})


AzureRMR::az_resource_group$set("public", "delete_vm", function(name, confirm=TRUE, free_resources=TRUE)
{
    vm <- self$get_vm(name)
    if(is_vm_template(vm))
        vm$delete(confirm=confirm, free_resources=free_resources)
    else vm$delete(confirm=confirm)
})


AzureRMR::az_resource_group$set("public", "list_vms", function()
{
    provider <- "Microsoft.Compute"
    path <- "virtualMachines"
    api_version <- az_subscription$
        new(self$token, self$subscription)$
        get_provider_api_version(provider, path)

    op <- file.path("resourceGroups", self$name, "providers", provider, path)

    cont <- call_azure_rm(self$token, self$subscription, op, api_version=api_version)
    lst <- lapply(cont$value,
        function(parms) az_vm_resource$new(self$token, self$subscription, deployed_properties=parms))

    # keep going until paging is complete
    while(!is_empty(cont$nextLink))
    {
        cont <- call_azure_url(self$token, cont$nextLink)
        lst <- lapply(cont$value,
            function(parms) az_vm_resource$new(self$token, self$subscription, deployed_properties=parms))
    }

    # get templates corresponding to raw VMs (if possible)
    lapply(named_list(lst), convert_to_vm_template)
})


convert_to_vm_template <- function(vm_resource)
{
    token <- vm_resource$token
    subscription <- vm_resource$subscription
    resource_group <- vm_resource$resource_group
    name <- vm_resource$name

    tpl <- try(az_vm_template$new(token, subscription, resource_group, name), silent=TRUE)
    if(!inherits(tpl, "try-error") &&
       !is_empty(tpl$properties$outputResources) &&
       grepl(sprintf("providers/Microsoft.Compute/virtualMachines/%s$", name),
             tpl$properties$outputResources[[1]]$id, ignore.case=TRUE))
        tpl
    else
    {
        warning("No deployment template found for VM '", name, "'", call.=FALSE)
        vm_resource
    }
}

