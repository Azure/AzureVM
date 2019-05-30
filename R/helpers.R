#' @export
user_config <- function(username, password=NULL, sshkey=NULL)
{
    pwd <- is.character(password)
    key <- is.character(sshkey)
    if(!pwd && !key)
        stop("Must supply either a login password or SSH key", call.=FALSE)
    if(pwd && key)
        stop("Supply either a login password or SSH key, but not both", call.=FALSE)

    structure(list(user=username, pwd=password, key=sshkey), class="user_config")
}


#' @export
datadisk_config <- function(size, create="empty", sku="Standard_LRS", write_accelerator=FALSE)
{
    vm_caching <- if(sku == "Premium_LRS") "ReadOnly" else "None"
    vm_create <- if(create == "empty") "attach" else "fromImage"
    vm_storage <- if(create == "empty") NULL else sku

    vm_spec <- list(
        createOption=vm_create,
        caching=vm_caching,
        writeAcceleratorEnabled=write_accelerator,
        storageAccountType=vm_storage
    )

    res_spec <- if(!is.null(size))
        list(
            diskSizeGB=size,
            sku=sku,
            creationData=list(createOption=create)
        )
    else NULL

    structure(list(res_spec=res_spec, vm_spec=vm_spec), class="datadisk_config")
}


#' @export
image_config <- function(publisher=NULL, offer=NULL, sku=NULL, version="latest", id=NULL)
{
    if(!is.null(publisher) && !is.null(offer) && !is.null(sku))
    {
        structure(list(publisher=publisher, offer=offer, sku=sku, version=version),
                  class=c("image_marketplace", "image_config"))
    }
    else if(!is.null(id))
    {
        structure(list(id=id),
                  class=c("image_custom", "image_config"))
    }
    else stop("Invalid image configuration", call.=FALSE)

}


#' @export
build_template <- function(config)
{
    UseMethod("build_template")
}


#' @export
build_template.vm_config <- function(config)
{
    add_template_parameters <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(type=obj))
        params <<- c(params, new_params)
    }

    params <- tpl_parameters_default

    if(config$keylogin)
        add_template_parameters(sshKeyData="string")
    else add_template_parameters(adminPassword="securestring")

    if(inherits(config, "image_marketplace"))
        add_template_parameters(imagePublisher="string", imageOffer="string", imageSku="string", imageVersion="string")
    else add_template_parameters(imageId="string")

    if(!is_empty(config$nsrules))
        add_template_parameters(nsgrules="array")

    if(!is_empty(config$datadisks))
    {
        add_template_parameters(dataDisks="array", dataDiskResources="array")
        config$vm$dependsOn <- c(config$vm$dependsOn, "managedDisks")
        config$vm$storageProfile$copy <- vm_datadisk
    }

    if(config$managed)
        config$vm$identity <- list(type="systemAssigned")

    config$vm$properties$osProfile <- c(config$vm$properties$osProfile,
        if(config$keylogin) vm_key_login else vm_pwd_login)

    tpl <- list(
        `$schema`="http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=params,
        variables=tpl_variables_default,
        resources=list(
            config$nic, config$nsg, config$vnet, config$ip, config$vm
        ),
        outputs=tpl_outputs_default
    )

    if(!is_empty(config$datadisks) && any(sapply(config$datadisks, function(x) !is.null(x$res_spec))))
        tpl$resources <- c(tpl$resources, list(disk_default))

    jsonlite::toJSON(tpl, pretty=TRUE, auto_unbox=TRUE)
}


#' @export
build_parameters <- function(config, name, login_user, size)
{
    UseMethod("build_parameters")
}


#' @export
build_parameters.vm_config <- function(config, name, login_user, size)
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

    # add nsrules to params
    if(!is_empty(config$nsrules))
        add_parameters(nsgRules=config$nsrules)
    else add_parameters(nsgRules=logical(0))

    # fixup datadisk LUNs
    for(i in seq_along(config$datadisks))
        config$datadisks[[i]]$vm_spec$lun <- i - 1

    # add datadisks to params
    if(!is_empty(config$datadisks))
    {
        disk_res_spec <- lapply(config$datadisks, `[[`, "res_spec")
        null <- sapply(disk_res_spec, is.null)

        add_parameters(
            dataDisks=lapply(config$datadisks, `[[`, "vm_spec"),
            dataDiskResources=disk_res_spec[!null]
        )
    }

    out <- list(
        `$schema`="https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
        contentVersion="1.0.0.0",
        parameters=params
    )

    jsonlite::toJSON(out, pretty=TRUE, auto_unbox=TRUE)
}


resource_config <- function(resource, properties)
{
    modifyList(resource, list(properties=properties))
}


