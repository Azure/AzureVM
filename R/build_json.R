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

    jsonlite::prettify(jsonlite::toJSON(params, auto_unbox=TRUE, null="null"))
}


