#' @export
build_template_definition.vm_config <- function(config)
{
    add_template_parameters <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(type=obj))
        params <<- c(params, new_params)
    }

    params <- tpl_env$tpl_parameters_default

    if(config$keylogin)
        add_template_parameters(sshKeyData="string")
    else add_template_parameters(adminPassword="securestring")

    if(inherits(config$image, "image_marketplace"))
        add_template_parameters(imagePublisher="string", imageOffer="string", imageSku="string", imageVersion="string")
    else add_template_parameters(imageId="string")

    if(!is_empty(config$nsg_rules))
        add_template_parameters(nsgrules="array")

    n_disks <- length(config$datadisks)
    n_disk_resources <- if(n_disks > 0)
        sum(sapply(config$datadisks, function(x) !is.null(x$res_spec)))
    else 0

    if(n_disks > 0)
    {
        add_template_parameters(dataDisks="array", dataDiskResources="array")
        config$vm$properties$storageProfile$copy <- tpl_env$vm_datadisk
        if(n_disk_resources > 0)
            config$vm$dependsOn <- c(config$vm$dependsOn, "managedDiskResources")
    }

    if(config$managed)
        config$vm$identity <- list(type="systemAssigned")

    config$vm$properties$osProfile <- c(config$vm$properties$osProfile,
        if(config$keylogin) tpl_env$vm_key_login else tpl_env$vm_pwd_login)

    tpl <- list(
        `$schema`="http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=params,
        variables=tpl_env$tpl_variables_default,
        resources=list(
            config$nic, config$nsg, config$vnet, config$ip, config$vm
        ),
        outputs=tpl_env$tpl_outputs_default
    )

    if(n_disk_resources > 0)
        tpl$resources <- c(tpl$resources, list(tpl_env$disk_default))

    if(!is_empty(config$other))
        tpl$resources <- c(tpl$resources, config$other)

    jsonlite::toJSON(tpl, pretty=TRUE, auto_unbox=TRUE, null="null")
}


#' @export
build_template_parameters.vm_config <- function(config, name, login_user, size)
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

    # add nsg_rules to params
    if(!is_empty(config$nsg_rules))
    {
        # fixup rule priorities (if not specified)
        for(i in seq_along(config$nsg_rules))
        {
            if(is_empty(config$nsg_rules[[i]]$properties$priority))
                config$nsg_rules[[i]]$properties$priority <- 1000 + 10 * i
        }
        add_parameters(nsgRules=lapply(config$nsg_rules, unclass))
    }
    else add_parameters(nsgRules=logical(0))

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
                newdiskname <- paste(diskname, name, i, sep="_")
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

    jsonlite::toJSON(params, pretty=TRUE, auto_unbox=TRUE, null="null")
}

