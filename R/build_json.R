#' Build template definition and parameters
#'
#' @param config An object of class `vm_config` or `vmss_config` representing a virtual machine or scaleset deployment.
#' @param name The VM or scaleset name. Will also be used for the domain name label, if a public IP address is included in the deployment.
#' @param login_user An object of class `user_config` representing the login details for the admin user account on the VM.
#' @param size The VM (instance) size.
#' @param ... Unused.
#'
#' @details
#' These are methods for the generics defined in the AzureRMR package.
#'
#' @return
#' Objects of class `json`, which are JSON character strings representing the deployment template and its parameters.
#'
#' @seealso
#' [create_vm], [vm_config], [vmss_config]
#'
#' @examples
#'
#' vm <- ubuntu_18.04()
#' build_template_definition(vm)
#' build_template_parameters(vm, "myubuntuvm",
#'     user_config("username", "~/.ssh/id_rsa.pub"), "Standard_DS3_v2")
#'
#' @rdname build_template
#' @aliases build_template
#' @export
build_template_definition.vm_config <- function(config, ...)
{
    tpl <- list(
        `$schema`="http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=add_template_parameters(config),
        variables=add_template_variables(config),
        resources=add_template_resources(config),
        outputs=tpl_outputs_default
    )

    jsonlite::prettify(jsonlite::toJSON(tpl, auto_unbox=TRUE, null="null"))
}


#' @rdname build_template
#' @export
build_template_definition.vmss_config <- function(config, ...)
{
    tpl <- list(
        `$schema`="http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=add_template_parameters(config),
        variables=add_template_variables(config),
        resources=add_template_resources(config),
        outputs=tpl_outputs_default
    )

    jsonlite::prettify(jsonlite::toJSON(tpl, auto_unbox=TRUE, null="null"))
}


#' @rdname build_template
#' @export
build_template_parameters.vm_config <- function(config, name, login_user, size, ...)
{
    add_parameters <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(value=obj))
        params <<- c(params, new_params)
    }

    stopifnot(inherits(login_user, "user_config"))

    params <- list()
    add_parameters(vmName=name, vmSize=size, adminUsername=login_user$user)

    if(config$keylogin && !is_empty(login_user$key))
        add_parameters(sshKeyData=login_user$key)
    else add_parameters(adminPassword=login_user$pwd)

    if(inherits(config$image, "image_marketplace"))
        add_parameters(
            imagePublisher=config$image$publisher,
            imageOffer=config$image$offer,
            imageSku=config$image$sku,
            imageVersion=config$image$version
        )
    else add_parameters(imageId=config$image$id)

    # add datadisks to params
    if(!is_empty(config$datadisks))
    {
        # fixup datadisk LUNs and names
        for(i in seq_along(config$datadisks))
        {
            config$datadisks[[i]]$vm_spec$lun <- i - 1
            diskname <- config$datadisks[[i]]$vm_spec$name
            if(!is.null(diskname))
            {
                newdiskname <- paste(name, diskname, i, sep="_")
                config$datadisks[[i]]$res_spec$name <- newdiskname
                config$datadisks[[i]]$vm_spec$name <- newdiskname
            }
        }

        disk_res_spec <- lapply(config$datadisks, `[[`, "res_spec")
        null <- sapply(disk_res_spec, is.null)

        add_parameters(
            dataDisks=lapply(config$datadisks, `[[`, "vm_spec"),
            dataDiskResources=disk_res_spec[!null]
        )
    }

    jsonlite::prettify(jsonlite::toJSON(params, auto_unbox=TRUE, null="null"))
}


#' @param instances For `vmss_config`, the number of (initial) instances in the VM scaleset.
#' @rdname build_template
#' @export
build_template_parameters.vmss_config <- function(config, name, login_user, size, instances, ...)
{
    add_parameters <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(value=obj))
        params <<- c(params, new_params)
    }

    stopifnot(inherits(login_user, "user_config"))

    params <- list()
    add_parameters(vmName=name, vmSize=size, instanceCount=instances, adminUsername=login_user$user)

    if(config$options$keylogin && !is_empty(login_user$key))
        add_parameters(sshKeyData=login_user$key)
    else add_parameters(adminPassword=login_user$pwd)

    if(inherits(config$image, "image_marketplace"))
        add_parameters(
            imagePublisher=config$image$publisher,
            imageOffer=config$image$offer,
            imageSku=config$image$sku,
            imageVersion=config$image$version
        )
    else add_parameters(imageId=config$image$id)

    do.call(add_parameters, config$options$params)

    # add datadisks to params
    if(!is_empty(config$datadisks))
    {
        # fixup datadisk for scaleset
        for(i in seq_along(config$datadisks))
        {
            config$datadisks[[i]]$vm_spec$lun <- i - 1
            if(config$datadisks[[i]]$vm_spec$createOption == "attach")
            {
                config$datadisks[[i]]$vm_spec$createOption <- "empty"
                config$datadisks[[i]]$vm_spec$diskSizeGB <- config$datadisks[[i]]$res_spec$diskSizeGB
                config$datadisks[[i]]$vm_spec$storageAccountType <- config$datadisks[[i]]$res_spec$sku
            }
            diskname <- config$datadisks[[i]]$vm_spec$name
            if(!is.null(diskname))
            {
                newdiskname <- paste(name, diskname, i, sep="_")
                config$datadisks[[i]]$res_spec$name <- newdiskname
                config$datadisks[[i]]$vm_spec$name <- newdiskname
            }
        }

        disk_res_spec <- lapply(config$datadisks, `[[`, "res_spec")
        null <- sapply(disk_res_spec, is.null)

        add_parameters(
            dataDisks=lapply(config$datadisks, `[[`, "vm_spec"),
            dataDiskResources=disk_res_spec[!null]
        )
    }

    jsonlite::prettify(jsonlite::toJSON(params, auto_unbox=TRUE, null="null"))
}


add_template_parameters <- function(config, ...)
{
    UseMethod("add_template_parameters")
}


add_template_variables <- function(config, ...)
{
    UseMethod("add_template_variables")
}


add_template_variables.character <- function(config, type, ...)
{
    # assume this is a resource ID
    resname <- basename(config)
    varnames <- paste0(type, c("Name", "Id"))
    structure(list(resname, config), names=varnames)
}


add_template_variables.az_resource <- function(config, type, ...)
{
    varnames <- paste0(type, c("Name", "Id"))
    vars <- list(config$name, config$id)

    # a bit hackish, should fully objectify
    if(type == "vnet") # if we have a vnet, extract the 1st subnet name
    {
        subnet <- config$properties$subnets[[1]]$name
        subnet_id <- "[concat(variables('vnetId'), '/subnets/', variables('subnet'))]"
        varnames <- c(varnames, "subnet", "subnetId")
        structure(c(vars, subnet, subnet_id), names=varnames)
    }
    else if(type == "lb") # if we have a load balancer, extract component names
    {
        frontend <- config$properties$frontendIPConfigurations[[1]]$name
        backend <- config$properties$backendAddressPools[[1]]$name
        frontend_id <- "[concat(variables('lbId'), '/frontendIPConfigurations/', variables('lbFrontendName'))]"
        backend_id <- "[concat(variables('lbId'), '/backendAddressPools/', variables('lbBackendName'))]"
        varnames <- c(varnames, "lbFrontendName", "lbBackendName", "lbFrontendId", "lbBackendId")
        structure(c(vars, frontend, backend, frontend_id, backend_id), names=varnames)
    }
    else structure(vars, names=varnames)
}


add_template_variables.NULL <- function(config, ...)
{
    NULL
}


add_template_resources <- function(config, ...)
{
    UseMethod("add_template_resources")
}


build_resource_fields <- function(config)
{
    UseMethod("build_resource_fields")
}


build_resource_fields.list <- function(config, ...)
{
    unclass(config)
}


