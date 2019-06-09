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


build_resource_fields.lb_config <- function(object, ...)
{
    props <- c(
        list(
            loadBalancingRules=lapply(object$rules, unclass),
            probes=lapply(object$probes, unclass)
        ),
        object$other
    )
    sku <- list(name=object$type)
    utils::modifyList(lb_default, list(properties=props, sku=sku))
}


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


lb_rule_ssh <- lb_rule("lb-ssh", 22, 22, probe_name="probe-Tcp-22")
lb_rule_http <- lb_rule("lb-http", 80, 80, probe_name="probe-Tcp-80")
lb_rule_https <- lb_rule("lb-https", 443, 443, probe_name="probe-Tcp-443")
lb_rule_rdp <- lb_rule("lb-rdp", 3389, 3389, probe_name="probe-Tcp-3389")
lb_rule_jupyter <- lb_rule("lb-rdp", 8000, 8000, probe_name="probe-Tcp-8000")
lb_rule_rstudio <- lb_rule("lb-rstudio", 8787, 8787, probe_name="probe-Tcp-8787")

lb_probe_ssh <- lb_probe(22)
lb_probe_http <- lb_probe(80)
lb_probe_https <- lb_probe(443)
lb_probe_rdp <- lb_probe(3389)
lb_probe_jupyter <- lb_probe(8000)
lb_probe_rstudio <- lb_probe(8787)


