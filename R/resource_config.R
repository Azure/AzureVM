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


#' @export
nsg_config <- function(rules=list(), ...)
{
    stopifnot(is.list(rules))
    props <- list(securityRules=rules, ...)
    structure(list(properties=props), class="nsg_config")
}


#' @export
ip_config <- function(allocation="dynamic", ipv6=FALSE, ...)
{
    version <- if(ipv6) "IPv6" else "IPv4"
    props <- list(publicIPAllocationMethod=allocation, publicIPAddressVersion=version, ...)
    structure(list(properties=props), class="ip_config")
}


#' @export
vnet_config <- function(address_space="10.0.0.0/16", subnets=list(subnet_config()), ...)
{
    # attempt to fixup address blocks so they are consistent (should really use iptools)
    ab_regex <- "^([0-9]+\\.[0-9]+).*$"
    ab_block <- sub(ab_regex, "\\1", address_space)
    fixaddr <- function(addr)
    {
        if(sub(ab_regex, "\\1", addr) == ab_block)
            sub("^[0-9]+\\.[0-9]+", ab_block, addr)
        else addr
    }
    subnets <- lapply(subnets, function(sn)
    {
        if(!inherits(sn, "subnet_config"))
            stop("Not a subnet object", call.=FALSE)

        if(!is_empty(sn$properties$addressPrefix))
            sn$properties$addressPrefix <- I(fixaddr(sn$properties$addressPrefix))
        if(!is_empty(sn$properties$addressPrefixes))
            sn$properties$addressPrefixes <- sapply(sn$properties$addressPrefixes, fixaddr)

        unclass(sn)
    })

    # unique-ify subnet names
    if(length(subnets) > 1)
    {
        sn_names <- make.unique(sapply(subnets, `[[`, "name"))
        for(i in seq_along(subnets))
            subnets[[i]]$name <- sn_names[i]
    }

    props <- list(
        addressSpace=list(
            addressPrefixes=I(address_space),
            subnets=subnets
        ),
        ...
    )
    structure(list(properties=props), class="vnet_config")
}


#' @export
subnet_config <- function(name="subnet", addresses="10.0.0.0/24", nsg=NULL, ...)
{
    properties <- if(length(addresses) < 2)
        list(addressPrefix=I(addresses), ...)
    else list(addressPrefixes=addresses, ...)

    # check if supplied a network security group resource ID or object
    if(is.character(nsg))
        properties$networkSecurityGroup$id <- nsg
    else if(is_resource(nsg) && tolower(nsg$type) == "microsoft.network/networksecuritygroups")
        properties$networkSecurityGroup$id <- nsg$id
    else if(!is.null(nsg))
        warning("Invalid network security group", call.=FALSE)

    subnet <- list(name=name, properties=properties)
    structure(subnet, class="subnet_config")
}


#' @export
nic_ip_config <- function(name="ipconfig", private_alloc="dynamic", ...)
{
    props <- list(privateIPAllocationMethod=private_alloc, ...)
    structure(list(name=name, properties=props), class="nic_ip_config")
}


#' @export
nic_config <- function(nic_ip=list(nic_ip_config()), ...)
{
    # unique-ify ip config names
    if(length(nic_ip) > 1)
    {
        ip_names <- make.unique(sapply(nic_ip, `[[`, "name"))
        for(i in seq_along(nic_ip))
            nic_ip[[i]]$name <- ip_names[i]
    }

    props <- list(ipConfigurations=lapply(nic_ip, unclass), ...)
    structure(props, class="nic_config")
}
