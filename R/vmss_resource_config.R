lb_config <- function(type="basic", rules=list(), probes=list())
{
    rule_probe_names <- sapply(rules, function(x) x$properties$probe$id)
    probe_names <- sapply(probes, `[[`, "name")

    # basic checking
    for(r in rule_probe_names)
    {
        found <- FALSE
        for(p in probe_names)
            found <- grepl(p, r, fixed=TRUE)
        if(!found)
            stop("Rule with no matching probe:", r, call.=FALSE)
    }

    props <- list(
        loadBalancingRules=lapply(rules, unclass),
        probes=lapply(probes, unclass)
    )
    structure(list(properties=props, sku=list(name=type)), class="lb_config")
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


autoscaler_config <- function(profiles=list(autoscaler_profile()))
{
    props <- list(profiles=lapply(profiles, unclass))
    structure(list(properties=props), class="as_config")
}


autoscaler_profile <- function(name="Profile", minsize=1, maxsize=NA, default=NA, scale_out=0.75, scale_in=0.25,
                               interval="PT1M", window="PT5M")
{
    if(is.na(maxsize))
        maxsize <- "[variables('asMaxCapacity')]"
    if(is.na(default))
        default <- "[parameters('instanceCount')]"
    capacity <- list(minimum=minsize, maximum=maxsize, default=default)

    trigger <- list(
        metricName="Percentage CPU",
        metricNamespace="",
        metricResourceUri="[variables('vmId')]",
        timeGrain=interval,
        timeWindow=window,
        statistic="Average",
        timeAggregation="Average"
    )
    action <- list(
        type="ChangeCount",
        value="[variables('asScaleValue')]",
        cooldown=interval
    )

    rule_out <- list(metricTrigger=trigger, scaleAction=action)
    rule_out$metricTrigger$operator <- "GreaterThan"
    rule_out$metricTrigger$threshold <- round(scale_out * 100)
    rule_out$scaleAction$direction <- "Increase"

    rule_in <- list(metricTrigger=trigger, scaleAction=action)
    rule_in$metricTrigger$operator <- "LessThan"
    rule_in$metricTrigger$threshold <- round(scale_in * 100)
    rule_in$scaleAction$direction <- "Decrease"

    prof <- list(
        name=name,
        capacity=capacity,
        rules=list(rule_out, rule_in)
    )
    structure(prof, class="as_profile_config")
}
