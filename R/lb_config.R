#' Load balancer configuration
#'
#' @param type The SKU of the load balancer resource: "basic" or "standard". If NULL (the default), this will be determined based on the VM scaleset's configuration. Note that the load balancer SKU must be the same as that of its public IP address.
#' @param rules A list of load balancer rules, each obtained via a call to `lb_rule`.
#' @param probes A list of health checking probes, each obtained via a call to `lb_probe`. There must be a probe corresponding to each rule.
#' @param ... Other named arguments that will be treated as resource properties.
#' @param port For `lb_probe`, the port to probe.
#' @param interval For `lb_probe`, the interval between probes.
#' @param fail_on For `lb_probe`, the probe health check will fail after this many non-responses.
#' @param protocol For `lb_probe` and `lb_rule`, the protocol: either "Tcp" or "Ip".
#' @param name For `lb_rule`, a name for the load balancing rule.
#' @param frontend_port,backend_port For `lb_rule`, the ports for this rule.
#' @param timeout The timeout interval for the rule. The default is 5 minutes.
#' @param floating_ip Whether to use floating IP addresses. Only needed for specific scenarios.
#' @param probe_name The name of the corresponding health check probe.
#'
#' @export
lb_config <- function(type=NULL, rules=list(), probes=list(), ...)
{
    rule_probe_names <- sapply(rules, function(x) x$properties$probe$id)
    probe_names <- sapply(probes, `[[`, "name")

    # basic checking
    for(r in rule_probe_names)
    {
        found <- FALSE
        for(p in probe_names)
        {
            found <- grepl(p, r, fixed=TRUE)
            if(found) break
        }
        if(!found)
            stop("Rule with no matching probe: ", r, call.=FALSE)
    }

    props <- list(
        type=type,
        rules=rules,
        probes=probes,
        other=list(...)
    )
    structure(props, class="lb_config")
}


build_resource_fields.lb_config <- function(config, ...)
{
    props <- c(
        list(
            loadBalancingRules=lapply(config$rules, unclass),
            probes=lapply(config$probes, unclass)
        ),
        config$other
    )
    sku <- list(name=config$type)
    utils::modifyList(lb_default, list(properties=props, sku=sku))
}


add_template_variables.lb_config <- function(config, ...)
{
    name <- "[concat(parameters('vmName'), '-lb')]"
    id <- "[resourceId('Microsoft.Network/loadBalancers', variables('lbName'))]"
    ref <- "[concat('Microsoft.Network/loadBalancers/', variables('lbName'))]"
    frontend <- "frontend"
    backend <- "backend"
    frontend_id <- "[concat(variables('lbId'), '/frontendIPConfigurations/', variables('lbFrontendName'))]"
    backend_id <- "[concat(variables('lbId'), '/backendAddressPools/', variables('lbBackendName'))]"
    list(
        lbName=name,
        lbId=id,
        lbRef=ref,
        lbFrontendName=frontend,
        lbBackendName=backend,
        lbFrontendId=frontend_id,
        lbBackendId=backend_id
    )
}


#' @rdname lb_config
#' @export
lb_probe <- function(port, interval=5, fail_on=2, protocol="Tcp")
{
    name <- paste("probe", protocol, port, sep="-")
    props <- list(
        port=port,
        intervalInSeconds=interval,
        numberOfProbes=fail_on,
        protocol=protocol
    )

    structure(list(name=name, properties=props), class="lb_probe")
}


#' @rdname lb_config
#' @export
lb_rule <- function(name, frontend_port, backend_port=frontend_port, protocol="Tcp", timeout=5,
                    floating_ip=FALSE, probe_name=paste("probe", protocol, frontend_port, sep="-"))
{
    frontend_id <- "[variables('lbFrontendId')]"
    backend_id <- "[variables('lbBackendId')]"
    probe_id <- sprintf("[concat(variables('lbId'), '/probes/%s')]", probe_name)

    props <- list(
        frontendIpConfiguration=list(id=frontend_id),
        backendAddressPool=list(id=backend_id),
        protocol=protocol,
        frontendPort=frontend_port,
        backendPort=backend_port,
        enableFloatingIp=floating_ip,
        idleTimeoutInMinutes=timeout,
        probe=list(id=probe_id)
    )

    structure(list(name=name, properties=props), class="lb_rule")
}


#' Load balancing rules
#'
#' @format
#' Objects of class `lb_rule` and `lb_probe`.
#' @details
#' Some predefined load balancing objects, for commonly-used ports.
#' - HTTP: TCP port 80
#' - HTTPS: TCP port 443
#' - JupyterHub: TCP port 8000
#' - RDP: TCP port 3389
#' - RStudio Server: TCP port 8787
#' - SSH: TCP port 22
#' - SQL Server: TCP port 1433
#' - SQL Server browser service: TCP port 1434
#' @docType data
#' @rdname lb_rules
#' @export
lb_rule_ssh <- lb_rule("lb-ssh", 22, 22, probe_name="probe-Tcp-22")

#' @rdname lb_rules
#' @export
lb_rule_http <- lb_rule("lb-http", 80, 80, probe_name="probe-Tcp-80")

#' @rdname lb_rules
#' @export
lb_rule_https <- lb_rule("lb-https", 443, 443, probe_name="probe-Tcp-443")

#' @rdname lb_rules
#' @export
lb_rule_rdp <- lb_rule("lb-rdp", 3389, 3389, probe_name="probe-Tcp-3389")

#' @rdname lb_rules
#' @export
lb_rule_jupyter <- lb_rule("lb-rdp", 8000, 8000, probe_name="probe-Tcp-8000")

#' @rdname lb_rules
#' @export
lb_rule_rstudio <- lb_rule("lb-rstudio", 8787, 8787, probe_name="probe-Tcp-8787")

#' @rdname lb_rules
#' @export
lb_rule_mssql <- lb_rule("lb-mssql", 1433, 1433, probe_name="probe-Tcp-1433")

#' @rdname lb_rules
#' @export
lb_rule_mssql_browser <- lb_rule("lb-mssql", 1434, 1434, probe_name="probe-Tcp-1434")

#' @rdname lb_rules
#' @export
lb_probe_ssh <- lb_probe(22)

#' @rdname lb_rules
#' @export
lb_probe_http <- lb_probe(80)

#' @rdname lb_rules
#' @export
lb_probe_https <- lb_probe(443)

#' @rdname lb_rules
#' @export
lb_probe_rdp <- lb_probe(3389)

#' @rdname lb_rules
#' @export
lb_probe_jupyter <- lb_probe(8000)

#' @rdname lb_rules
#' @export
lb_probe_rstudio <- lb_probe(8787)

#' @rdname lb_rules
#' @export
lb_probe_mssql <- lb_probe(1433)

#' @rdname lb_rules
#' @export
lb_probe_mssql_browser <- lb_probe(1434)

