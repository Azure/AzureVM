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


build_resource_fields.ip_config <- function(config, ...)
{
    alloc <- if(config$dynamic) "dynamic" else "static"
    version <- if(config$ipv6) "IPv6" else "IPv4"
    props <- c(
        list(
            publicIPAllocationMethod=alloc,
            publicIPAddressVersion=version
        ),
        config$other)
    if(!is.null(config$domain_name))
        props$dnsSettings$domainNameLabel <- config$domain_name

    sku <- list(name=config$type)
    utils::modifyList(ip_default, list(properties=props, sku=sku))
}


add_template_variables.ip_config <- function(config, ...)
{
    name <- "[concat(parameters('vmName'), '-ip')]"
    id <- "[resourceId('Microsoft.Network/publicIPAddresses', variables('ipName'))]"
    ref <- "[concat('Microsoft.Network/publicIPAddresses/', variables('ipName'))]"
    list(ipName=name, ipId=id, ipRef=ref)
}
