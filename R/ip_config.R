#' Public IP address configuration
#'
#' @param type The SKU of the IP address resource: "basic" or "standard". If NULL (the default), this will be determined based on the VM's configuration.
#' @param dynamic Whether the IP address should be dynamically or statically allocated. Note that the standard SKU only supports standard allocation. If NULL (the default) this will be determined based on the VM's configuration.
#' @param ipv6 Whether to create an IPv6 address. The default is IPv4.
#' @param domain_name The domain name label to associate with the address.
#' @param ... Other named arguments that will be treated as resource properties.
#' @export
ip_config <- function(type=NULL, dynamic=NULL, ipv6=FALSE, domain_name="[parameters('vmName')]", ...)
{
    # structure(list(properties=props, sku=list(name=type)), class="ip_config")
    props <- list(
        type=type,
        dynamic=dynamic,
        ipv6=ipv6,
        domain_name=domain_name,
        other=list(...)
    )
    structure(props, class="ip_config")
}


build_resource_fields.ip_config <- function(object, ...)
{
    alloc <- if(object$dynamic) "dynamic" else "static"
    version <- if(object$ipv6) "IPv6" else "IPv4"
    props <- c(
        list(
            publicIPAllocationMethod=alloc,
            publicIPAddressVersion=version
        ),
        object$other)
    if(!is.null(object$domain_name))
        props$dnsSettings$domainNameLabel <- object$domain_name

    sku <- list(name=object$type)
    utils::modifyList(ip_default, list(properties=props, sku=sku))
}

