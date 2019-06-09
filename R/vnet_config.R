#' Virtual network configuration
#'
#' @param address_space For `vnet_config`, the address range accessible by the virtual network, expressed in CIDR block format.
#' @param subnets For `vnet_config`, a list of subnet objects, each obtained via a call to `subnet_config`.
#' @param name For `subnet_config`, the name of the subnet. Duplicate names will automatically be disambiguated prior to VM deployment.
#' @param addresses For `subnet_config`, the address ranges spanned by this subnet. Must be a subset of the address space available to the parent virtual network.
#' @param nsg The network security group associated with this subnet. Defaults to the NSG created as part of this VM deployment.
#' @param ... Other named arguments that will be treated as resource properties.
#' @export
vnet_config <- function(address_space="10.0.0.0/16", subnets=list(subnet_config()), ...)
{
    # attempt to fixup address blocks so they are consistent (should use iptools when it's fixed)
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
        if(!is_empty(sn$properties$addressPrefix))
            sn$properties$addressPrefix <- fixaddr(sn$properties$addressPrefix)
        if(!is_empty(sn$properties$addressPrefixes))
            sn$properties$addressPrefixes <- sapply(sn$properties$addressPrefixes, fixaddr)

        sn
    })

    # unique-ify subnet names
    sn_names <- make.unique(sapply(subnets, `[[`, "name"))
    for(i in seq_along(subnets))
        subnets[[i]]$name <- sn_names[i]

    props <- list(
        addressSpace=list(addressPrefixes=I(address_space)),
        subnets=subnets,
        ...
    )
    structure(list(properties=props), class="vnet_config")
}


vnet_config.build_resource_fields <- function(object, ...)
{
    object$properties$subnets <- lapply(object$properties$subnets, unclass)
    utils::modifyList(vnet_default, object)
}


#' @rdname vnet_config
#' @export
subnet_config <- function(name="subnet", addresses="10.0.0.0/16", nsg="[variables('nsgId')]", ...)
{
    properties <- if(length(addresses) < 2)
        list(addressPrefix=addresses, ...)
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
