#' Network security group configuration
#'
#' @param rules for `nsg_config`, a list of security rule objects, each obtained via a call to `nsg_rule`.
#' @param dest_port,dest_addr,dest_asgs For `nsg_rule`, the destination port, address range, and application security groups for a rule.
#' @param source_port,source_addr,source_asgs For `nsg_rule`, the source port, address range, and application security groups for a rule.
#' @param ... Other named arguments that will be treated as resource properties.
#' @param access For `nsg_rule`, the action to take: "allow" or "deny".
#' @param direction For `nsg_rule`, the direction of traffic: "inbound" or "outbound".
#' @param protocol For `nsg_rule`, the network protocol: either "TCP" or "UDP".
#' @param priority For `nsg_rule`, the rule priority. If NULL, this will be set automatically by AzureVM.
#' @export
nsg_config <- function(rules=list(), ...)
{
    stopifnot(is.list(rules))
    props <- list(securityRules=rules, ...)
    structure(list(properties=props), class="nsg_config")
}


build_resource_fields.nsg_config <- function(object, ...)
{
    for(i in seq_along(object$properties$securityRules))
    {
        # fixup nsg security rule priorities
        if(is_empty(object$properties$securityRules[[i]]$properties$priority))
            object$properties$securityRules[[i]]$properties$priority <- 1000 + 10 * i

        object$properties$securityRules[[i]] <- unclass(object$properties$securityRules[[i]])
    }

    utils::modifyList(nsg_default, object)
}


#' @rdname nsg_config
#' @export
nsg_rule <- function(name, dest_port="*", dest_addr="*", dest_asgs=NULL,
                            source_port="*", source_addr="*", source_asgs=NULL,
                            access="allow", direction="inbound",
                            protocol="Tcp", priority=NULL)
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

    structure(list(name=name, properties=properties), class="nsg_rule")
}


#' Network security rules
#'
#' @section Usage:
#' ```
#' nsg_rule_allow_http
#' nsg_rule_allow_https
#' nsg_rule_allow_jupyter
#' nsg_rule_allow_rdp
#' nsg_rule_allow_rstudio
#' nsg_rule_allow_ssh
#' ```
#' @section Details:
#' Some predefined network security rules provided by AzureVM, to unblock commonly-used ports.
#' - HTTP: TCP port 80
#' - HTTPS: TCP port 443
#' - JupyterHub: TCP port 8000
#' - RDP: TCP port 3389
#' - RStudio Server: TCP port 8787
#' - SSH: TCP port 22
#' - SQL Server: TCP port 1433
#' - SQL Server browser service: TCP port 1434
#' @docType data
#' @rdname nsg_rule
#' @export
nsg_rule_allow_ssh <- nsg_rule("Allow-ssh", 22)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_http <- nsg_rule("Allow-http", 80)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_https <- nsg_rule("Allow-https", 443)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_rdp <- nsg_rule("Allow-rdp", 3389)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_jupyter <- nsg_rule("Allow-jupyter", 8000)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_rstudio <- nsg_rule("Allow-rstudio", 8787)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_mssql <- nsg_rule("Allow-mssql", 1433)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_mssql_browser <- nsg_rule("Allow-mssql-browser", 1434)
