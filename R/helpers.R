lapply(list.files("tpl", pattern="\\.json$"), function(f)
{
    obj <- sub("\\.json$", "", f)
    assign(obj, jsonlite::fromJSON(file.path("tpl", f), simplifyVector=FALSE), parent.env(environment()))
})


image_config <- function(publisher=NULL, offer=NULL, sku=NULL, version="latest", id=NULL)
{
    if(!is.null(publisher) && !is.null(offer) && !is.null(sku))
        list(publisher=publisher, offer=offer, sku=sku, version=version)
    else if(!is.null(id))
        list(id=id)
    else stop("Invalid image configuration", call.=FALSE)
}


resource_config <- function(resource, properties)
{
    modifyList(resource, list(properties=properties))
}


build_template <- function(config)
{
    if(!is_empty(config$datadisks))
    {
        config$vm$dependsOn <- c(config$vm$dependsOn, "managedDisks")
        config$vm$storageProfile$copy <- vm_datadisk
    }

    if(config$msi)
        config$vm$identity <- list(type="systemAssigned")

    config$vm$properties$osProfile <- c(config$vm$properties$osProfile,
        if(config$keylogin) vm_key_login else vm_pwd_login)

    tpl <- list(
        `$schema`="http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=tpl_parameters_default,
        variables=tpl_variables_default,
        resources=list(
            config$nic, config$nsg, config$vnet, config$ip, config$vm
        ),
        outputs=tpl_outputs_default
    )

    if(!is_empty(config$datadisks))
        tpl$resources <- c(tpl$resources, list(disk_default))

    jsonlite::toJSON(tpl, pretty=TRUE, auto_unbox=TRUE)
}


build_parameters <- function(config, params)
{
    # add nsrules to params
    # add datadisks to params
    # fixup datadisk LUNs
}


datadisk_config <- function(size, create="empty", sku="Standard_LRS", write_accelerator=FALSE)
{
    vm_caching <- if(sku == "Premium_LRS") "ReadOnly" else "None"
    vm_create <- if(create == "empty") "attach" else "fromImage"
    vm_storage <- if(create == "empty") NULL else sku

    disk_vm_spec <- list(
        createOption=vm_create,
        caching=vm_caching,
        writeAcceleratorEnabled=write_accelerator,
        storageAccountType=vm_storage
    )

    disk_resource_spec <- if(!is.null(size))
        list(
            diskSizeGB=size,
            sku=sku,
            creationData=list(createOption=create)
        )
    else NULL

    structure(list(disk_resource_spec, disk_vm_spec), class="datadisk_config")
}
