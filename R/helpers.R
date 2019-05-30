#' @export
user_config <- function(username, sshkey=NULL, password=NULL)
{
    pwd <- is.character(password)
    key <- is.character(sshkey)
    if(!pwd && !key)
        stop("Must supply either a login password or SSH key", call.=FALSE)
    if(pwd && key)
        stop("Supply either a login password or SSH key, but not both", call.=FALSE)

    structure(list(user=username, key=sshkey, pwd=password), class="user_config")
}


#' @export
datadisk_config <- function(size, name="datadisk", create="empty", sku="StandardSSD_LRS", write_accelerator=FALSE)
{
    vm_caching <- if(sku == "Premium_LRS") "ReadOnly" else "None"
    vm_create <- if(create == "empty") "attach" else "fromImage"
    vm_storage <- if(create == "empty") NULL else sku

    vm_spec <- list(
        createOption=vm_create,
        caching=vm_caching,
        writeAcceleratorEnabled=write_accelerator,
        storageAccountType=vm_storage,
        diskSizeGB=NULL,
        id=NULL,
        name=name
    )

    res_spec <- if(!is.null(size))
        list(
            diskSizeGB=size,
            sku=sku,
            creationData=list(createOption=create),
            name=name
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
nsg_rule_config <- function(name, dest_port="*", dest_addr="*", dest_asgs=NULL,
                            source_port="*", source_addr="*", source_asgs=NULL,
                            access="allow", direction="inbound",
                            protocol="TCP", priority=NULL)
{
    if(is_empty(dest_asgs))
        dest_asgs <- logical(0)
    if(is_empty(source_asgs))
        source_asgs <- logical(0)

    properties <- list(
        protocol=protocol,
        access=access,
        direction=direction,
        sourceApplicationSecurityGroups=source_asgs,
        destinationApplicationSecurityGroups=dest_asgs,
        sourceAddressPrefix=source_addr,
        sourcePortRange=as.character(source_port),
        destinationAddressPrefix=dest_addr,
        destinationPortRange=as.character(dest_port)
    )

    if(!is_empty(priority))
        properties$priority <- priority

    structure(list(name=name, properties=properties), class="nsg_rule_config")
}


resource_config <- function(resource, properties)
{
    modifyList(resource, list(properties=properties))
}


