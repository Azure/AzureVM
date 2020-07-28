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
#' sub <- AzureRMR::get_azure_login$
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
#' get_vm_scaleset(name, resource_group = name)
#'
#' ## R6 method for class 'az_resource_group'
#' get_vm_scaleset(name)
#'
#' ## R6 method for class 'az_resource_group')
#' get_vm_resource(name)
#' get_vm_scaleset_resource(name)
#' ```
#' @section Arguments:
#' - `name`: The name of the VM or scaleset.
#' - `resource_group`: For the `az_subscription` methods, the resource group in which `get_vm()` and `get_vm_scaleset()`  will look for the VM or scaleset. Defaults to the VM name.
#'
#' @section Value:
#' For `get_vm()`, an object representing the VM deployment. This will include other resources besides the VM itself, such as the network interface, virtual network, etc.
#'
#' For `get_vm_scaleset()`, an object representing the scaleset deployment. Similarly to `get_vm()`, this includes other resources besides the scaleset.
#'
#' For `get_vm_resource()` and `get_vm_scaleset_resource()`, the VM or scaleset resource itself.
#'
#' @seealso
#' [az_vm_template], [az_vm_resource], [az_vmss_template], [az_vmss_resource] for the methods available for working with VMs and VM scalesets.
#'
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")
#'
#' sub$get_vm("myvirtualmachine")
#' sub$get_vm_scaleset("myscaleset")
#'
#' rg <- sub$get_resource_group("rgname")
#' rg$get_vm("myothervirtualmachine")
#' rg$get_vm_scaleset("myotherscaleset")
#'
#' }
#' @rdname get_vm
#' @aliases get_vm get_vm_scaleset get_vm_resource get_vm_scaleset_resource
#' @name get_vm
NULL


#' Create a new virtual machine or scaleset of virtual machines
#'
#' Method for the [AzureRMR::az_subscription] and [AzureRMR::az_resource_group] classes.
#'
#' @section Usage:
#' ```
#' ## R6 method for class 'az_resource_group'
#' create_vm(name, login_user, size = "Standard_DS3_v2", config = "ubuntu_dsvm",
#'           managed_identity = TRUE, datadisks = numeric(0), ...,
#'           template, parameters, mode = "Incremental", wait = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' create_vm(name, ..., resource_group = name, location)
#'
#' ## R6 method for class 'az_resource_group'
#' create_vm_scaleset(name, login_user, instances, size = "Standard_DS1_v2",
#'                    config = "ubuntu_dsvm_ss", ...,
#'                    template, parameters, mode = "Incremental", wait = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' create_vm_scaleset(name, ..., resource_group = name, location)
#' ```
#' @section Arguments:
#' - `name`: The name of the VM or scaleset.
#' - `location`: For the subscription methods, the location for the VM or scaleset. Use the `list_locations()` method of the `AzureRMR::az_subscription` class to see what locations are available.
#' - `resource_group`: For the subscription methods, the resource group in which to place the VM or scaleset. Defaults to a new resource group with the same name as the VM.
#' - `login_user`: The details for the admin login account. An object of class `user_config`, obtained by a call to the `user_config` function.
#' - `size`: The VM (instance) size. Use the [list_vm_sizes] method to see what sizes are available.
#' - `config`: The VM or scaleset configuration. See 'Details' below for how to specify this. The default is to use an Ubuntu Data Science Virtual Machine.
#' - `managed_identity`: For `create_vm`, whether the VM should have a managed identity attached.
#' - `datadisks`: Any data disks to attach to the VM or scaleset. See 'Details' below.
#' - `instances`: For `create_vm_scaleset`, the initial number of instances in the scaleset.
#' - `...` For the subscription methods, any of the other arguments listed here, which will be passed to the resource group method. For the resource group method, additional arguments to pass to the VM/scaleset configuration functions [vm_config] and [vmss_config]. See the examples below.
#' - `template,parameters`: The template definition and parameters to deploy. By default, these are constructed from the values of the other arguments, but you can supply your own template and/or parameters as well.
#' - `wait`: Whether to wait until the deployment is complete.
#' - `mode`: The template deployment mode. If "Complete", any existing resources in the resource group will be deleted.
#'
#' @section Details:
#' These methods deploy a template to create a new virtual machine or scaleset.
#'
#' The `config` argument can be specified in the following ways:
#' - As the name of a supplied VM or scaleset configuration, like "ubuntu_dsvm" or "ubuntu_dsvm_ss". AzureVM comes with a number of supplied configurations to deploy commonly used images, which can be seen at [vm_config] and [vmss_config]. Any arguments in `...` will be passed to the configuration, allowing you to customise the deployment.
#' - As a call to the `vm_config` or `vmss_config` functions, to deploy a custom VM image.
#' - As an object of class `vm_config` or `vmss_config`.
#'
#' The data disks for the VM can be specified as either a vector of numeric disk sizes in GB, or as a list of `datadisk_config` objects, created via calls to the `datadisk_config` function. Currently, AzureVM only supports creating data disks at deployment time for single VMs, not scalesets.
#'
#' You can also supply your own template definition and parameters for deployment, via the `template` and `parameters` arguments. See [AzureRMR::az_template] for information how to create templates.
#'
#' The `AzureRMR::az_subscription` methods will by default create the VM in _exclusive_ mode, meaning a new resource group is created solely to hold the VM or scaleset. This simplifies managing the VM considerably; in particular deleting the resource group will also automatically delete all the deployed resources.
#'
#' @section Value:
#' For `create_vm`, an object of class `az_vm_template` representing the created VM. For `create_vm_scaleset`, an object of class `az_vmss_template` representing the scaleset.
#'
#' @seealso
#' [az_vm_template], [az_vmss_template]
#'
#' [vm_config], [vmss_config], [user_config], [datadisk_config]
#'
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group],
#' [Data Science Virtual Machine](https://azure.microsoft.com/en-us/services/virtual-machines/data-science-virtual-machines/)
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")
#'
#' # default Ubuntu 18.04 VM:
#' # SSH key login, Standard_DS3_v2, publicly accessible via SSH
#' sub$create_vm("myubuntuvm", user_config("myname", "~/.ssh/id_rsa.pub"),
#'               location="australiaeast")
#'
#' # Windows Server 2019, with a 500GB datadisk attached, not publicly accessible
#' sub$create_vm("mywinvm", user_config("myname", password="Use-strong-passwords!"),
#'               size="Standard_DS4_v2", config="windows_2019", datadisks=500, ip=NULL,
#'               location="australiaeast")
#'
#' # Ubuntu DSVM, GPU-enabled
#' sub$create_vm("mydsvm", user_config("myname", "~/.ssh/id_rsa.pub"), size="Standard_NC12",
#'               config="ubuntu_dsvm_ss",
#'               location="australiaeast")
#'
#' ## custom VM configuration: Windows 10 Pro 1903 with data disks
#' ## this assumes you have a valid Win10 desktop license
#' user <- user_config("myname", password="Use-strong-passwords!")
#' image <- image_config(
#'      publisher="MicrosoftWindowsDesktop",
#'      offer="Windows-10",
#'      sku="19h1-pro"
#' )
#' datadisks <- list(
#'     datadisk_config(250, type="Premium_LRS"),
#'     datadisk_config(1000, type="Standard_LRS")
#' )
#' nsg <- nsg_config(
#'     list(nsg_rule_allow_rdp)
#' )
#' config <- vm_config(
#'     image=image,
#'     keylogin=FALSE,
#'     datadisks=datadisks,
#'     nsg=nsg,
#'     properties=list(licenseType="Windows_Client")
#' )
#' sub$create_vm("mywin10vm", user, size="Standard_DS2_v2", config=config,
#'               location="australiaeast")
#'
#'
#' # default Ubuntu scaleset:
#' # load balancer and autoscaler enabled, Standard_DS1_v2
#' sub$create_vm_scaleset("mydsvmss", user_config("myname", "~/.ssh/id_rsa.pub"),
#'                        instances=5,
#'                        location="australiaeast"))
#'
#' # Ubuntu DSVM scaleset with public GPU-enabled instances, no load balancer or autoscaler
#' sub$create_vm_scaleset("mydsvmss", user_config("myname", "~/.ssh/id_rsa.pub"),
#'                        instances=5, size="Standard_NC12", config="ubuntu_dsvm_ss",
#'                        options=scaleset_options(public=TRUE),
#'                        load_balancer=NULL, autoscaler=NULL,
#'                        location="australiaeast")
#'
#' # RHEL scaleset, allow http/https access
#' sub$create_vm_scaleset("myrhelss", user_config("myname", "~/.ssh/id_rsa.pub"),
#'                         instances=5, config="rhel_8_ss",
#'                         nsg=nsg_config(list(nsg_rule_allow_http, nsg_rule_allow_https)),
#'                         location="australiaeast")
#'
#' # Large Debian scaleset, using low-priority (spot) VMs
#' # need to set the instance size to something that supports low-pri
#' sub$create_vm_scaleset("mydebss", user_config("myname", "~/.ssh/id_rsa.pub"),
#'                        instances=50, size="Standard_DS3_v2", config="debian_9_backports_ss",
#'                        options=scaleset_options(priority="spot", large_scaleset=TRUE),
#'                        location="australiaeast")
#'
#'
#' ## VM and scaleset in the same resource group and virtual network
#' # first, create the resgroup
#' rg <- sub$create_resource_group("rgname", "australiaeast")
#'
#' # create the master
#' rg$create_vm("mastervm", user_config("myname", "~/.ssh/id_rsa.pub"))
#'
#' # get the vnet resource
#' vnet <- rg$get_resource(type="Microsoft.Network/virtualNetworks", name="mastervm-vnet")
#'
#' # create the scaleset
#' rg$create_vm_scaleset("slavess", user_config("myname", "~/.ssh/id_rsa.pub"),
#'                       instances=5, vnet=vnet, nsg=NULL, load_balancer=NULL, autoscaler=NULL)
#'
#' }
#' @rdname create_vm
#' @aliases create_vm create_vm_scaleset
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
#' delete_vm_scaleset(name, confirm = TRUE, free_resources = TRUE)
#'
#' ## R6 method for class 'az_subscription'
#' delete_vm_scaleset(name, confirm = TRUE, free_resources = TRUE,
#'                   resource_group = name)
#' ```
#' @section Arguments:
#' - `name`: The name of the VM or scaleset.
#' - `confirm`: Whether to confirm the delete.
#' - `free_resources`: If this was a deployed template, whether to free all resources created during the deployment process.
#' - `resource_group`: For the `AzureRMR::az_subscription` method, the resource group containing the VM or scaleset.
#'
#' @section Details:
#' For the subscription methods, deleting the VM or scaleset will also delete its resource group.
#'
#' @seealso
#' [create_vm], [az_vm_template], [az_vm_resource],
#' [AzureRMR::az_subscription], [AzureRMR::az_resource_group]
#'
#' @examples
#' \dontrun{
#'
#' sub <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")
#'
#' sub$delete_vm("myvm")
#' sub$delete_vm_scaleset("myscaleset")
#'
#' }
#' @rdname delete_vm
#' @aliases delete_vm delete_vm_scaleset
#' @name delete_vm
NULL


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
    function(name, ..., resource_group=name, location)
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

        res <- try(resource_group$create_vm(name, ..., mode=mode))

        if(inherits(res, "try-error") && mode == "Complete")
        {
            resource_group$delete(confirm=FALSE)
            stop("Unable to create VM", call.=FALSE)
        }
        res
    })

    az_subscription$set("public", "create_vm_scaleset", overwrite=TRUE,
    function(name, ..., resource_group=name, location)
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

        res <- try(resource_group$create_vm_scaleset(name, ..., mode=mode))

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
}


# extend resource group methods
add_rg_methods <- function()
{
    az_resource_group$set("public", "create_vm", overwrite=TRUE,
    function(name, login_user, size="Standard_DS3_v2", config="ubuntu_20.04",
             managed_identity=TRUE, datadisks=numeric(0),
             ..., template, parameters, mode="Incremental", wait=TRUE)
    {
        stopifnot(inherits(login_user, "user_config"))

        if(is.character(config))
            config <- get(config, getNamespace("AzureVM"))
        if(is.function(config))
            config <- config(!is_empty(login_user$key), managed_identity, datadisks, ...)

        stopifnot(inherits(config, "vm_config"))

        if(missing(template))
            template <- build_template_definition(config)

        if(missing(parameters))
            parameters <- build_template_parameters(config, name, login_user, size)

        az_vm_template$new(self$token, self$subscription, self$name, name,
            template=template, parameters=parameters, mode=mode, wait=wait)
    })

    az_resource_group$set("public", "create_vm_scaleset", overwrite=TRUE,
    function(name, login_user, instances, size="Standard_DS1_v2", config="ubuntu_20.04_ss",
             ..., template, parameters, mode="Incremental", wait=TRUE)
    {
        stopifnot(inherits(login_user, "user_config"))

        if(is.character(config))
            config <- get(config, getNamespace("AzureVM"))
        if(is.function(config))
            config <- config(...)

        stopifnot(inherits(config, "vmss_config"))

        if(missing(template))
            template <- build_template_definition(config)

        if(missing(parameters))
            parameters <- build_template_parameters(config, name, login_user, size, instances)

        az_vmss_template$new(self$token, self$subscription, self$name, name,
            template=template, parameters=parameters, mode=mode, wait=wait)
    })

    az_resource_group$set("public", "get_vm", overwrite=TRUE,
    function(name)
    {
        az_vm_template$new(self$token, self$subscription, self$name, name)
    })

    az_resource_group$set("public", "get_vm_scaleset", overwrite=TRUE,
    function(name)
    {
        az_vmss_template$new(self$token, self$subscription, self$name, name)
    })

    az_resource_group$set("public", "delete_vm", overwrite=TRUE,
                          function(name, confirm=TRUE, free_resources=TRUE)
    {
        self$get_vm(name)$delete(confirm=confirm, free_resources=free_resources)
    })

    az_resource_group$set("public", "delete_vm_scaleset", overwrite=TRUE,
    function(name, confirm=TRUE, free_resources=TRUE)
    {
        self$get_vm_scaleset(name)$delete(confirm=confirm, free_resources=free_resources)
    })

    az_resource_group$set("public", "list_vm_sizes", overwrite=TRUE,
    function(name_only=FALSE)
    {
        az_subscription$
            new(self$token, parms=list(subscriptionId=self$subscription))$
            list_vm_sizes(self$location, name_only=name_only)
    })

    az_resource_group$set("public", "get_vm_resource", overwrite=TRUE,
    function(name)
    {
        az_vm_resource$new(self$token, self$subscription, self$name,
            type="Microsoft.Compute/virtualMachines", name=name)
    })

    az_resource_group$set("public", "get_vm_scaleset_resource", overwrite=TRUE,
    function(name)
    {
        az_vmss_resource$new(self$token, self$subscription, self$name,
            type="Microsoft.Compute/virtualMachineScalesets", name=name)
    })
}



#' Defunct methods
#'
#' @section Usage:
#' ```
#' get_vm_cluster(...)
#' create_vm_cluster(...)
#' delete_vm_cluster(...)
#' ```
#' These methods for the `az_subscription` and `az_resource_group` classes are defunct in AzureVM 2.0. To work with virtual machine clusters, call the [get_vm_scaleset], [create_vm_scaleset] and [delete_vm_scaleset] methods instead.
#' @rdname defunct
#' @name defunct
#' @aliases get_vm_cluster create_vm_cluster delete_vm_cluster
NULL


add_defunct_methods <- function()
{
    az_subscription$set("public", "get_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'get_vm_cluster' method is defunct.\nUse 'get_vm_scaleset' instead.")
    })

    az_subscription$set("public", "create_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'create_vm_cluster' method is defunct.\nUse 'create_vm_scaleset' instead.")
    })

    az_subscription$set("public", "delete_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'delete_vm_cluster' method is defunct.\nUse 'delete_vm_scaleset' instead.")
    })

    az_resource_group$set("public", "get_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'get_vm_cluster' method is defunct.\nUse 'get_vm_scaleset' instead.")
    })

    az_resource_group$set("public", "create_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'create_vm_cluster' method is defunct.\nUse 'create_vm_scaleset' instead.")
    })

    az_resource_group$set("public", "delete_vm_cluster", overwrite=TRUE, function(...)
    {
        .Defunct(msg="The 'delete_vm_cluster' method is defunct.\nUse 'delete_vm_scaleset' instead.")
    })
}

