# documentation is separate from implementation because roxygen still doesn't know how to handle R6

#' List available VM sizes
#'
#' Method for the [AzureRMR::az_subscription] class.
#'
#' @rdname list_vm_sizes
#' @name list_vm_sizes
#' @usage
#' list_vm_sizes(location, name_only=FALSE)
#'
#' @param location The location/region for which to obtain available VM sizes.
#' @param name_only Whether to return only a vector of names, or all information on each VM size.
#'
#' @return
#' If `name_only` is TRUE, a character vector of names, suitable for passing to `create_vm`. If FALSE, a data frame containing the following information for each VM size: the name, number of cores, OS disk size, resource disk size, memory, and maximum data disks.
#'
#' @seealso
#' [create_vm]
NULL


#' Get existing virtual machine(s)
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @rdname get_vm
#' @name get_vm
#' @aliases list_vms
#' @usage
#' get_vm(name, resource_group=name)
#' get_vm(name)
#' list_vms()
#'
#' @param name The name of the VM.
#' @param resource_group For the `az_subscription` method, the resource group in which `get_vm()` will look for the VM. Defaults to the VM name.
#'
#' @details
#' The `get_vm()` method first instantiates an object of class `az_vm_resource`, which wraps the raw VM resource of the given name. It then searches for a deployment template of the same name, with which to instantiate an object of class `az_vm_template`. This allows managing all resources that were created as part of the deployment: storage account, IP address, network interface, etc.
#'
#' The `list_vms()` method does the same, but for all VMs in either the subscription or resource group as appropriate.
#'
#' @return
#' For `get_vm()`, an object representing the VM, either of class `az_vm_template` or `az_vm_resource`. If the latter, a warning is thrown as well.
#'
#' For `list_vms()`, a list of such objects.
#'
#' @seealso
#' [az_vm_template], [az_vm_resource],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
NULL


#' Create a new virtual machine
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @rdname create_vm
#' @name create_vm
#' @usage
#' create_vm(name, location, os=c("Windows", "Ubuntu"), size="Standard_DS3_v2",
#'           username, passkey, userauth_type=c("password", "key"),
#'           template, parameters, ..., wait=TRUE)
#'
#' @param name The VM name.
#' @param location The location for the VM. Use the `list_locations()` method of the `AzureRMR::az_subscription` class to see what locations are available.
#' @param os The operating system for the VM.
#' @param size The VM size. Use the `list_vm_sizes()` method of the `AzureRMR::az_subscription` class to see what sizes are available.
#' @param username The login username for the VM.
#' @param passkey The login password or public key.
#' @param userauth_type The type of login authentication to use. Only has an effect for Linux-based VMs; Windows VMs will always use `"password"`.
#' @param template Optional: the VM template to deploy. By default, this is determined by the values of the other arguments; see 'Details' below.
#' @param parameters Optional: other parameters to pass to the deployment.
#' @param wait Whether to wait until the deployment is complete.
#'
#' @details
#' This method deploys a template to create a new virtual machine. Currently, three VM templates are supplied with this package, based on the Azure Data Science Virtual Machine:
#' - Ubuntu DSVM
#' - Ubuntu DSVM using public key authentication
#' - Windows Server 2016 DSVM
#'
#' You can also supply your own VM template for deployment, via the `template` argument. See [AzureRMR::az_template] for information how to supply templates for deployment. Note that if you do this, you may also have to supply a `parameters` argument, as the standard parameters for this method are customised for the DSVM.
#'
#' For the `AzureRMR::az_subscription` method, this will by default create the VM in _exclusive_ mode, meaning a new resource group is created solely to hold the VM. This simplifies managing the VM considerably, in particular deleting the resource group will also automatically delete all the VM's resources.
#'
#' @return
#' An object of class `az_vm_template` representing the created VM.
#'
#' @seealso
#' [az_vm_template],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group],
#' [Data Science Virtual Machine](https://azure.microsoft.com/en-us/services/virtual-machines/data-science-virtual-machines/)
NULL


#' Delete virtual machine
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @rdname delete_vm
#' @name delete_vm
#' @usage
#' delete_vm(name, confirm=TRUE, free_resources=TRUE)
#' delete_vm(name, confirm=TRUE, free_resources=TRUE, resource_group=name)
#'
#' @param name The VM name.
#' @param confirm Whether to confirm the delete.
#' @param free_resources If the VM is a deployed template, whether to free all resources created during the deployment process.
#' @param resource_group For the `AzureRMR::az_subscription` method, the resource group containing the VM.
#'
#' @details
#' If the VM is of class [az_vm_template] and was created in exclusive mode, this method deletes the entire resource group containing the VM. This automatically frees all resources that were created during the deployment process. Otherwise, if `free_resources=TRUE`, it manually deletes each individual resource in turn. This is done synchronously (the method does not return until the deletion is complete) to allow for dependencies.
#'
#' If the VM is of class [az_vm_resource], this method only deletes the VM resource itself, not any other resources it may depend on.
#'
#' @seealso
#' [create_vm], [az_vm_template], [az_vm_resource],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
NULL


# adding methods to classes in external package must go in .onLoad
.onLoad <- function(libname, pkgname)
{
    ## extend subscription methods
    AzureRMR::az_subscription$set("public", "list_vm_sizes", function(location, name_only=FALSE)
    {
        provider <- "Microsoft.Compute"
        path <- "locations"
        api_version <- self$get_provider_api_version(provider, path)

        op <- file.path("providers", provider, path, location, "vmSizes")
        res <- call_azure_rm(self$token, self$id, op, api_version=api_version)

        if(!name_only)
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
    resource_group=name)
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
}


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

