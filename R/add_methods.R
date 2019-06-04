# documentation is separate from implementation because roxygen still doesn't know how to handle R6

#' List available VM sizes
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @section Usage:
#' ```
#' ## R6 method for class 'az_subscription'
#' list_vm_sizes(location, name_only = FALSE)
#'
#' ## R6 method for class 'az_resource_group'
#' list_vm_sizes(name_only = FALSE)
#' ```
#' @section Arguments:
#' - `location`: For the subscription class method, the location/region for which to obtain available VM sizes.
#' - `name_only`: Whether to return only a vector of names, or all information on each VM size.
#'
#' @section Value:
#' If `name_only` is TRUE, a character vector of names, suitable for passing to `create_vm`. If FALSE, a data frame containing the following information for each VM size: the name, number of cores, OS disk size, resource disk size, memory, and maximum data disks.
#'
#' @seealso
#' [create_vm]
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::az_rm$
#'     new(tenant="myaadtenant.onmicrosoft.com", app="app_id", password="password")$
#'     get_subscription("subscription_id")
#'
#' sub$list_vm_sizes("australiaeast")
#'
#' # same output as above
#' rg <- sub$create_resource_group("rgname", location="australiaeast")
#' rg$list_vm_sizes()
#'
#' }
#' @rdname list_vm_sizes
#' @aliases list_vm_sizes
#' @name list_vm_sizes
NULL


#' Get existing virtual machine(s)
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @section Usage:
#' ```
#' ## R6 method for class 'az_subscription'
#' get_vm(name, resource_group = name)
#'
#' ## R6 method for class 'az_resource_group'
#' get_vm(name)
#'
#' ## R6 method for class 'az_subscription'
#' get_vm_cluster(name, resource_group = name)
#'
#' ## R6 method for class 'az_resource_group'
#' get_vm_cluster(name)
#'
#' ## R6 method for class 'az_resource_group'
#' ## R6 method for class 'az_subscription'
#' list_vms()
#' ```
#' @section Arguments:
#' - `name`: The name of the VM or cluster.
#' - `resource_group`: For the `az_subscription` method, the resource group in which `get_vm()` will look for the VM. Defaults to the VM name.
#'
#' @section Details:
#' Despite the names, `get_vm` and `get_vm_cluster` can both be used to retrieve individual VMs and clusters. The main difference is in their behaviour if a deployment template is not found. In the case of `get_vm`, it also searches for a raw VM resource of the given name, whereas `get_vm_cluster` will throw an error immediately.
#'
#' @section Value:
#' For `get_vm()`, an object representing the VM, either of class `az_vm_template` or `az_vm_resource`.
#'
#' For `list_vms()`, a list of such objects.
#'
#' For `get_vm_cluster()`, an object representing the cluster.
#'
#' @seealso
#' [az_vm_template], [az_vm_resource],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
#'
#' @examples
#' \dontrun{
#' 
#' sub <- AzureRMR::az_rm$
#'     new(tenant="myaadtenant.onmicrosoft.com", app="app_id", password="password")$
#'     get_subscription("subscription_id")
#'
#' sub$list_vms()
#' sub$get_vm("myVirtualMachine")
#'
#' rg <- sub$get_resource_group("rgname")
#' rg$get_vm("myOtherVirtualMachine")
#' 
#' }
#' @rdname get_vm
#' @aliases get_vm get_vm_cluster list_vms
#' @name get_vm
NULL


#' Create a new virtual machine or cluster of virtual machines
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @section Usage:
#' ```
#' ## R6 method for class 'az_resource_group'
#' create_vm(name, os = c("Windows", "Ubuntu"), size = "Standard_DS3_v2",
#'           username, passkey, userauth_type = c("password", "key"),
#'           ext_file_uris = NULL, inst_command = NULL,
#'           template, parameters, ..., wait = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' create_vm(name, location, os = c("Windows", "Ubuntu"), size = "Standard_DS3_v2",
#'           username, passkey, userauth_type = c("password", "key"),
#'           ext_file_uris = NULL, inst_command = NULL,
#'           template, parameters, ..., wait = TRUE)
#'
#' ## R6 method for class 'az_resource_group'
#' create_vm_cluster(name, os = c("Windows", "Ubuntu"), size = "Standard_DS3_v2",
#'                   username, passkey, userauth_type = c("password", "key"),
#'                   ext_file_uris = NULL, inst_command = NULL, clust_size,
#'                   template, parameters, ..., wait = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' create_vm_cluster(name, location, os = c("Windows", "Ubuntu"), size = "Standard_DS3_v2",
#'                   username, passkey, userauth_type = c("password", "key"),
#'                   ext_file_uris = NULL, inst_command = NULL, clust_size,
#'                   template, parameters, ..., wait = TRUE)

#' ```
#' @section Arguments:
#' - `name`: The name of the VM or cluster.
#' - `location`: For the subscription class methods, the location for the VM. Use the `list_locations()` method of the `AzureRMR::az_subscription` class to see what locations are available.
#' - `os`: The operating system for the VM.
#' - `size`: The VM size. Use the `list_vm_sizes()` method of the `AzureRMR::az_subscription` class to see what sizes are available.
#' - `username`: The login username for the VM.
#' - `passkey`: The login password or public key.
#' - `userauth_type`: The type of login authentication to use. Only has an effect for Linux-based VMs; Windows VMs will always use `"password"`.
#' - `ext_file_uris`: Optional link to download extension packages.
#' - `inst_command`: If `ext_file_uris` is supplied, the install script to run. Defaults to `install.sh` for an Ubuntu VM, or `install.ps1` for a Windows VM.
#' - `clust_size`: For a cluster, the number of nodes to create.
#' - `template`: Optional: the VM template to deploy. By default, this is determined by the values of the other arguments; see 'Details' below.
#' - `parameters`: Optional: other parameters to pass to the deployment.
#' - `wait`: Whether to wait until the deployment is complete.
#' - `...`: Other arguments to lower-level methods.
#'
#' @section Details:
#' This method deploys a template to create a new virtual machine or cluster of VMs. Currently, seven templates are supplied with this package, based on the Azure Data Science Virtual Machine:
#' - Ubuntu DSVM
#' - Ubuntu DSVM using public key authentication
#' - Ubuntu DSVM with extensions
#' - Ubuntu DSVM cluster
#' - Ubuntu DSVM cluster with extensions
#' - Windows Server 2016 DSVM
#' - Windows Server 2016 DSVM cluster with extensions
#'
#' An individual virtual machine is treated as a cluster containing only a single node.
#'
#' You can also supply your own VM template for deployment, via the `template` argument. See [AzureRMR::az_template] for information how to supply templates. Note that if you do this, you may also have to supply a `parameters` argument, as the standard parameters for this method are customised for the DSVM.
#'
#' For the `AzureRMR::az_subscription` method, this will by default create the VM in _exclusive_ mode, meaning a new resource group is created solely to hold the VM. This simplifies managing the VM considerably, in particular deleting the resource group will also automatically delete all the VM's resources.
#'
#' @section Value:
#' An object of class `az_vm_template` representing the created VM.
#'
#' @seealso
#' [az_vm_template],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group],
#' [Data Science Virtual Machine](https://azure.microsoft.com/en-us/services/virtual-machines/data-science-virtual-machines/)
#'
#' @examples
#' \dontrun{
#' 
#' sub <- AzureRMR::az_rm$
#'     new(tenant="myaadtenant.onmicrosoft.com", app="app_id", password="password")$
#'     get_subscription("subscription_id")
#'
#' # default Windows Server DSVM: make sure to use a strong password!
#' sub$create_vm("myWindowsDSVM",
#'    location="australiaeast",
#'    username="ds",
#'    passkey="Password123!")
#'
#' # upsized Linux (Ubuntu) DSVM
#' sub$create_vm("myLinuxDSVM",
#'    location="australiaeast",
#'    os="Linux",
#'    username="ds",
#'    passkey=readLines("~/id_rsa.pub"),
#'    size="Standard_DS13_v2")
#'
#" # Linux cluster with 5 nodes
#' sub$create_vm_cluster("myLinuxCluster",
#'    location="australiaeast",
#'    os="Linux",
#'    username="ds",
#'    passkey=readLines("~/id_rsa.pub"),
#'    clust_size=5)
#'
#' }
#' @rdname create_vm
#' @aliases create_vm create_vm_cluster
#' @name create_vm
NULL


#' Delete virtual machine
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @docType class
#' @section Usage:
#' ```
#' ## R6 method for class 'az_resource_group'
#' delete_vm(name, confirm = TRUE, free_resources = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' delete_vm(name, confirm = TRUE, free_resources = TRUE,
#'           resource_group = name)
#'
#' ## R6 method for class 'az_resource_group'
#' delete_vm_cluster(name, confirm = TRUE, free_resources = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' delete_vm_cluster(name, confirm = TRUE, free_resources = TRUE,
#'                   resource_group = name)
#' ```
#' @section Arguments:
#' - `name`: The name of the VM or cluster.
#' - `confirm`: Whether to confirm the delete.
#' - `free_resources`: If this was a deployed template, whether to free all resources created during the deployment process.
#' - `resource_group`: For the `AzureRMR::az_subscription` method, the resource group containing the VM or cluster.
#'
#' @section Details:
#' If the VM or cluster is of class [az_vm_template] and was created in exclusive mode, this method deletes the entire resource group that it occupies. This automatically frees all resources that were created during the deployment process. Otherwise, if `free_resources=TRUE`, it manually deletes each individual resource in turn. This is done synchronously (the method does not return until the deletion is complete) to allow for dependencies.
#'
#' If the VM is of class [az_vm_resource], this method only deletes the VM resource itself, not any other resources it may depend on.
#'
#' @seealso
#' [create_vm], [az_vm_template], [az_vm_resource],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::az_rm$
#'     new(tenant="myaadtenant.onmicrosoft.com", app="app_id", password="password")$
#'     get_subscription("subscription_id")
#' 
#' sub$delete_vm("myWindowsDSVM")
#' sub$delete_vm("myLinuxDSVM")
#'
#' }
#' @rdname delete_vm
#' @aliases delete_vm delete_vm_cluster
#' @name delete_vm
NULL


# adding methods to classes in external package must go in .onLoad
.onLoad <- function(libname, pkgname)
{
    add_sub_methods()
    add_rg_methods()
}


# extend subscription methods
add_sub_methods <- function()
{
    az_subscription$set("public", "list_vm_sizes", overwrite=TRUE,
    function(location, name_only=FALSE)
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


    az_subscription$set("public", "create_vm", overwrite=TRUE,
    function(name, location, resource_group=name, ...)
    {
        if(!is_resource_group(resource_group))
        {
            rgnames <- names(self$list_resource_groups())
            if(resource_group %in% rgnames)
            {
                resource_group <- self$get_resource_group(resource_group)
                mode <- "Incremental"
            }
            else
            {
                message("Creating resource group '", resource_group, "'")
                resource_group <- self$create_resource_group(resource_group, location=location)
                mode <- "Complete"
            }
        }
        else mode <- "Incremental" # if passed a resource group object, assume it already exists in Azure

        res <- try(resource_group$create_vm(..., mode=mode))

        if(inherits(res, "try-error") && mode == "Complete")
        {
            resource_group$delete(confirm=FALSE)
            stop("Unable to create VM", call.=FALSE)
        }
        res
    })


    az_subscription$set("public", "create_vm_scaleset", overwrite=TRUE,
    function(name, location, resource_group=name, ...)
    {
        if(!is_resource_group(resource_group))
        {
            rgnames <- names(self$list_resource_groups())
            if(resource_group %in% rgnames)
            {
                resource_group <- self$get_resource_group(resource_group)
                mode <- "Incremental"
            }
            else
            {
                message("Creating resource group '", resource_group, "'")
                resource_group <- self$create_resource_group(resource_group, location=location)
                mode <- "Complete"
            }
        }
        else mode <- "Incremental" # if passed a resource group object, assume it already exists in Azure

        res <- try(resource_group$create_vm_scaleset(..., mode=mode))

        if(inherits(res, "try-error") && mode == "Complete")
        {
            resource_group$delete(confirm=FALSE)
            stop("Unable to create VM scaleset", call.=FALSE)
        }
        res
    })


    az_subscription$set("public", "get_vm", overwrite=TRUE,
    function(name, resource_group=name)
    {
        if(!is_resource_group(resource_group))
            resource_group <- self$get_resource_group(resource_group)

        resource_group$get_vm(name)
    })


    az_subscription$set("public", "get_vm_scaleset", overwrite=TRUE,
    function(name, resource_group=name)
    {
        if(!is_resource_group(resource_group))
            resource_group <- self$get_resource_group(resource_group)

        resource_group$get_vm_scaleset(name)
    })

    az_subscription$set("public", "delete_vm", overwrite=TRUE,
    function(name, confirm=TRUE, free_resources=TRUE, resource_group=name)
    {
        if(!is_resource_group(resource_group))
            resource_group <- self$get_resource_group(resource_group)

        resource_group$delete_vm(name, confirm=confirm, free_resources=free_resources)
    })


    az_subscription$set("public", "delete_vm_scaleset", overwrite=TRUE,
    function(name, confirm=TRUE, free_resources=TRUE, resource_group=name)
    {
        if(!is_resource_group(resource_group))
            resource_group <- self$get_resource_group(resource_group)

        resource_group$delete_vm_scaleset(name, confirm=confirm, free_resources=free_resources)
    })


    az_subscription$set("public", "list_vms", overwrite=TRUE, function()
    {
        provider <- "Microsoft.Compute"
        path <- "virtualMachines"
        api_version <- self$get_provider_api_version(provider, path)

        op <- file.path("providers", provider, path)

        cont <- call_azure_rm(self$token, self$id, op, api_version=api_version)
        lst <- lapply(cont$value,
        function(parms) AzureVM::az_vm_resource$new(self$token, self$id, deployed_properties=parms))
        # keep going until paging is complete
        while(!is_empty(cont$nextLink))
        {
            cont <- call_azure_url(self$token, cont$nextLink)
            lst <- lapply(cont$value,
            function(parms) AzureVM::az_vm_resource$new(self$token, self$id, deployed_properties=parms))
        }

        # namespace shenanigans: get unexported function from AzureVM
        convert_to_vm_template <- get("convert_to_vm_template", loadNamespace("AzureVM"))

        # get templates corresponding to raw VMs (if possible)
        lapply(named_list(lst), convert_to_vm_template)
    })
}


# extend resource group methods
add_rg_methods <- function()
{
    az_resource_group$set("public", "create_vm", overwrite=TRUE,
    function(name, login_user, size="Standard_DS3_v2", config="ubuntu_dsvm", managed=TRUE, datadisks=numeric(0),
             ..., template, parameters, mode="Incremental", wait=TRUE)
    {
        stopifnot(inherits(login_user, "user_config"))

        if(is.character(config))
            config <- get(config, getNamespace("AzureVM"))
        if(is.function(config))
            config <- config(!is_empty(login_user$key), managed, datadisks, ...)

        stopifnot(inherits(config, "vm_config"))

        if(missing(template))
            template <- build_template_definition(config)

        if(missing(parameters))
            parameters <- build_template_parameters(config, name, login_user, size)

        AzureVM::az_vm_template$new(self$token, self$subscription, self$name, name,
            template=template, parameters=parameters, mode=mode, wait=wait)
    })


    az_resource_group$set("public", "create_vm_scaleset", overwrite=TRUE,
    function(name, login_user, size="Standard_DS3_v2", config="ubuntu_dsvm_ss", managed=TRUE, datadisks=numeric(0),
             scaleset, ..., template, parameters, mode="Incremental", wait=TRUE)
    {
        stopifnot(inherits(login_user, "user_config"))

        if(is.character(config))
            config <- get(config, getNamespace("AzureVM"))
        if(is.function(config))
            config <- config(!is_empty(login_user$key), managed, datadisks, scaleset, ...)

        stopifnot(inherits(config, "vmss_config"))

        if(missing(template))
            template <- build_template_definition(config)

        if(missing(parameters))
            parameters <- build_template_parameters(config, name, login_user, size, scaleset)

        AzureVM::az_vmss_template$new(self$token, self$subscription, self$name, name,
            template=template, parameters=parameters, mode=mode, wait=wait)
    })


    az_resource_group$set("public", "create_vm_cluster", overwrite=TRUE,
    function(...)
    {
        .Defunct(msg="The 'create_vm_cluster' method is defunct.\nUse 'create_vm_scaleset' instead.")
    })


    az_resource_group$set("public", "get_vm", overwrite=TRUE,
    function(name)
    {
        res <- try(AzureVM::az_vm_template$new(self$token, self$subscription, self$name, name), silent=TRUE)

        # if we couldn't find a VM deployment template, get the raw VM resource
        if(inherits(res, "try-error"))
        {
            warning("No deployment template found for VM '", name, "'", call.=FALSE)
            res <- AzureVM::az_vm_resource$new(self$token, self$subscription, self$name,
            type="Microsoft.Compute/virtualMachines", name=name)
        }
        res
    })


    az_resource_group$set("public", "get_vm_scaleset", overwrite=TRUE,
    function(name)
    {
        AzureVM::az_vmss_template$new(self$token, self$subscription, self$name, name)
    })


    az_resource_group$set("public", "get_vm_cluster", overwrite=TRUE,
    function(...)
    {
        .Defunct(msg="The 'get_vm_cluster' method is defunct.\nUse 'get_vm_scaleset' instead.")
    })


    az_resource_group$set("public", "delete_vm", overwrite=TRUE,
                          function(name, confirm=TRUE, free_resources=TRUE)
    {
        vm <- self$get_vm(name)
        if(is_vm_template(vm))
            vm$delete(confirm=confirm, free_resources=free_resources)
        else vm$delete(confirm=confirm)
    })


    az_resource_group$set("public", "delete_vm_scaleset", overwrite=TRUE,
    function(name, confirm=TRUE, free_resources=TRUE)
    {
        self$get_vmss_cluster(name)$delete(confirm=confirm, free_resources=free_resources)
    })


    az_resource_group$set("public", "delete_vm_cluster", overwrite=TRUE,
    function(...)
    {
        .Defunct(msg="The 'delete_vm_cluster' method is defunct.\nUse 'delete_vm_scaleset' instead.")
    })


    az_resource_group$set("public", "list_vms", overwrite=TRUE, function()
    {
        provider <- "Microsoft.Compute"
        path <- "virtualMachines"
        api_version <- az_subscription$
            new(self$token, self$subscription)$
            get_provider_api_version(provider, path)

        op <- file.path("resourceGroups", self$name, "providers", provider, path)

        cont <- call_azure_rm(self$token, self$subscription, op, api_version=api_version)
        lst <- lapply(cont$value,
        function(parms) AzureVM::az_vm_resource$new(self$token, self$subscription, deployed_properties=parms))

        # keep going until paging is complete
        while(!is_empty(cont$nextLink))
        {
            cont <- call_azure_url(self$token, cont$nextLink)
            lst <- lapply(cont$value,
            function(parms) AzureVM::az_vm_resource$new(self$token, self$subscription, deployed_properties=parms))
        }

        # namespace shenanigans: get unexported function from AzureVM
        convert_to_vm_template <- get("convert_to_vm_template", loadNamespace("AzureVM"))

        # get templates corresponding to raw VMs (if possible)
        lapply(named_list(lst), convert_to_vm_template)
    })


    az_resource_group$set("public", "list_vm_sizes", overwrite=TRUE,
    function(name_only=FALSE)
    {
        az_subscription$
            new(self$token, self$subscription)$
            list_vm_sizes(self$location, name_only=name_only)
    })
}


convert_to_vm_template <- function(vm_resource)
{
    token <- vm_resource$token
    subscription <- vm_resource$subscription
    resource_group <- vm_resource$resource_group
    name <- vm_resource$name

    tpl <- try(AzureVM::az_vm_template$new(token, subscription, resource_group, name), silent=TRUE)
    if(!inherits(tpl, "try-error") &&
       !is_empty(tpl$properties$outputResources) &&
       grepl(sprintf("providers/Microsoft.Compute/virtualMachines/%s$", name),
             tpl$properties$outputResources[[1]]$id, ignore.case=TRUE))
        tpl
    else vm_resource
}

